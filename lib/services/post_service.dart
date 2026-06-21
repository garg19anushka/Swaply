// lib/services/post_service.dart

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/post_model.dart';

class PostService extends ChangeNotifier {
  final _supabase = Supabase.instance.client;

  List<PostModel> _posts = [];
  List<PostModel> _openRequests = [];
  List<PostModel> _bookmarkedPosts = [];
  Set<String> _bookmarkedIds = {};
  bool _isLoading = false;

  List<PostModel> get posts => _posts;
  List<PostModel> get openRequests => _openRequests;
  List<PostModel> get bookmarkedPosts => _bookmarkedPosts;
  bool get isLoading => _isLoading;

  String? get _uid => _supabase.auth.currentUser?.id;

  static const _profileSelect = '''
    profiles (
      id, username, full_name, avatar_url, campus,
      average_rating, total_swaps, rating_count
    )
  ''';

  // ── fetch posts ────────────────────────────────────────────────────────────
  Future<void> fetchPosts({
    String? searchQuery,
    String? exchangeType, // 'barter' | 'custom' | 'open_request' | null=all
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadBookmarkedIds();

      // Build filter query — all .eq() calls must come before .order()
      var filterQuery = _supabase
          .from('posts')
          .select('*, $_profileSelect')
          .eq('is_open_request', false);

      if (exchangeType != null && exchangeType != 'open_request') {
        filterQuery = filterQuery.eq('exchange_type', exchangeType);
      }

      final rows = await filterQuery.order('created_at', ascending: false);

      List<PostModel> results = (rows as List)
          .map(
            (r) => PostModel.fromMap(
              r as Map<String, dynamic>,
              isBookmarked: _bookmarkedIds.contains(r['id']),
            ),
          )
          .toList();

      // Search filter (client-side)
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        results = results.where((p) {
          return p.title.toLowerCase().contains(q) ||
              p.skillOffered.toLowerCase().contains(q) ||
              (p.skillWanted?.toLowerCase().contains(q) ?? false) ||
              p.tags.any((t) => t.toLowerCase().contains(q)) ||
              (p.profile?.displayName.toLowerCase().contains(q) ?? false);
        }).toList();
      }

      _posts = results;
    } catch (e) {
      debugPrint('PostService.fetchPosts error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── fetch open requests ────────────────────────────────────────────────────
  // By default only shows ACTIVE (unresolved) requests — once a request is
  // marked resolved it drops out of this list so the feed doesn't fill up
  // with already-helped requests. Pass includeResolved: true to see everything
  // (e.g. for a "my past requests" view).
  Future<void> fetchOpenRequests({bool includeResolved = false}) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadBookmarkedIds();

      var filterQuery = _supabase
          .from('posts')
          .select('*, $_profileSelect')
          .eq('is_open_request', true);

      if (!includeResolved) {
        filterQuery = filterQuery.eq('is_resolved', false);
      }

      final rows = await filterQuery.order('created_at', ascending: false);

      // Expired requests (auto-set at creation, see createPost) drop out
      // of the active list the same way resolved ones do — old asks that
      // were never helped shouldn't sit in the feed indefinitely. Posts
      // created before this feature existed have expiresAt == null, and
      // isExpired correctly returns false for those, so they're unaffected.
      _openRequests = (rows as List)
          .map(
            (r) => PostModel.fromMap(
              r as Map<String, dynamic>,
              isBookmarked: _bookmarkedIds.contains(r['id']),
            ),
          )
          .where((p) => includeResolved || !p.isExpired)
          .toList();
    } catch (e) {
      debugPrint('PostService.fetchOpenRequests error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── mark an open request as resolved ────────────────────────────────────
  // Only the post's own author should call this (enforce with RLS too).
  // Updates Supabase, then removes the post from the local _openRequests
  // list so the UI reflects it immediately without a full refetch.
  //
  // Also awards credit to whoever helped: the FIRST person who started a
  // chat from this post (the earliest row in chat_swap_banners for this
  // post_id) gets their profiles.total_swaps incremented by 1 — the same
  // number the leaderboard score formula already reads, so helping with
  // an open request now counts toward leaderboard rank exactly like
  // completing a regular swap does.
  Future<bool> markPostResolved(String postId) async {
    try {
      await _supabase
          .from('posts')
          .update({'is_resolved': true})
          .eq('id', postId);

      await _awardHelperCredit(postId);

      _openRequests = _openRequests.where((p) => p.id != postId).toList();
      _posts = _posts
          .map((p) => p.id == postId ? p.copyWith(isResolved: true) : p)
          .toList();
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('PostService.markPostResolved error: $e');
      return false;
    }
  }

  // Finds the earliest chat_swap_banners row for this post (i.e. whoever
  // started a chat from it first) and bumps that user's total_swaps by 1.
  // Failure here is logged but never blocks the resolve action itself —
  // the request still gets marked resolved even if credit can't be
  // awarded for some reason (e.g. nobody ever started a chat on it).
  Future<void> _awardHelperCredit(String postId) async {
    try {
      final earliest = await _supabase
          .from('chat_swap_banners')
          .select('created_by')
          .eq('post_id', postId)
          .order('created_at', ascending: true)
          .limit(1)
          .maybeSingle();

      final helperId = earliest?['created_by'] as String?;
      if (helperId == null) return;

      // Don't award credit if the asker is somehow resolving their own
      // post as if they'd helped themselves (shouldn't normally happen,
      // since the asker wouldn't start a chat from their own post, but
      // guards against bad data).
      final post = await _supabase
          .from('posts')
          .select('user_id')
          .eq('id', postId)
          .single();
      if (helperId == post['user_id']) return;

      final profile = await _supabase
          .from('profiles')
          .select('total_swaps')
          .eq('id', helperId)
          .single();
      final current = (profile['total_swaps'] ?? 0) as int;

      await _supabase
          .from('profiles')
          .update({'total_swaps': current + 1})
          .eq('id', helperId);
    } catch (e) {
      debugPrint('PostService._awardHelperCredit error: $e');
    }
  }

  // ── reopen a previously resolved request ────────────────────────────────
  Future<bool> reopenPost(String postId) async {
    try {
      await _supabase
          .from('posts')
          .update({'is_resolved': false})
          .eq('id', postId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('PostService.reopenPost error: $e');
      return false;
    }
  }

  // ── fetch user posts ───────────────────────────────────────────────────────
  Future<List<PostModel>> fetchUserPosts(String userId) async {
    try {
      await _loadBookmarkedIds();
      final rows = await _supabase
          .from('posts')
          .select('*, $_profileSelect')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (rows as List)
          .map(
            (r) => PostModel.fromMap(
              r as Map<String, dynamic>,
              isBookmarked: _bookmarkedIds.contains(r['id']),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('PostService.fetchUserPosts error: $e');
      return [];
    }
  }

  // ── fetch bookmarked posts ─────────────────────────────────────────────────
  Future<void> fetchBookmarkedPosts() async {
    if (_uid == null) return;
    _isLoading = true;
    notifyListeners();

    try {
      final rows = await _supabase
          .from('bookmarks')
          .select('post_id, posts (*, $_profileSelect)')
          .eq('user_id', _uid!);

      _bookmarkedPosts = (rows as List)
          .where((r) => r['posts'] != null)
          .map(
            (r) => PostModel.fromMap(
              r['posts'] as Map<String, dynamic>,
              isBookmarked: true,
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('PostService.fetchBookmarkedPosts error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── create post ────────────────────────────────────────────────────────────
  Future<PostModel?> createPost({
    required String title,
    required String description,
    required String skillOffered,
    String? skillWanted,
    String exchangeType = 'barter',
    String? customOffer,
    required List<String> tags,
    bool isOpenRequest = false,
  }) async {
    if (_uid == null) return null;

    try {
      // Open requests get an automatic expiry so stale asks naturally
      // drop off rather than sitting in the list forever — "Urgent"
      // requests expire sooner (3 days) than the general default (14
      // days), reusing the same Urgency tags already captured on the
      // create-post form rather than adding a separate expiry picker.
      DateTime? expiresAt;
      if (isOpenRequest) {
        final isUrgent = tags.contains('Urgent');
        expiresAt = DateTime.now().add(Duration(days: isUrgent ? 3 : 14));
      }

      final row = await _supabase
          .from('posts')
          .insert({
            'user_id': _uid,
            'title': title,
            'description': description,
            'skill_offered': skillOffered,
            'skill_wanted': skillWanted,
            'exchange_type': exchangeType,
            'custom_offer': customOffer,
            'tags': tags,
            'is_open_request': isOpenRequest,
            'expires_at': expiresAt?.toIso8601String(),
            'bookmarks_count': 0,
            'swap_count': 0,
          })
          .select('*, $_profileSelect')
          .single();

      final post = PostModel.fromMap(row as Map<String, dynamic>);
      if (isOpenRequest) {
        _openRequests.insert(0, post);
      } else {
        _posts.insert(0, post);
      }
      notifyListeners();
      return post;
    } catch (e) {
      debugPrint('PostService.createPost error: $e');
      return null;
    }
  }

  // ── update post ────────────────────────────────────────────────────────────
  Future<PostModel?> updatePost({
    required String postId,
    required String title,
    required String description,
    required String skillOffered,
    String? skillWanted,
    String exchangeType = 'barter',
    String? customOffer,
    required List<String> tags,
    bool isOpenRequest = false,
  }) async {
    try {
      final row = await _supabase
          .from('posts')
          .update({
            'title': title,
            'description': description,
            'skill_offered': skillOffered,
            'skill_wanted': skillWanted,
            'exchange_type': exchangeType,
            'custom_offer': customOffer,
            'tags': tags,
            'is_open_request': isOpenRequest,
          })
          .eq('id', postId)
          .select('*, $_profileSelect')
          .single();

      final updated = PostModel.fromMap(
        row as Map<String, dynamic>,
        isBookmarked: _bookmarkedIds.contains(postId),
      );
      _updateInLists(updated);
      notifyListeners();
      return updated;
    } catch (e) {
      debugPrint('PostService.updatePost error: $e');
      return null;
    }
  }

  // ── delete post ────────────────────────────────────────────────────────────
  Future<void> deletePost(String postId) async {
    try {
      await _supabase.from('posts').delete().eq('id', postId);
      _posts.removeWhere((p) => p.id == postId);
      _openRequests.removeWhere((p) => p.id == postId);
      _bookmarkedPosts.removeWhere((p) => p.id == postId);
      notifyListeners();
    } catch (e) {
      debugPrint('PostService.deletePost error: $e');
    }
  }

  // ── renew a post (extend expires_at by 30 days from now) ─────────────────
  Future<bool> renewPost(String postId) async {
    if (_uid == null) return false;
    try {
      final newExpiry = DateTime.now().add(const Duration(days: 30));
      await _supabase
          .from('posts')
          .update({'expires_at': newExpiry.toIso8601String()})
          .eq('id', postId)
          .eq('user_id', _uid!); // safety: only the owner can renew

      // Update the local list so the UI reflects immediately
      for (final list in [_posts, _openRequests]) {
        final idx = list.indexWhere((p) => p.id == postId);
        if (idx != -1) {
          list[idx] = list[idx].copyWith(expiresAt: newExpiry);
        }
      }
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('PostService.renewPost error: $e');
      return false;
    }
  }

  // ── toggle bookmark ────────────────────────────────────────────────────────
  Future<void> toggleBookmark(String postId) async {
    if (_uid == null) return;
    final wasBookmarked = _bookmarkedIds.contains(postId);

    // Optimistic update
    if (wasBookmarked) {
      _bookmarkedIds.remove(postId);
    } else {
      _bookmarkedIds.add(postId);
    }
    _refreshBookmarkState(postId, !wasBookmarked);
    notifyListeners();

    try {
      if (wasBookmarked) {
        await _supabase.from('bookmarks').delete().match({
          'user_id': _uid!,
          'post_id': postId,
        });
      } else {
        await _supabase.from('bookmarks').insert({
          'user_id': _uid!,
          'post_id': postId,
        });

        // ── Notify the post owner about the new match ──────────────────
        // Find the post to get the owner's id and skill info
        PostModel? post;
        for (final p in [..._posts, ..._openRequests, ..._bookmarkedPosts]) {
          if (p.id == postId) {
            post = p;
            break;
          }
        }

        // Only notify if the bookmarker is NOT the post owner
        if (post != null && post.userId != _uid) {
          // Fetch the bookmarker's profile to show their name + skills
          final myProfile = await _supabase
              .from('profiles')
              .select('full_name, username, skills_offered')
              .eq('id', _uid!)
              .maybeSingle();

          final myName =
              myProfile?['full_name'] as String? ??
              myProfile?['username'] as String? ??
              'Someone';

          final mySkill =
              (myProfile?['skills_offered'] as List?)?.isNotEmpty == true
              ? (myProfile!['skills_offered'] as List).first.toString()
              : null;

          await _supabase.from('notifications').insert({
            'user_id': post.userId, // notify the POST OWNER
            'type': 'new_match',
            'title': '$myName bookmarked your post! 🔖',
            'body': mySkill != null
                ? '$myName offers $mySkill — looks like a great match for your ${post.skillOffered} post.'
                : '$myName bookmarked your "${post.skillOffered}" post.',
            'data': {
              'post_id': postId,
              'bookmarker_id': _uid,
              'bookmarker_name': myName,
              // skill_1 and skill_2 are used by the notification card
              // to render the teal skill exchange pill
              'skill_1': mySkill ?? 'Their skill',
              'skill_2': post.skillOffered,
              'route': '/explore',
            },
            'is_read': false,
          });
        }
      }
    } catch (e) {
      // Revert on error
      if (wasBookmarked) {
        _bookmarkedIds.add(postId);
      } else {
        _bookmarkedIds.remove(postId);
      }
      _refreshBookmarkState(postId, wasBookmarked);
      notifyListeners();
      debugPrint('PostService.toggleBookmark error: $e');
    }
  }

  // ── private helpers ────────────────────────────────────────────────────────
  Future<void> _loadBookmarkedIds() async {
    if (_uid == null) return;
    try {
      final rows = await _supabase
          .from('bookmarks')
          .select('post_id')
          .eq('user_id', _uid!);
      _bookmarkedIds = {for (final r in rows) r['post_id'] as String};
    } catch (e) {
      debugPrint('PostService._loadBookmarkedIds error: $e');
    }
  }

  void _refreshBookmarkState(String postId, bool isBookmarked) {
    _posts = _posts
        .map((p) => p.id == postId ? p.copyWith(isBookmarked: isBookmarked) : p)
        .toList();
    _openRequests = _openRequests
        .map((p) => p.id == postId ? p.copyWith(isBookmarked: isBookmarked) : p)
        .toList();
    _bookmarkedPosts = _bookmarkedPosts
        .map((p) => p.id == postId ? p.copyWith(isBookmarked: isBookmarked) : p)
        .toList();
  }

  void _updateInLists(PostModel updated) {
    _posts = _posts.map((p) => p.id == updated.id ? updated : p).toList();
    _openRequests = _openRequests
        .map((p) => p.id == updated.id ? updated : p)
        .toList();
  }
}
