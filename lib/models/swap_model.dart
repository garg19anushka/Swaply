// lib/models/swap_model.dart

class SwapModel {
  final String id;
  final String swapTitle;
  final double progress; // 0.0 – 1.0
  final String progressLabel; // e.g. "Session 2 of 4 complete"
  final int totalSessions;
  final int doneSessions;
  final String nextSessionLabel; // e.g. "Next: Thu, 15 May @ 5 PM"
  final String? partnerName;
  final String? partnerUsername;
  final String? partnerAvatarUrl;
  final String status; // 'active' | 'completed' | 'cancelled' | 'pending'

  const SwapModel({
    required this.id,
    required this.swapTitle,
    required this.progress,
    required this.progressLabel,
    required this.totalSessions,
    required this.doneSessions,
    required this.nextSessionLabel,
    this.partnerName,
    this.partnerUsername,
    this.partnerAvatarUrl,
    this.status = 'active',
  });

  factory SwapModel.fromMap(Map<String, dynamic> map) {
    final done = (map['done_sessions'] as num?)?.toInt() ?? 0;
    final total = (map['total_sessions'] as num?)?.toInt() ?? 1;
    return SwapModel(
      id: map['id']?.toString() ?? '',
      swapTitle: map['swap_title']?.toString() ?? 'Skill Swap',
      progress: total > 0 ? done / total : 0.0,
      progressLabel:
          map['progress_label']?.toString() ??
          'Session $done of $total complete',
      totalSessions: total,
      doneSessions: done,
      nextSessionLabel: map['next_session_label']?.toString() ?? 'TBD',
      partnerName: map['partner_name']?.toString(),
      partnerUsername: map['partner_username']?.toString(),
      partnerAvatarUrl: map['partner_avatar_url']?.toString(),
      status: map['status']?.toString() ?? 'active',
    );
  }

  // alias so both fromMap and fromJson work
  factory SwapModel.fromJson(Map<String, dynamic> json) =>
      SwapModel.fromMap(json);

  Map<String, dynamic> toMap() => {
    'id': id,
    'swap_title': swapTitle,
    'total_sessions': totalSessions,
    'done_sessions': doneSessions,
    'progress_label': progressLabel,
    'next_session_label': nextSessionLabel,
    'partner_name': partnerName,
    'partner_username': partnerUsername,
    'partner_avatar_url': partnerAvatarUrl,
    'status': status,
  };
}
