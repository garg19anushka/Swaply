// lib/models/swap_model.dart

class SwapModel {
  final String id;
  final String swapTitle;
  final double progress; // 0.0 – 1.0
  final String progressLabel;
  final int totalSessions;
  final int doneSessions;
  final String nextSessionLabel;

  // Legacy single-side partner fields (kept for backwards compat)
  final String? partnerName;
  final String? partnerUsername;
  final String? partnerAvatarUrl;

  final String status;
  final DateTime? expiresAt;
  final DateTime? confirmedAt;
  final String? requesterId;
  final String? responderId;
  final String? offeredSkill;
  final String? wantedSkill;

  // Per-role identity snapshots — stored in DB so both parties see
  // the correct "partner" regardless of which side they are on.
  final String? requesterName;
  final String? requesterUsername;
  final String? requesterAvatarUrl;
  final String? responderName;
  final String? responderUsername;
  final String? responderAvatarUrl;

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
    this.expiresAt,
    this.confirmedAt,
    this.requesterId,
    this.responderId,
    this.offeredSkill,
    this.wantedSkill,
    this.requesterName,
    this.requesterUsername,
    this.requesterAvatarUrl,
    this.responderName,
    this.responderUsername,
    this.responderAvatarUrl,
  });

  // ── Helpers ───────────────────────────────────────────────────────────────

  SwapStatus get swapStatus => SwapStatus.fromString(status);
  bool get needsAction => status == 'pending' || status == 'awaiting_review';

  /// Returns the display name of the *other* party given the current
  /// viewer's userId. Falls back to the legacy partnerName field so
  /// older rows (created before the per-role columns were added) still work.
  String? viewerPartnerName(String? viewerUserId) {
    if (viewerUserId == null) return partnerName;
    if (viewerUserId == requesterId) {
      return responderName ?? responderUsername ?? partnerName;
    }
    return requesterName ?? requesterUsername ?? partnerName;
  }

  String? viewerPartnerUsername(String? viewerUserId) {
    if (viewerUserId == null) return partnerUsername;
    if (viewerUserId == requesterId) {
      return responderUsername ?? partnerUsername;
    }
    return requesterUsername ?? partnerUsername;
  }

  String? viewerPartnerAvatarUrl(String? viewerUserId) {
    if (viewerUserId == null) return partnerAvatarUrl;
    if (viewerUserId == requesterId) {
      return responderAvatarUrl ?? partnerAvatarUrl;
    }
    return requesterAvatarUrl ?? partnerAvatarUrl;
  }

  String? get expiryCountdown {
    if (expiresAt == null) return null;
    final diff = expiresAt!.difference(DateTime.now());
    if (diff.isNegative) return 'Expired';
    if (diff.inHours >= 24) return '${diff.inDays}d ${diff.inHours % 24}h';
    if (diff.inHours >= 1) return '${diff.inHours}h ${diff.inMinutes % 60}m';
    return '${diff.inMinutes}m';
  }

  int get sortPriority {
    switch (swapStatus) {
      case SwapStatus.pending:
        return 0;
      case SwapStatus.awaiting_review:
        return 1;
      case SwapStatus.active:
        return 2;
      case SwapStatus.completed:
        return 3;
      case SwapStatus.cancelled:
        return 4;
      case SwapStatus.expired:
        return 5;
    }
  }

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
      expiresAt: map['expires_at'] != null
          ? DateTime.tryParse(map['expires_at'].toString())
          : null,
      confirmedAt: map['confirmed_at'] != null
          ? DateTime.tryParse(map['confirmed_at'].toString())
          : null,
      requesterId: map['requester_id']?.toString(),
      responderId: map['responder_id']?.toString(),
      offeredSkill: map['offered_skill']?.toString(),
      wantedSkill: map['wanted_skill']?.toString(),
      requesterName: map['requester_name']?.toString(),
      requesterUsername: map['requester_username']?.toString(),
      requesterAvatarUrl: map['requester_avatar_url']?.toString(),
      responderName: map['responder_name']?.toString(),
      responderUsername: map['responder_username']?.toString(),
      responderAvatarUrl: map['responder_avatar_url']?.toString(),
    );
  }

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
    'expires_at': expiresAt?.toIso8601String(),
    'confirmed_at': confirmedAt?.toIso8601String(),
    'requester_id': requesterId,
    'responder_id': responderId,
    'offered_skill': offeredSkill,
    'wanted_skill': wantedSkill,
    'requester_name': requesterName,
    'requester_username': requesterUsername,
    'requester_avatar_url': requesterAvatarUrl,
    'responder_name': responderName,
    'responder_username': responderUsername,
    'responder_avatar_url': responderAvatarUrl,
  };
}

// ─────────────────────────────────────────────────────────────────────────────
//  SwapStatus enum with helpers
// ─────────────────────────────────────────────────────────────────────────────
enum SwapStatus {
  pending,
  active,
  awaiting_review,
  completed,
  cancelled,
  expired;

  static SwapStatus fromString(String s) {
    switch (s) {
      case 'pending':
        return SwapStatus.pending;
      case 'active':
        return SwapStatus.active;
      case 'awaiting_review':
        return SwapStatus.awaiting_review;
      case 'completed':
        return SwapStatus.completed;
      case 'cancelled':
        return SwapStatus.cancelled;
      case 'expired':
        return SwapStatus.expired;
      default:
        return SwapStatus.active;
    }
  }

  String get label {
    switch (this) {
      case pending:
        return 'Pending';
      case active:
        return 'Active';
      case awaiting_review:
        return 'Rate Now';
      case completed:
        return 'Completed';
      case cancelled:
        return 'Cancelled';
      case expired:
        return 'Expired';
    }
  }

  String get emoji {
    switch (this) {
      case pending:
        return '⏳';
      case active:
        return '🔵';
      case awaiting_review:
        return '⭐';
      case completed:
        return '✅';
      case cancelled:
        return '✗';
      case expired:
        return '🕐';
    }
  }
}
