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
    String sortBy = 'newest', // newest | oldest | rating_high | rating_low
    String skillType =
        'all', // all | technical | creative | soft | language | academic | fitness | business
    String availability = 'all', // all | now | this_week | weekends | evenings
    String sessionFormat = 'all', // all | online | in_person | hybrid | async
  }) async {
    _setLoading(true);
    try {
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

      // DB-level sort: only createdAt is reliable from DB
      final ascending = sortBy == 'oldest';
      final data = await query.order('created_at', ascending: ascending);

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

      List<PostModel> posts = (data as List).map((json) {
        final post = PostModel.fromJson(json);
        post.isBookmarked = bookmarkedIds.contains(post.id);
        return post;
      }).toList();

      // ── Client-side: Skill Type filter ────────────────────────────
      if (skillType != 'all') {
        final _technical = {
          'coding',
          'programming',
          'engineering',
          'data',
          'ai',
          'ml',
          'web',
          'app',
          'flutter',
          'react',
          'java',
          'python',
          'math',
        };
        final _creative = {
          'design',
          'art',
          'photo',
          'video',
          'music',
          'drawing',
          'illustration',
          'canva',
          'figma',
          'editing',
        };
        final _soft = {
          'communication',
          'leadership',
          'management',
          'teamwork',
          'speaking',
          'presentation',
          'negotiation',
        };
        final _language = {
          'language',
          'english',
          'hindi',
          'french',
          'spanish',
          'german',
          'japanese',
          'chinese',
          'translation',
        };
        final _academic = {
          'writing',
          'research',
          'essay',
          'academic',
          'study',
          'tutor',
          'homework',
          'assignment',
        };
        final _fitness = {
          'fitness',
          'yoga',
          'gym',
          'workout',
          'nutrition',
          'health',
          'sport',
          'dance',
        };
        final _business = {
          'business',
          'marketing',
          'finance',
          'accounting',
          'sales',
          'entrepreneurship',
          'startup',
          'excel',
        };

        Set<String> keywords;
        switch (skillType) {
          case 'technical':
            keywords = _technical;
            break;
          case 'creative':
            keywords = _creative;
            break;
          case 'soft':
            keywords = _soft;
            break;
          case 'language':
            keywords = _language;
            break;
          case 'academic':
            keywords = _academic;
            break;
          case 'fitness':
            keywords = _fitness;
            break;
          case 'business':
            keywords = _business;
            break;
          default:
            keywords = {};
        }

        if (keywords.isNotEmpty) {
          posts = posts.where((p) {
            final haystack = '${p.skillOffered} ${p.title} ${p.tags.join(' ')}'
                .toLowerCase();
            return keywords.any((kw) => haystack.contains(kw));
          }).toList();
        }
      }

      // ── Client-side: Availability filter ──────────────────────────
      if (availability != 'all') {
        final now = DateTime.now();
        posts = posts.where((p) {
          final hoursSince = now.difference(p.createdAt).inHours;
          switch (availability) {
            case 'now':
              return hoursSince < 24;
            case 'this_week':
              return hoursSince < 168;
            case 'weekends':
              return now.weekday == 6 || now.weekday == 7;
            case 'evenings':
              return now.hour >= 17 || now.hour < 23;
            default:
              return true;
          }
        }).toList();
      }

      // ── Client-side: Session Format filter ────────────────────────
      if (sessionFormat != 'all') {
        posts = posts.where((p) {
          final haystack = '${p.title} ${p.description} ${p.tags.join(' ')}'
              .toLowerCase();
          switch (sessionFormat) {
            case 'online':
              return haystack.contains('online') ||
                  haystack.contains('virtual') ||
                  haystack.contains('remote');
            case 'in_person':
              return haystack.contains('in person') ||
                  haystack.contains('offline') ||
                  haystack.contains('campus');
            case 'hybrid':
              return haystack.contains('hybrid') || haystack.contains('both');
            case 'async':
              return haystack.contains('async') ||
                  haystack.contains('self-paced') ||
                  haystack.contains('flexible');
            default:
              return true;
          }
        }).toList();
      }

      // ── Client-side: Rating sort ───────────────────────────────────
      if (sortBy == 'rating_high') {
        posts.sort(
          (a, b) => (b.profile?.averageRating ?? 0).compareTo(
            a.profile?.averageRating ?? 0,
          ),
        );
      } else if (sortBy == 'rating_low') {
        posts.sort(
          (a, b) => (a.profile?.averageRating ?? 0).compareTo(
            b.profile?.averageRating ?? 0,
          ),
        );
      }

      _posts = posts;

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
