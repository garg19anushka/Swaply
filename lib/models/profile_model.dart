// =============================================
// lib/models/profile_model.dart
// =============================================

class ProfileModel {
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final String? bio;
  final String? campus;
  final List<String> skillsOffered;
  final List<String> skillsWanted;
  final int totalSwaps;
  final double averageRating;
  final int ratingCount;
  final DateTime createdAt;

  // Dynamic Badges System
  List<String> get badges {
    List<String> userBadges = [];
    if (totalSwaps >= 5 && averageRating >= 4.5) {
      userBadges.add("Top Mentor");
    }
    if (ratingCount >= 3) {
      userBadges.add("Trusted User");
    }
    if (totalSwaps >= 10) {
      userBadges.add("Fast Responder");
    }
    return userBadges;
  }

  ProfileModel({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    this.bio,
    this.campus,
    this.skillsOffered = const [],
    this.skillsWanted = const [],
    this.totalSwaps = 0,
    this.averageRating = 0.0,
    this.ratingCount = 0,
    required this.createdAt,
  });

  factory ProfileModel.fromJson(Map<String, dynamic> json) {
    return ProfileModel(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      bio: json['bio'],
      campus: json['campus'],
      skillsOffered: List<String>.from(json['skills_offered'] ?? []),
      skillsWanted: List<String>.from(json['skills_wanted'] ?? []),
      totalSwaps: json['total_swaps'] ?? 0,
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      ratingCount: json['rating_count'] ?? 0,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'full_name': fullName,
      'avatar_url': avatarUrl,
      'bio': bio,
      'campus': campus,
      'skills_offered': skillsOffered,
      'skills_wanted': skillsWanted,
    };
  }

  ProfileModel copyWith({
    String? fullName,
    String? avatarUrl,
    String? bio,
    String? campus,
    List<String>? skillsOffered,
    List<String>? skillsWanted,
  }) {
    return ProfileModel(
      id: id,
      username: username,
      fullName: fullName ?? this.fullName,
      avatarUrl: avatarUrl ?? this.avatarUrl,
      bio: bio ?? this.bio,
      campus: campus ?? this.campus,
      skillsOffered: skillsOffered ?? this.skillsOffered,
      skillsWanted: skillsWanted ?? this.skillsWanted,
      totalSwaps: totalSwaps,
      averageRating: averageRating,
      ratingCount: ratingCount,
      createdAt: createdAt,
    );
  }
}
