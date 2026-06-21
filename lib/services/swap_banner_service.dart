// swap_banner_service.dart
//
// Fixes the "second banner overwrites the first" bug in Swaply chat.
//
// CONFIRMED FROM YOUR SCREENSHOTS:
//   Image 1: chat with Harsheen, banner = "Java Programming Help"
//   Image 2: SAME chat with Harsheen, after starting a chat from a
//            different post ("Teach Canva Design") — the Java banner
//            is GONE, replaced by the Canva one. Same thread, same
//            messages above/below, only the banner changed.
//
// ROOT CAUSE (in the current code):
//   - `chats` table has ONE `post_id` + ONE `banner_after_index` column.
//   - `ChatService.getOrCreateChat()` reuses the existing chat row when
//     User A messages the same User B again, but never updates `post_id`
//     for the new post, and `saveBannerIndex()` is a no-op once the
//     column is already set on that row.
//   - `chat_screen.dart` then loads "the post for this chat" (singular)
//     via `fetchPostForChat()`, which just does `chats.post_id -> posts`.
//     Whatever the LATEST `post_id` value is, that's the only banner
//     the UI can ever render — there is no second slot.
//   - Net effect: every time you start from a different post with the
//     same person, the new post's banner silently replaces the old
//     one's banner in the UI. Nothing is actually appended/stored
//     per-post — exactly what your screenshots show.
//
// FIX:
//   - Move from "1 banner field per chat" to "1 banner ROW per post"
//     in a new `chat_swap_banners` table (real DB rows, not a UI-only
//     virtual item). Each row anchors to the message count at the time
//     the post-based chat was opened, so it renders in the correct
//     chronological position, and new banners always land after older
//     ones (bottom / most recent).
//   - `unique(chat_id, post_id)` enforces "one banner per unique post
//     they swap-requested" with NO cap on how many distinct posts/banners
//     a single chat can accumulate.
//
// REQUIRED SUPABASE MIGRATION (run once, in SQL editor):
//
//   create table chat_swap_banners (
//     id uuid primary key default gen_random_uuid(),
//     chat_id uuid not null references chats(id) on delete cascade,
//     post_id uuid not null references posts(id) on delete cascade,
//     created_by uuid not null references profiles(id),
//     message_index_at_creation int not null,
//     created_at timestamptz not null default now(),
//     unique (chat_id, post_id)
//   );
//
//   alter table chat_swap_banners enable row level security;
//
//   create policy "Participants can read banners"
//     on chat_swap_banners for select
//     using (
//       exists (
//         select 1 from chats c
//         where c.id = chat_swap_banners.chat_id
//           and (c.participant_1 = auth.uid() or c.participant_2 = auth.uid())
//       )
//     );
//
//   create policy "Participants can insert banners"
//     on chat_swap_banners for insert
//     with check (
//       exists (
//         select 1 from chats c
//         where c.id = chat_swap_banners.chat_id
//           and (c.participant_1 = auth.uid() or c.participant_2 = auth.uid())
//       )
//     );
//
//   -- Optional but recommended: migrate any existing single banners
//   -- (old chats.post_id / banner_after_index) into the new table so
//   -- nobody loses their current banner on rollout:
//   insert into chat_swap_banners
//     (chat_id, post_id, created_by, message_index_at_creation)
//   select id, post_id, participant_1, coalesce(banner_after_index, 0)
//   from chats
//   where post_id is not null
//   on conflict (chat_id, post_id) do nothing;
//
// HOW TO WIRE THIS IN:
//   1. Drop this file into lib/services/swap_banner_service.dart
//   2. In post_detail_screen.dart, after getOrCreateChat() succeeds, call:
//        await SwapBannerService.instance.ensureBannerForPost(
//          chatId: chat.id,
//          postId: post.id,
//        );
//   3. In chat_screen.dart, replace the single `_bannerAfterIndex`/
//      `_sourcePost` fields with a `List<BannerWithPost> _banners`,
//      fetched via `fetchBannersWithPosts(chatId)`, and render every
//      entry whose anchor matches the current ListView index — see the
//      itemBuilder pattern documented in the class doc-comment below.

import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../main.dart'; // exposes the shared `supabase` client

