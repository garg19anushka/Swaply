import 'dart:io';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:uuid/uuid.dart';
import '../main.dart';
import '../models/chat_model.dart';
import '../models/profile_model.dart';

class ChatService extends ChangeNotifier {
  List<ChatModel> _chats = [];
  List<MessageModel> _messages = [];
  bool _isLoading = false;
  RealtimeChannel? _messageChannel;

  List<ChatModel> get chats => _chats;
  List<MessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isLoadingMessages => _isLoading;

  Future<ChatModel?> getOrCreateChat({
    required String otherUserId,
    String? postId,
  }) async {
    final currentUserId = supabase.auth.currentUser?.id;
    if (currentUserId == null) return null;

    try {
      // Check existing chat
      final existing = await supabase
          .from('chats')
          .select()
          .or('and(participant_1.eq.$currentUserId,participant_2.eq.$otherUserId),and(participant_1.eq.$otherUserId,participant_2.eq.$currentUserId)')
          .maybeSingle();

      if (existing != null) {
        final otherProfile = await supabase
            .from('profiles')
            .select()
            .eq('id', otherUserId)
            .single();
        return ChatModel.fromJson(existing,
            otherUser: ProfileModel.fromJson(otherProfile));
      }

      // Create new chat
      final data = await supabase.from('chats').insert({
        'participant_1': currentUserId,
        'participant_2': otherUserId,
        'post_id': postId,
      }).select().single();

      final otherProfile = await supabase
          .from('profiles')
          .select()
          .eq('id', otherUserId)
          .single();

      return ChatModel.fromJson(data,
          otherUser: ProfileModel.fromJson(otherProfile));
    } catch (e) {
      debugPrint('Error getting/creating chat: $e');
      return null;
    }
  }

  Future<void> fetchChats() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return;

    _isLoading = true;
    notifyListeners();

    try {
      final data = await supabase
          .from('chats')
          .select()
          .or('participant_1.eq.$userId,participant_2.eq.$userId')
          .order('last_message_at', ascending: false);

      List<ChatModel> chats = [];
      for (final chatJson in data as List) {
        final otherUserId = chatJson['participant_1'] == userId
            ? chatJson['participant_2']
            : chatJson['participant_1'];

        final profileData = await supabase
            .from('profiles')
            .select()
            .eq('id', otherUserId)
            .single();

        chats.add(ChatModel.fromJson(chatJson,
            otherUser: ProfileModel.fromJson(profileData)));
      }
      _chats = chats;
    } catch (e) {
      debugPrint('Error fetching chats: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> fetchMessages(String chatId) async {
    try {
      final data = await supabase
          .from('messages')
          .select('*, profiles(*)')
          .eq('chat_id', chatId)
          .order('created_at', ascending: true);

      _messages = (data as List).map((m) => MessageModel.fromJson(m)).toList();
      notifyListeners();
    } catch (e) {
      debugPrint('Error fetching messages: $e');
    }
  }

  void subscribeToChat(String chatId) {
    _messageChannel?.unsubscribe();
    _messageChannel = supabase.channel('chat_$chatId').onPostgresChanges(
      event: PostgresChangeEvent.insert,
      schema: 'public',
      table: 'messages',
      filter: PostgresChangeFilter(
        type: PostgresChangeFilterType.eq,
        column: 'chat_id',
        value: chatId,
      ),
      callback: (payload) async {
        final newMessage = payload.newRecord;
        // Fetch with profile
        try {
          final data = await supabase
              .from('messages')
              .select('*, profiles(*)')
              .eq('id', newMessage['id'])
              .single();
          final msg = MessageModel.fromJson(data);
          _messages.add(msg);
          notifyListeners();
        } catch (e) {
          debugPrint('Error fetching new message: $e');
        }
      },
    ).subscribe();
  }

  void unsubscribeFromChat() {
    _messageChannel?.unsubscribe();
    _messageChannel = null;
    _messages = [];
  }

  Future<bool> sendMessage({
    required String chatId,
    String? content,
    String? imageUrl,
    String messageType = 'text',
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await supabase.from('messages').insert({
        'chat_id': chatId,
        'sender_id': userId,
        'content': content,
        'image_url': imageUrl,
        'message_type': messageType,
      });

      // Update chat last message
      await supabase.from('chats').update({
        'last_message': messageType == 'image' ? '📷 Image' : content,
        'last_message_at': DateTime.now().toIso8601String(),
      }).eq('id', chatId);

      return true;
    } catch (e) {
      debugPrint('Error sending message: $e');
      return false;
    }
  }

  Future<bool> deleteMessage(String messageId, String chatId) async {
    try {
      await supabase
          .from('messages')
          .delete()
          .eq('id', messageId);

      _messages.removeWhere((m) => m.id == messageId);
      notifyListeners();
      return true;
    } catch (e) {
      debugPrint('Error deleting message: $e');
      return false;
    }
  }

  Future<String?> uploadChatImage(File imageFile) async {
    try {
      final fileName = '${const Uuid().v4()}.jpg';
      await supabase.storage.from('chat-images').upload(fileName, imageFile);
      return supabase.storage.from('chat-images').getPublicUrl(fileName);
    } catch (e) {
      debugPrint('Error uploading image: $e');
      return null;
    }
  }

  Future<SwapModel?> confirmSwap({
    required String chatId,
    required String otherUserId,
    String? postId,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return null;

    try {
      final data = await supabase.from('swaps').insert({
        'chat_id': chatId,
        'post_id': postId,
        'initiator_id': userId,
        'receiver_id': otherUserId,
        'status': 'pending',
      }).select().single();

      await supabase.from('chats').update({
        'swap_confirmed': true,
        'swap_status': 'pending',
      }).eq('id', chatId);

      // Send system message
      await sendMessage(
        chatId: chatId,
        content: '🤝 Swap confirmed! Waiting for completion.',
        messageType: 'system',
      );

      return SwapModel.fromJson(data);
    } catch (e) {
      debugPrint('Error confirming swap: $e');
      return null;
    }
  }

  Future<bool> markSwapCompleted(String swapId, String chatId) async {
    try {
      await supabase.from('swaps').update({
        'status': 'completed',
        'completed_at': DateTime.now().toIso8601String(),
      }).eq('id', swapId);

      await supabase.from('chats').update({
        'swap_status': 'completed',
      }).eq('id', chatId);

      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<SwapModel>> fetchUserSwaps() async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return [];

    try {
      final data = await supabase
          .from('swaps')
          .select()
          .or('initiator_id.eq.$userId,receiver_id.eq.$userId')
          .order('created_at', ascending: false);

      return (data as List).map((s) => SwapModel.fromJson(s)).toList();
    } catch (e) {
      return [];
    }
  }

  Future<bool> submitRating({
    required String swapId,
    required String rateeId,
    required int rating,
    String? review,
  }) async {
    final userId = supabase.auth.currentUser?.id;
    if (userId == null) return false;

    try {
      await supabase.from('ratings').insert({
        'swap_id': swapId,
        'rater_id': userId,
        'ratee_id': rateeId,
        'rating': rating,
        'review': review,
      });
      return true;
    } catch (e) {
      return false;
    }
  }

  Future<List<RatingModel>> fetchUserRatings(String userId) async {
    try {
      final data = await supabase
          .from('ratings')
          .select('*, profiles:rater_id(*)')
          .eq('ratee_id', userId)
          .order('created_at', ascending: false);

      return (data as List).map((r) => RatingModel.fromJson(r)).toList();
    } catch (e) {
      return [];
    }
  }
}
