// lib/models/post_model.dart

class ProfileModel {
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? campus;
  final double averageRating;
  final int totalSwaps;
  final int ratingCount;

  ProfileModel({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.campus,
    this.averageRating = 0.0,
    this.totalSwaps = 0,
    this.ratingCount = 0,
  });

  factory ProfileModel.fromMap(Map<String, dynamic> map) {
    return ProfileModel(
      id: map['id'] ?? '',
      username: map['username'] ?? '',
      fullName: map['full_name'],
      avatarUrl: map['avatar_url'],
      campus: map['campus'],
      averageRating: (map['average_rating'] ?? 0.0).toDouble(),
      totalSwaps: map['total_swaps'] ?? 0,
      ratingCount: map['rating_count'] ?? 0,
    );
  }

  String get displayName => fullName ?? username;
}

class PostModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String skillOffered;
  final String? skillWanted;
  final List<String> tags;
  final int bookmarksCount;
  final int swapCount;
  final String exchangeType;
  final String? customOffer;
  final bool isOpenRequest;
  final bool isBookmarked;
  final DateTime createdAt;
  final DateTime? expiresAt; // used by expiry notifications + Edge Function
  final ProfileModel? profile;

  PostModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.skillOffered,
    this.skillWanted,
    required this.tags,
    this.bookmarksCount = 0,
    this.swapCount = 0,
    this.exchangeType = 'barter',
    this.customOffer,
    this.isOpenRequest = false,
    this.isBookmarked = false,
    required this.createdAt,
    this.expiresAt,
    this.profile,
  });

  // Convenience helpers used in the UI
  bool get isExpired =>
      expiresAt != null && expiresAt!.isBefore(DateTime.now());

  int? get hoursUntilExpiry => expiresAt == null
      ? null
      : expiresAt!.difference(DateTime.now()).inHours.clamp(0, 99999);

  factory PostModel.fromMap(
    Map<String, dynamic> map, {
    bool isBookmarked = false,
  }) {
    ProfileModel? profile;
    if (map['profiles'] != null) {
      profile = ProfileModel.fromMap(map['profiles'] as Map<String, dynamic>);
    }
    return PostModel(
      id: map['id'] ?? '',
      userId: map['user_id'] ?? '',
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      skillOffered: map['skill_offered'] ?? '',
      skillWanted: map['skill_wanted'],
      tags: List<String>.from(map['tags'] ?? []),
      bookmarksCount: map['bookmarks_count'] ?? map['save_count'] ?? 0,
      swapCount: map['swap_count'] ?? 0,
      exchangeType: map['exchange_type'] ?? 'barter',
      customOffer: map['custom_offer'],
      isOpenRequest: map['is_open_request'] ?? false,
      isBookmarked: isBookmarked,
      createdAt: DateTime.tryParse(map['created_at'] ?? '') ?? DateTime.now(),
      expiresAt: map['expires_at'] != null
          ? DateTime.tryParse(map['expires_at'].toString())
          : null,
      profile: profile,
    );
  }

  PostModel copyWith({
    bool? isBookmarked,
    int? bookmarksCount,
    DateTime? expiresAt,
    ProfileModel? profile,
  }) {
    return PostModel(
      id: id,
      userId: userId,
      title: title,
      description: description,
      skillOffered: skillOffered,
      skillWanted: skillWanted,
      tags: tags,
      bookmarksCount: bookmarksCount ?? this.bookmarksCount,
      swapCount: swapCount,
      exchangeType: exchangeType,
      customOffer: customOffer,
      isOpenRequest: isOpenRequest,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      createdAt: createdAt,
      expiresAt: expiresAt ?? this.expiresAt,
      profile: profile ?? this.profile,
    );
  }
}
