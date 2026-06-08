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
  Future<void> fetchOpenRequests() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _loadBookmarkedIds();

      final rows = await _supabase
          .from('posts')
          .select('*, $_profileSelect')
          .eq('is_open_request', true)
          .order('created_at', ascending: false);

      _openRequests = (rows as List)
          .map(
            (r) => PostModel.fromMap(
              r as Map<String, dynamic>,
              isBookmarked: _bookmarkedIds.contains(r['id']),
            ),
          )
          .toList();
    } catch (e) {
      debugPrint('PostService.fetchOpenRequests error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
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
