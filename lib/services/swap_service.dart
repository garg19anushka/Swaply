// lib/services/swap_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/swap_model.dart';

class SwapService extends ChangeNotifier {
  final _client = Supabase.instance.client;

  List<SwapModel> _activeSwaps = [];
  List<SwapModel> _allSwaps = [];
  bool _isLoading = false;
  String? _error;

  List<SwapModel> get activeSwaps => _activeSwaps;
  List<SwapModel> get allSwaps => _allSwaps;
  bool get isLoading => _isLoading;
  String? get error => _error;

  static const _swapColumns = '''
    id,
    swap_title,
    total_sessions,
    done_sessions,
    progress_label,
    next_session_label,
    status,
    partner_name,
    partner_username,
    partner_avatar_url,
    expires_at,
    confirmed_at,
    requester_id,
    responder_id,
    offered_skill,
    wanted_skill,
    requester_name,
    requester_username,
    requester_avatar_url,
    responder_name,
    responder_username,
    responder_avatar_url
  ''';

  // ── Fetch active swaps ────────────────────────────────────────────────────
  Future<void> fetchActiveSwaps() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client
          .from('swaps')
          .select(_swapColumns)
          .eq('status', 'active')
          .or('requester_id.eq.$userId,responder_id.eq.$userId')
          .order('created_at', ascending: false);

