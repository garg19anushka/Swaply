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

  // ── Shared select columns (keeps fetchActive & fetchAll in sync) ──────────
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
    wanted_skill
  ''';

  // ── Fetch active swaps for the current user ───────────────────────────────
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
          .or('user_id.eq.$userId,partner_id.eq.$userId')
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

  // ── Fetch ALL swaps (active + completed + pending etc.) ───────────────────
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
          .or('user_id.eq.$userId,partner_id.eq.$userId')
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

  // ── Confirm a pending swap ────────────────────────────────────────────────
  /// Sets status → 'active', stamps confirmed_at, and sends a notification
  /// to the requester so they know their swap was accepted.
  Future<void> confirmSwap(String swapId) async {
    // Optimistic UI — update local state immediately so the badge disappears
    _allSwaps = _allSwaps.map((s) {
      if (s.id != swapId) return s;
      return SwapModel(
        id: s.id,
        swapTitle: s.swapTitle,
        progress: s.progress,
        progressLabel: s.progressLabel,
        totalSessions: s.totalSessions,
        doneSessions: s.doneSessions,
        nextSessionLabel: s.nextSessionLabel,
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
          })
          .eq('id', swapId);

      // 2. Notify the requester
      final swap = _allSwaps.firstWhere((s) => s.id == swapId);
      if (swap.requesterId != null) {
        await _client.from('notifications').insert({
          'user_id': swap.requesterId,
          'type': 'swap_accepted',
          'title': 'Swap accepted! 🤝',
          'body':
              '${swap.partnerName ?? 'Your partner'} confirmed the swap. Head to chat to coordinate.',
          'data': {'swap_id': swapId, 'route': '/chat'},
          'is_read': false,
        });
      }

      // 3. Re-fetch to sync with server truth
      await fetchAllSwaps();
    } catch (e) {
      debugPrint('SwapService.confirmSwap error: $e');
      _error = e.toString();
      // Roll back optimistic update on failure
      await fetchAllSwaps();
    }
  }

  // ── Mark a session as done ────────────────────────────────────────────────
  Future<void> completeSession(String swapId) async {
    try {
      final swap = _allSwaps.firstWhere(
        (s) => s.id == swapId,
        orElse: () => _activeSwaps.firstWhere((s) => s.id == swapId),
      );
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
