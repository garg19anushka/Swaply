import 'package:flutter/material.dart';
import '../main.dart';

class LeaderboardEntry {
  final String id;
  final String username;
  final String? fullName;
  final String? avatarUrl;
  final int totalSwaps;
  final double averageRating;
  final int ratingCount;
  final List<String> skillsOffered;
  final double score;

  LeaderboardEntry({
    required this.id,
    required this.username,
    this.fullName,
    this.avatarUrl,
    required this.totalSwaps,
    required this.averageRating,
    required this.ratingCount,
    required this.skillsOffered,
    required this.score,
  });

  factory LeaderboardEntry.fromJson(Map<String, dynamic> json) {
    return LeaderboardEntry(
      id: json['id'] ?? '',
      username: json['username'] ?? '',
      fullName: json['full_name'],
      avatarUrl: json['avatar_url'],
      totalSwaps: json['total_swaps'] ?? 0,
      averageRating: (json['average_rating'] ?? 0.0).toDouble(),
      ratingCount: json['rating_count'] ?? 0,
      skillsOffered: List<String>.from(json['skills_offered'] ?? []),
      score: (json['score'] ?? 0.0).toDouble(),
    );
  }
}

class LeaderboardService extends ChangeNotifier {
  List<LeaderboardEntry> _entries = [];
  List<LeaderboardEntry> _filteredEntries = [];
  bool _isLoading = false;
  String? _error;

  List<LeaderboardEntry> get entries => _entries;
  List<LeaderboardEntry> get filteredEntries => _filteredEntries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  /// Fetch overall leaderboard
  Future<void> fetchLeaderboard() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final data = await supabase
          .from('profiles')
          .select(
            'id, username, full_name, avatar_url, total_swaps, average_rating, rating_count, skills_offered',
          )
          .or('total_swaps.gt.0,rating_count.gt.0')
          .order('total_swaps', ascending: false)
          .limit(50);

      _entries = (data as List).map((json) {
        // Calculate score locally
        final swaps = (json['total_swaps'] ?? 0) as int;
        final rating = (json['average_rating'] ?? 0.0).toDouble();
        json['score'] = swaps * 10 + rating * 20;
        return LeaderboardEntry.fromJson(json);
      }).toList();

      // Sort by score descending
      _entries.sort((a, b) => b.score.compareTo(a.score));
      _filteredEntries = List.from(_entries);
    } catch (e) {
      _error = e.toString();
      debugPrint('Leaderboard error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Filter leaderboard by skill
  void filterBySkill(String? skill) {
    if (skill == null || skill.isEmpty || skill == 'All Skills') {
      _filteredEntries = List.from(_entries);
    } else {
      _filteredEntries = _entries
          .where(
            (e) => e.skillsOffered.any(
              (s) => s.toLowerCase().contains(skill.toLowerCase()),
            ),
          )
          .toList();
    }
    notifyListeners();
  }

  /// Get all unique skills from leaderboard entries
  List<String> get allSkills {
    final Set<String> skills = {};
    for (final entry in _entries) {
      skills.addAll(entry.skillsOffered);
    }
    final list = skills.toList()..sort();
    return ['All Skills', ...list];
  }
}
