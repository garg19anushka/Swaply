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
          .select('''
            id,
            swap_title,
            total_sessions,
            done_sessions,
            progress_label,
            next_session_label,
            status,
            partner_name,
            partner_username,
            partner_avatar_url
          ''')
          .eq('status', 'active')
          .or('user_id.eq.$userId,partner_id.eq.$userId')
          .order('created_at', ascending: false);

      _activeSwaps = (response as List)
          .map((m) => SwapModel.fromMap(m as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('SwapService.fetchActiveSwaps error: $e');
      _error = e.toString();
      // Provide a graceful fallback so the UI doesn't break
      _activeSwaps = [];
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Fetch ALL swaps (active + completed) ─────────────────────────────────
  Future<void> fetchAllSwaps() async {
    final userId = _client.auth.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final response = await _client
          .from('swaps')
          .select('''
            id,
            swap_title,
            total_sessions,
            done_sessions,
            progress_label,
            next_session_label,
            status,
            partner_name,
            partner_username,
            partner_avatar_url
          ''')
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

  // ── Mark a session as done ────────────────────────────────────────────────
  Future<void> completeSession(String swapId) async {
    try {
      final swap = _allSwaps.firstWhere(
        (s) => s.id == swapId,
        orElse: () => _activeSwaps.firstWhere((s) => s.id == swapId),
      );
      final newDone = (swap.doneSessions + 1).clamp(0, swap.totalSessions);
      final newStatus = newDone >= swap.totalSessions ? 'completed' : 'active';

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
