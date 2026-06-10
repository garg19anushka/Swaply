// lib/services/notification_service.dart
// ─────────────────────────────────────────────────────────────────────────────

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart';
import '../models/chat_model.dart';

class NotificationService extends ChangeNotifier {
  List<NotificationModel> _notifications = [];
  int _unreadCount = 0;
  bool _isLoading = false;
  RealtimeChannel? _notifChannel;

  List<NotificationModel> get notifications => _notifications;
  int get unreadCount => _unreadCount;
  bool get isLoading => _isLoading;

  // ── Fetch all notifications for current user ───────────────────────────────
  Future<void> fetchNotifications() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final data = await supabase
          .from('notifications')
          .select()
          .eq('user_id', userId)
          .order('created_at', ascending: false)
          .limit(50);

      _notifications = (data as List)
          .map((n) => NotificationModel.fromJson(n))
          .toList();
      _unreadCount = _notifications.where((n) => !n.isRead).length;
    } catch (e) {
      debugPrint('Error fetching notifications: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Real-time subscription for new notifications ───────────────────────────
  void subscribeToNotifications() {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    _notifChannel = supabase
        .channel('notifications_$userId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'notifications',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'user_id',
            value: userId,
          ),
          callback: (payload) {
            final notif = NotificationModel.fromJson(payload.newRecord);
            _notifications.insert(0, notif);
            _unreadCount++;
            notifyListeners();
          },
        )
        .subscribe();
  }

  // ── Mark a single notification as read ────────────────────────────────────
  Future<void> markAsRead(String notificationId) async {
    final idx = _notifications.indexWhere((n) => n.id == notificationId);
    if (idx == -1 || _notifications[idx].isRead) return;

    // Optimistic update
    _notifications[idx].isRead = true;
    _unreadCount = _notifications.where((n) => !n.isRead).length;
    notifyListeners();

    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('id', notificationId);
    } catch (e) {
      // Roll back on error
      _notifications[idx].isRead = false;
      _unreadCount = _notifications.where((n) => !n.isRead).length;
      notifyListeners();
      debugPrint('Error marking notification read: $e');
    }
  }

  // ── Mark all notifications as read ────────────────────────────────────────
  Future<void> markAllRead() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    // Optimistic update
    for (final n in _notifications) {
      n.isRead = true;
    }
    _unreadCount = 0;
    notifyListeners();

    try {
      await supabase
          .from('notifications')
          .update({'is_read': true})
          .eq('user_id', userId)
          .eq('is_read', false);
    } catch (e) {
      debugPrint('Error marking all notifications read: $e');
      // Re-fetch to restore correct state
      await fetchNotifications();
    }
  }

  @override
  void dispose() {
    _notifChannel?.unsubscribe();
    super.dispose();
  }
}
