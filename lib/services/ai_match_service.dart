// lib/services/ai_match_service.dart

import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../models/post_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  AiMatchResult – a single ranked match
// ─────────────────────────────────────────────────────────────────────────────
class AiMatchResult {
  final PostModel post;
  final int matchScore; // 0–100

  const AiMatchResult({required this.post, required this.matchScore});
}

// ─────────────────────────────────────────────────────────────────────────────
//  AiMatchService
// ─────────────────────────────────────────────────────────────────────────────
class AiMatchService extends ChangeNotifier {
  List<AiMatchResult> _matches = [];
  bool _isLoading = false;

  List<AiMatchResult> get matches => _matches;
  bool get isLoading => _isLoading;
  bool get hasMatches => _matches.isNotEmpty;

  // ── Public entry-point called from FeedScreen ─────────────────────────────
  Future<void> fetchMatches({
    required String mySkillOffered,
    required String mySkillWanted,
    required String myCampus,
    required String myUserId,
    required List<PostModel> allPosts,
    int maxResults = 5,
  }) async {
    if (_isLoading) return;

    _isLoading = true;
    notifyListeners();

    try {
      // Filter out the current user's own posts
      final candidates = allPosts.where((p) => p.userId != myUserId).toList();

      if (candidates.isEmpty) {
        _matches = [];
        _isLoading = false;
        notifyListeners();
        return;
      }

      // Build a compact summary of each candidate post for the prompt
      final postSummaries = candidates
          .take(30) // Cap to avoid huge prompts
          .map(
            (p) => {
              'id': p.id,
              'skillOffered': p.skillOffered,
              'skillWanted': p.skillWanted ?? '',
              'campus': p.profile?.campus ?? '',
              'tags': p.tags.join(', '),
            },
          )
          .toList();

      final prompt =
          '''
You are a skill-swap matching engine. A user offers "$mySkillOffered" and wants "$mySkillWanted".
They are at campus "$myCampus".

Below is a JSON array of candidate posts. For each post, compute a match score (0-100) based on:
1. How well their skillOffered matches what the user wants (40 pts)
2. How well their skillWanted matches what the user offers (40 pts)
3. Same campus bonus (20 pts)

Return ONLY a JSON array (no markdown, no explanation) with objects:
{"id": "<post id>", "score": <integer 0-100>}

Sorted by score descending. Include at most $maxResults entries with score >= 30.

Candidate posts:
${jsonEncode(postSummaries)}
''';

      final response = await http
          .post(
            Uri.parse('https://api.anthropic.com/v1/messages'),
            headers: {
              'Content-Type': 'application/json',
              // Key is injected server-side; do NOT hard-code here
            },
            body: jsonEncode({
              'model': 'claude-haiku-4-5-20251001',
              'max_tokens': 512,
              'messages': [
                {'role': 'user', 'content': prompt},
              ],
            }),
          )
          .timeout(const Duration(seconds: 20));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final text = (data['content'] as List)
            .whereType<Map>()
            .where((b) => b['type'] == 'text')
            .map((b) => b['text'] as String)
            .join();

        final ranked = _parseScores(text);
        _matches = ranked
            .map((entry) {
              final post = candidates.firstWhere(
                (p) => p.id == entry['id'],
                orElse: () => candidates.first,
              );
              return AiMatchResult(
                post: post,
                matchScore: entry['score'] as int,
              );
            })
            .where((r) => candidates.any((p) => p.id == r.post.id))
            .take(maxResults)
            .toList();
      } else {
        // Fallback: simple keyword score
        _matches = _fallbackRank(
          mySkillOffered: mySkillOffered,
          mySkillWanted: mySkillWanted,
          myCampus: myCampus,
          candidates: candidates,
          maxResults: maxResults,
        );
      }
    } catch (e) {
      debugPrint('AiMatchService error: $e');
      // Always provide a fallback so the UI doesn't stay in loading
      _matches = _fallbackRank(
        mySkillOffered: mySkillOffered,
        mySkillWanted: mySkillWanted,
        myCampus: myCampus,
        candidates: allPosts.where((p) => p.userId != myUserId).toList(),
        maxResults: maxResults,
      );
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ── Parse JSON scores from Claude response ────────────────────────────────
  List<Map<String, dynamic>> _parseScores(String text) {
    try {
      // Strip any accidental markdown fences
      final clean = text.replaceAll(RegExp(r'```json|```'), '').trim();
      final list = jsonDecode(clean) as List;
      return list.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // ── Fallback: simple keyword-based ranking ────────────────────────────────
  List<AiMatchResult> _fallbackRank({
    required String mySkillOffered,
    required String mySkillWanted,
    required String myCampus,
    required List<PostModel> candidates,
    required int maxResults,
  }) {
    int score(PostModel p) {
      int s = 0;
      final offered = p.skillOffered.toLowerCase();
      final wanted = (p.skillWanted ?? '').toLowerCase();
      final campus = (p.profile?.campus ?? '').toLowerCase();

      if (offered.contains(mySkillWanted.toLowerCase()) ||
          mySkillWanted.toLowerCase().contains(offered))
        s += 40;
      if (wanted.contains(mySkillOffered.toLowerCase()) ||
          mySkillOffered.toLowerCase().contains(wanted))
        s += 40;
      if (campus == myCampus.toLowerCase()) s += 20;
      return s;
    }

    final scored =
        candidates
            .map((p) => AiMatchResult(post: p, matchScore: score(p)))
            .where((r) => r.matchScore >= 20)
            .toList()
          ..sort((a, b) => b.matchScore.compareTo(a.matchScore));

    return scored.take(maxResults).toList();
  }

  void clearMatches() {
    _matches = [];
    _isLoading = false;
    notifyListeners();
  }
}
