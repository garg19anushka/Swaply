import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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

  // Track the current user's last known rank so we can detect rank-ups
  int? _lastKnownRank;

  List<LeaderboardEntry> get entries => _entries;
  List<LeaderboardEntry> get filteredEntries => _filteredEntries;
  bool get isLoading => _isLoading;
  String? get error => _error;

  final _supabase = Supabase.instance.client;

  /// Fetch overall leaderboard and notify the current user if they ranked up
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
        final swaps = (json['total_swaps'] ?? 0) as int;
        final rating = (json['average_rating'] ?? 0.0).toDouble();
        json['score'] = swaps * 10 + rating * 20;
        return LeaderboardEntry.fromJson(json);
      }).toList();

      // Sort by score descending
      _entries.sort((a, b) => b.score.compareTo(a.score));
      _filteredEntries = List.from(_entries);

      // ── Rank-up notification ─────────────────────────────────────────────
      final currentUserId = _supabase.auth.currentUser?.id;
      if (currentUserId != null) {
        // Find the current user's position (1-indexed)
        final newRankIndex = _entries.indexWhere((e) => e.id == currentUserId);

        if (newRankIndex != -1) {
          final newRank = newRankIndex + 1;
          final lastRank = _lastKnownRank;
          final entry = _entries[newRankIndex];
          final points = entry.score.toInt();

          // Only notify if they moved UP and are in the top 100
          if (lastRank != null && newRank < lastRank && newRank <= 100) {
            final displayName = entry.fullName ?? entry.username;
            await _supabase.from('notifications').insert({
              'user_id': currentUserId,
              'type': 'leaderboard',
              'title': 'You climbed the leaderboard! 🚀',
              'body': 'You moved from #$lastRank to #$newRank — keep swapping!',
              'data': {
                'rank': '#$newRank',
                'points': '$points',
                'previous_rank': lastRank,
                'route': '/leaderboard',
              },
              'is_read': false,
            });
          }

          // Save the new rank for next time
          _lastKnownRank = newRank;
        }
      }
      // ────────────────────────────────────────────────────────────────────
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