      _activeSwaps = (response as List)
          .map((m) => SwapModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('SwapService.fetchActiveSwaps error: $e');
      _error = e.toString();
      _activeSwaps = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Fetch all swaps ───────────────────────────────────────────────────────
  Future<void> fetchAllSwaps() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client
          .from('swaps')
          .select(_swapColumns)
          .or('requester_id.eq.$userId,responder_id.eq.$userId')
          .order('created_at', ascending: false);

      _allSwaps = (response as List)
          .map((m) => SwapModel.fromMap(m as Map<String, dynamic>))
          .toList();
      _activeSwaps = _allSwaps.where((s) => s.status == 'active').toList();
    } catch (e) {
      debugPrint('SwapService.fetchAllSwaps error: $e');
      _error = e.toString();
      _allSwaps = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── REQUEST a swap (Step 1 of 2) ─────────────────────────────────────────
  /// Called from PostDetailScreen. Creates a pending swap row and notifies
  /// the responder so they see it in My Swaps and their notification feed.
  /// Returns the new swap's id on success, null on failure.
  Future<String?> requestSwap({
    required String responderId,
    required String? offeredSkill, // nullable — resolved below if null
    required String wantedSkill,
    required String postId,
    int totalSessions = 4,
  }) async {
    final me = _client.auth.currentUser;
    if (me == null) return null;

    try {
      // 1. Fetch my profile snapshot
      final myProfile = await _client
          .from('profiles')
          .select('full_name, username, avatar_url, skills_offered')
          .eq('id', me.id)
          .maybeSingle();

      // Resolve offeredSkill — if the post was an open request (skillWanted
      // was null on the post), use the first skill from the requester's own
      // profile, then fall back to a generic label.
      final resolvedOfferedSkill =
          (offeredSkill != null && offeredSkill.isNotEmpty)
          ? offeredSkill
          : ((myProfile?['skills_offered'] as List?)?.isNotEmpty == true
                ? (myProfile!['skills_offered'] as List).first.toString()
                : 'My skill');

      // 2. Fetch responder profile snapshot
      final theirProfile = await _client
          .from('profiles')
          .select('full_name, username, avatar_url')
          .eq('id', responderId)
          .maybeSingle();

      final myName =
          myProfile?['full_name'] as String? ??
          myProfile?['username'] as String? ??
          'Someone';
      final myUsername = myProfile?['username'] as String? ?? '';
      final myAvatar = myProfile?['avatar_url'] as String?;

      final theirName =
          theirProfile?['full_name'] as String? ??
          theirProfile?['username'] as String? ??
          'Someone';
      final theirUsername = theirProfile?['username'] as String? ?? '';
      final theirAvatar = theirProfile?['avatar_url'] as String?;

      // 3. Check for an existing pending/active swap between the same pair
      //    (avoid duplicate requests for the same post)
      final existing = await _client
          .from('swaps')
          .select('id, status')
          .or('requester_id.eq.${me.id},responder_id.eq.${me.id}')
          .or('requester_id.eq.$responderId,responder_id.eq.$responderId')
          .inFilter('status', ['pending', 'active'])
          .maybeSingle();

      if (existing != null) {
        _error = 'You already have an active or pending swap with this person.';
        notifyListeners();
        return null;
      }

      // 4. Insert the swap row
      final row = await _client
          .from('swaps')
          .insert({
            'requester_id': me.id,
            'responder_id': responderId,
            'offered_skill': resolvedOfferedSkill,
            'wanted_skill': wantedSkill,
            'swap_title': '$resolvedOfferedSkill ↔ $wantedSkill',
            'status': 'pending',
            'total_sessions': totalSessions,
            'done_sessions': 0,
            'progress_label': 'Session 0 of $totalSessions complete',
            'next_session_label': 'Waiting for confirmation',
            // Legacy single-side field — shows the responder's name to
            // the requester (who will see this row first)
            'partner_name': theirName,
            'partner_username': theirUsername,
            'partner_avatar_url': theirAvatar,
            // Per-role snapshots so both sides see the correct partner
            'requester_name': myName,
            'requester_username': myUsername,
            'requester_avatar_url': myAvatar,
            'responder_name': theirName,
            'responder_username': theirUsername,
            'responder_avatar_url': theirAvatar,
            'expires_at': DateTime.now()
                .add(const Duration(days: 3))
                .toIso8601String(),
          })
          .select('id')
          .single();

      final swapId = row['id'] as String;

      // 5. Notify the responder
      await _client.from('notifications').insert({
        'user_id': responderId,
        'type': 'swap_request',
        'title': 'New swap request! 🤝',
        'body':
            '$myName wants to swap $resolvedOfferedSkill for $wantedSkill with you.',
        'data': {
          'swap_id': swapId,
          'route': '/my_swaps',
          'requester_id': me.id,
          'requester_name': myName,
        },
        'is_read': false,
      });

      // 6. Refresh local list
      await fetchAllSwaps();
      return swapId;
    } catch (e) {
      debugPrint('SwapService.requestSwap error: $e');
      _error = e.toString();
      notifyListeners();
      return null;
    }
  }

  // ── CONFIRM a swap (Step 2 of 2 — responder accepts) ─────────────────────
  Future<void> confirmSwap(String swapId) async {
    // Optimistic update
    _allSwaps = _allSwaps.map((s) {
      if (s.id != swapId) return s;
      return SwapModel(
        id: s.id,
        swapTitle: s.swapTitle,
        progress: s.progress,
        progressLabel: s.progressLabel,
        totalSessions: s.totalSessions,
        doneSessions: s.doneSessions,
        nextSessionLabel: 'Schedule your first session',
        partnerName: s.partnerName,
        partnerUsername: s.partnerUsername,
        partnerAvatarUrl: s.partnerAvatarUrl,
        status: 'active',
        expiresAt: s.expiresAt,
        confirmedAt: DateTime.now(),
        requesterId: s.requesterId,
        responderId: s.responderId,
        offeredSkill: s.offeredSkill,
        wantedSkill: s.wantedSkill,
        requesterName: s.requesterName,
        requesterUsername: s.requesterUsername,
        requesterAvatarUrl: s.requesterAvatarUrl,
        responderName: s.responderName,
        responderUsername: s.responderUsername,
        responderAvatarUrl: s.responderAvatarUrl,
      );
    }).toList();
    notifyListeners();

    try {
      // 1. Update the swap row
      await _client
          .from('swaps')
          .update({
            'status': 'active',
            'confirmed_at': DateTime.now().toIso8601String(),
            'next_session_label': 'Schedule your first session',
          })
          .eq('id', swapId);

      // 2. Find swap locally to get the requester's id + responder name
      SwapModel? swap;
      for (final s in _allSwaps) {
        if (s.id == swapId) {
          swap = s;
          break;
        }
      }

      // 3. Notify the requester
      if (swap != null && swap.requesterId != null) {
        final responderDisplayName =
            swap.responderName ?? swap.responderUsername ?? 'Your partner';
        await _client.from('notifications').insert({
          'user_id': swap.requesterId,
          'type': 'swap_accepted',
          'title': 'Swap confirmed! 🎉',
          'body':
              '$responderDisplayName accepted your swap request. '
              'Head to My Swaps to coordinate your first session.',
          'data': {'swap_id': swapId, 'route': '/my_swaps'},
          'is_read': false,
        });
      }

      await fetchAllSwaps();
    } catch (e) {
      debugPrint('SwapService.confirmSwap error: $e');
      _error = e.toString();
      await fetchAllSwaps();
    }
  }

  // ── DECLINE a pending swap ────────────────────────────────────────────────
  Future<void> declineSwap(String swapId) async {
    // Optimistic remove from list
    _allSwaps = _allSwaps.where((s) => s.id != swapId).toList();
    notifyListeners();

    try {
      SwapModel? swap;
      // We already removed it optimistically, so fetch from DB to get ids
      final row = await _client
          .from('swaps')
          .select('requester_id, responder_name, responder_username')
          .eq('id', swapId)
          .maybeSingle();

      await _client
          .from('swaps')
          .update({'status': 'cancelled'})
          .eq('id', swapId);

      // Notify the requester their swap was declined
      if (row != null && row['requester_id'] != null) {
        final declinerName =
            row['responder_name'] as String? ??
            row['responder_username'] as String? ??
            'The other person';
        await _client.from('notifications').insert({
          'user_id': row['requester_id'],
          'type': 'swap_declined',
          'title': 'Swap request declined',
          'body': '$declinerName wasn\'t able to accept your swap this time.',
          'data': {'swap_id': swapId},
          'is_read': false,
        });
      }

      await fetchAllSwaps();
    } catch (e) {
      debugPrint('SwapService.declineSwap error: $e');
      _error = e.toString();
      await fetchAllSwaps();
    }
  }

  // ── Mark a session complete ───────────────────────────────────────────────
  Future<void> completeSession(String swapId) async {
    SwapModel? swap;
    for (final s in [..._allSwaps, ..._activeSwaps]) {
      if (s.id == swapId) {
        swap = s;
        break;
      }
    }
    if (swap == null) {
      debugPrint('SwapService.completeSession: swap $swapId not found.');
      return;
    }

    try {
      final newDone = (swap.doneSessions + 1).clamp(0, swap.totalSessions);
      final newStatus = newDone >= swap.totalSessions
          ? 'awaiting_review'
          : 'active';

      await _client
          .from('swaps')
          .update({'done_sessions': newDone, 'status': newStatus})
          .eq('id', swapId);

      await fetchAllSwaps();
    } catch (e) {
      debugPrint('SwapService.completeSession error: $e');
    }
  }
}
