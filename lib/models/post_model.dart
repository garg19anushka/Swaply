import 'profile_model.dart';

class PostModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String skillOffered;
  final String? skillWanted;
  final String exchangeType; // 'barter' or 'custom'
  final String? customOffer;
  final List<String> tags;
  final bool isOpenRequest;
  final bool isActive;
  final int bookmarksCount;
  final DateTime createdAt;
  final ProfileModel? profile;
  bool isBookmarked;

  PostModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.skillOffered,
    this.skillWanted,
    required this.exchangeType,
    this.customOffer,
    this.tags = const [],
    this.isOpenRequest = false,
    this.isActive = true,
    this.bookmarksCount = 0,
    required this.createdAt,
    this.profile,
    this.isBookmarked = false,
  });

  factory PostModel.fromJson(Map<String, dynamic> json) {
    return PostModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      skillOffered: json['skill_offered'] ?? '',
      skillWanted: json['skill_wanted'],
      exchangeType: json['exchange_type'] ?? 'barter',
      customOffer: json['custom_offer'],
      tags: List<String>.from(json['tags'] ?? []),
      isOpenRequest: json['is_open_request'] ?? false,
      isActive: json['is_active'] ?? true,
      bookmarksCount: json['bookmarks_count'] ?? 0,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      profile: json['profiles'] != null
          ? ProfileModel.fromJson(json['profiles'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'user_id': userId,
      'title': title,
      'description': description,
      'skill_offered': skillOffered,
      'skill_wanted': skillWanted,
      'exchange_type': exchangeType,
      'custom_offer': customOffer,
      'tags': tags,
      'is_open_request': isOpenRequest,
    };
  }
}
