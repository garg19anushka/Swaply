import 'package:flutter/material.dart';
import '../main.dart';
import '../models/post_model.dart';

class PostService extends ChangeNotifier {
  List<PostModel> _posts = [];
  List<PostModel> _bookmarkedPosts = [];
  List<PostModel> _openRequests = [];
  bool _isLoading = false;

  List<PostModel> get posts => _posts;
  List<PostModel> get bookmarkedPosts => _bookmarkedPosts;
  List<PostModel> get openRequests => _openRequests;
  bool get isLoading => _isLoading;

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  Future<void> fetchPosts({
    String? searchQuery,
    String? exchangeType,
    bool openRequestsOnly = false,
  }) async {
    _setLoading(true);
    try {
      // Build filter query using PostgrestFilterBuilder (before .order())
      var query = supabase
          .from('posts')
          .select('*, profiles(*)')
          .eq('is_active', true);

      if (openRequestsOnly) {
        query = query.eq('is_open_request', true);
      }
      if (exchangeType != null && exchangeType.isNotEmpty) {
        query = query.eq('exchange_type', exchangeType);
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        query = query.ilike('title', '%$searchQuery%');
      }

      final data = await query.order('created_at', ascending: false);

      final userId = supabase.auth.currentUser?.id;

      Set<String> bookmarkedIds = {};
      if (userId != null) {
        final bookmarks = await supabase
            .from('bookmarks')
            .select('post_id')
            .eq('user_id', userId);
        bookmarkedIds = Set<String>.from(
          (bookmarks as List).map((b) => b['post_id']),
        );
      }

      _posts = (data as List).map((json) {
        final post = PostModel.fromJson(json);
        post.isBookmarked = bookmarkedIds.contains(post.id);
        return post;
      }).toList();

      if (openRequestsOnly) {
        _openRequests = _posts;
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching posts: $e');
    } finally {
      _setLoading(false);
    }
  }

  Future<void> fetchOpenRequests() async {
    try {
      final data = await supabase
          .from('posts')
          .select('*, profiles(*)')
          .eq('is_active', true)
          .eq('is_open_request', true)
          .order('created_at', ascending: false);

      _openRequests = (data as List)
          .map((json) => PostModel.fromJson(json))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching open requests: $e');
    }
  }

  Future<PostModel?> createPost({
    required String title,
    required String description,
    required String skillOffered,
    String? skillWanted,
    required String exchangeType,
    String? customOffer,
    List<String> tags = const [],
    bool isOpenRequest = false,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final data = await supabase
          .from('posts')
          .insert({
            'user_id': userId,
            'title': title,
            'description': description,
            'skill_offered': skillOffered,
            'skill_wanted': skillWanted,
            'exchange_type': exchangeType,
            'custom_offer': customOffer,
            'tags': tags,
            'is_open_request': isOpenRequest,
          })
          .select('*, profiles(*)')
          .single();

      final newPost = PostModel.fromJson(data);
      _posts.insert(0, newPost);
      notifyListeners();
      return newPost;
    } catch (e) {
      debugPrint('Error creating post: $e');
      return null;
    }
  }

  Future<bool> deletePost(String postId) async {
    try {
      await supabase.from('posts').delete().eq('id', postId);
      _posts.removeWhere((p) => p.id == postId);
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<PostModel?> updatePost({
    required String postId,
    required String title,
    required String description,
    required String skillOffered,
    String? skillWanted,
    required String exchangeType,
    String? customOffer,
    List<String> tags = const [],
    bool isOpenRequest = false,
  }) async {
    try {
      final data = await supabase
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
          .select('*, profiles(*)')
          .single();

      final updated = PostModel.fromJson(data);
      final idx = _posts.indexWhere((p) => p.id == postId);
      if (idx != -1) {
        _posts[idx] = updated;
      }
      notifyListeners();
      return updated;
    } catch (e) {
      debugPrint('Error updating post: $e');
      return null;
    }
  }

  Future<void> toggleBookmark(String postId) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    final postIndex = _posts.indexWhere((p) => p.id == postId);
    if (postIndex == -1) return;

    final isCurrentlyBookmarked = _posts[postIndex].isBookmarked;

    _posts[postIndex].isBookmarked = !isCurrentlyBookmarked;
    notifyListeners();

    try {
      if (isCurrentlyBookmarked) {
        await supabase
            .from('bookmarks')
            .delete()
            .eq('user_id', userId)
            .eq('post_id', postId);
      } else {
        await supabase.from('bookmarks').insert({
          'user_id': userId,
          'post_id': postId,
        });
      }
    } catch (e) {
      _posts[postIndex].isBookmarked = isCurrentlyBookmarked;
      notifyListeners();
    }
  }

  Future<void> fetchBookmarkedPosts() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    try {
      final data = await supabase
          .from('bookmarks')
          .select('post_id, posts(*, profiles(*))')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      _bookmarkedPosts = (data as List)
          .where((b) => b['posts'] != null)
          .map((b) => PostModel.fromJson(b['posts']))
          .toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching bookmarks: $e');
    }
  }

  Future<List<PostModel>> fetchUserPosts(String userId) async {
    try {
      final data = await supabase
          .from('posts')
          .select('*, profiles(*)')
          .eq('user_id', userId)
          .order('created_at', ascending: false);

      return (data as List).map((json) => PostModel.fromJson(json)).toList();
    } catch (e) {
      return [];
    }
  }
}