/// A single "Started from swap" banner event.
///
/// Unlike the old `bannerAfterIndex` int on `ChatModel`, this is a REAL,
/// independently-persisted row — one per (chat, post) pair. A chat can
/// have any number of these; each one survives reload because it lives
/// in `chat_swap_banners`, not in client-side state, and inserting a new
/// one never touches or deletes an older one.
@immutable
class SwapBannerModel {
  final String id;
  final String chatId;
  final String postId;
  final String createdBy;

  /// How many real messages existed in the chat when this banner's
  /// source post was opened. Used purely to anchor the banner's
  /// position when splicing it into the message ListView — it does
  /// NOT change as new messages arrive, so the banner stays pinned
  /// to the point in history where that swap was started.
  final int messageIndexAtCreation;

  final DateTime createdAt;

  const SwapBannerModel({
    required this.id,
    required this.chatId,
    required this.postId,
    required this.createdBy,
    required this.messageIndexAtCreation,
    required this.createdAt,
  });

  factory SwapBannerModel.fromJson(Map<String, dynamic> json) {
    return SwapBannerModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      postId: json['post_id'] as String,
      createdBy: json['created_by'] as String,
      messageIndexAtCreation: json['message_index_at_creation'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toInsertJson() => {
    'chat_id': chatId,
    'post_id': postId,
    'created_by': createdBy,
    'message_index_at_creation': messageIndexAtCreation,
  };
}

/// A banner paired with the full post data needed to render it
/// (title, skillOffered, skillWanted, etc). Returned by
/// [SwapBannerService.fetchBannersWithPosts] so chat_screen.dart doesn't
/// need a separate query per banner.
class BannerWithPost {
  final SwapBannerModel banner;
  final Map<String, dynamic> post;
  const BannerWithPost({required this.banner, required this.post});
}

/// Handles creating and fetching the (potentially many) swap banners
/// that belong to a single chat thread.
///
/// Replaces `ChatService.saveBannerIndex` / `ChatService.fetchPostForChat`,
/// which only ever supported a single banner per chat and is what caused
/// the second banner to overwrite the first.
///
/// ── Rendering multiple banners in chat_screen.dart ──────────────────
/// Old code only ever inserted ONE virtual item into the ListView:
///
///   itemCount: cs.messages.length + (_bannerAfterIndex != null ? 1 : 0)
///
/// New approach — group banners by their anchor index, since several
/// banners CAN share the same anchor (e.g. two posts opened back-to-back
/// before any new message was sent), and render all of them there:
///
///   final bannersByIndex = <int, List<BannerWithPost>>{};
///   for (final bp in _banners) {
///     bannersByIndex.putIfAbsent(bp.banner.messageIndexAtCreation, () => []).add(bp);
///   }
///   final totalBannerCount = _banners.length;
///
///   ListView.builder(
///     itemCount: cs.messages.length + totalBannerCount,
///     itemBuilder: (_, i) {
///       // Walk through message slots, splicing in every banner whose
///       // anchor index has been reached but not yet rendered.
///       int messagesSeen = 0;
///       int bannersRendered = 0;
///       for (int slot = 0; slot <= i; slot++) {
///         final bannersHere = bannersByIndex[messagesSeen] ?? const [];
///         if (bannersRendered < bannersHere.length &&
///             slot == messagesSeen + bannersRendered) {
///           // this slot is a banner
///           if (slot == i) {
///             final bp = bannersHere[bannersRendered];
///             return _SwapContextBanner(postJson: bp.post, isDark: _d);
///           }
///           bannersRendered++;
///           continue;
///         }
///         if (slot == i) {
///           return _buildMessageRow(cs.messages[messagesSeen]);
///         }
///         messagesSeen++;
///         bannersRendered = 0;
///       }
///       return const SizedBox.shrink();
///     },
///   )
///
/// (A simpler, equally correct alternative if you don't need banners
/// interleaved mid-history: always render new banners as a single
/// scrollable column ABOVE message index 0, in creation order — that
/// naturally stacks "Java Programming Help" then "Teach Canva Design"
/// without any index math at all. Recommended if every banner is
/// created at/near the top of an empty or short chat, which matches
/// your screenshots.)
class SwapBannerService {
  SwapBannerService._();
  static final SwapBannerService instance = SwapBannerService._();

  /// Call this whenever a user taps "Start a Chat" / "Start Swap" from a
  /// post's detail screen — whether or not a chat with that person
  /// already exists.
  ///
  /// - If this is the first time User A has opened a chat from THIS post
  ///   with THIS person, a new banner row is created, anchored at the
  ///   current message count (so it appears at the bottom of whatever
  ///   history already exists).
  /// - If a banner for this exact (chat, post) pair already exists
  ///   (e.g. user re-opened the same post a second time), nothing new is
  ///   inserted — `unique(chat_id, post_id)` is respected, and the
  ///   existing row is returned instead.
  ///
  /// This is what makes multiple banners possible: each distinct post
  /// gets its own row, and old banners are never overwritten or deleted.
  Future<SwapBannerModel?> ensureBannerForPost({
    required String chatId,
    required String postId,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      // Has a banner for this exact post already been created in this chat?
      final existing = await supabase
          .from('chat_swap_banners')
          .select()
          .eq('chat_id', chatId)
          .eq('post_id', postId)
          .maybeSingle();

      if (existing != null) {
        return SwapBannerModel.fromJson(existing);
      }

      // New post for this chat -> anchor the banner at the bottom of the
      // current message history, then insert a brand-new row. Existing
      // banners for other posts in this chat (e.g. "Java Programming
      // Help") are completely untouched by this insert.
      final messageCount = await supabase
          .from('messages')
          .select('id')
          .eq('chat_id', chatId)
          .count(CountOption.exact);

      final inserted = await supabase
          .from('chat_swap_banners')
          .insert({
            'chat_id': chatId,
            'post_id': postId,
            'created_by': userId,
            'message_index_at_creation': messageCount.count,
          })
          .select()
          .single();

      return SwapBannerModel.fromJson(inserted);
    } catch (e) {
      debugPrint('SwapBannerService.ensureBannerForPost error: $e');
      return null;
    }
  }

  /// Fetches EVERY banner for a chat, ordered by where they anchor in the
  /// message history (oldest swap first, newest swap last/bottom).
  ///
  /// Both participants get the identical list on every open, because it's
  /// read straight from `chat_swap_banners` — there's no per-user state.
  Future<List<SwapBannerModel>> fetchBannersForChat(String chatId) async {
    try {
      final rows = await supabase
          .from('chat_swap_banners')
          .select()
          .eq('chat_id', chatId)
          .order('message_index_at_creation', ascending: true)
          .order('created_at', ascending: true);

      return (rows as List)
          .map((r) => SwapBannerModel.fromJson(r as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('SwapBannerService.fetchBannersForChat error: $e');
      return [];
    }
  }

  /// Convenience: fetches banners AND their associated post data in one
  /// go, so chat_screen.dart doesn't need a separate N+1 query per banner.
  /// Returns entries in the same order as [fetchBannersForChat] — i.e.
  /// oldest swap first, so iterating this list and rendering each in
  /// order naturally stacks them top-to-bottom, newest at the bottom.
  ///
  /// Joins `profiles` (same shape post_service.dart uses) so each post
  /// map includes a nested `profiles` object — this is what lets
  /// PostModel.fromMap populate `post.profile`, which the banner uses
  /// to show "by <name>" next to the title.
  static const _profileSelect = '''
    profiles (
      id, username, full_name, avatar_url, campus,
      average_rating, total_swaps, rating_count
    )
  ''';

  Future<List<BannerWithPost>> fetchBannersWithPosts(String chatId) async {
    final banners = await fetchBannersForChat(chatId);
    if (banners.isEmpty) return [];

    try {
      final postIds = banners.map((b) => b.postId).toSet().toList();
      final posts = await supabase
          .from('posts')
          .select('*, $_profileSelect')
          .inFilter('id', postIds);

      final postsById = <String, Map<String, dynamic>>{
        for (final p in posts as List)
          p['id'] as String: p as Map<String, dynamic>,
      };

      return banners
          .where((b) => postsById.containsKey(b.postId))
          .map((b) => BannerWithPost(banner: b, post: postsById[b.postId]!))
          .toList();
    } catch (e) {
      debugPrint('SwapBannerService.fetchBannersWithPosts error: $e');
      return [];
    }
  }
}
