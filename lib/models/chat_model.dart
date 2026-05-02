import 'profile_model.dart';

class ChatModel {
  final String id;
  final String? postId;
  final String participant1;
  final String participant2;
  final String? lastMessage;
  final DateTime lastMessageAt;
  final bool swapConfirmed;
  final String swapStatus;
  final DateTime createdAt;
  final ProfileModel? otherUser;
  int unreadCount;

  ChatModel({
    required this.id,
    this.postId,
    required this.participant1,
    required this.participant2,
    this.lastMessage,
    required this.lastMessageAt,
    this.swapConfirmed = false,
    this.swapStatus = 'none',
    required this.createdAt,
    this.otherUser,
    this.unreadCount = 0,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json,
      {ProfileModel? otherUser}) {
    return ChatModel(
      id: json['id'] ?? '',
      postId: json['post_id'],
      participant1: json['participant_1'] ?? '',
      participant2: json['participant_2'] ?? '',
      lastMessage: json['last_message'],
      lastMessageAt: DateTime.parse(
          json['last_message_at'] ?? DateTime.now().toIso8601String()),
      swapConfirmed: json['swap_confirmed'] ?? false,
      swapStatus: json['swap_status'] ?? 'none',
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      otherUser: otherUser,
    );
  }
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String? content;
  final String? imageUrl;
  final String messageType;
  final bool isRead;
  final DateTime createdAt;
  final ProfileModel? sender;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    this.content,
    this.imageUrl,
    this.messageType = 'text',
    this.isRead = false,
    required this.createdAt,
    this.sender,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] ?? '',
      chatId: json['chat_id'] ?? '',
      senderId: json['sender_id'] ?? '',
      content: json['content'],
      imageUrl: json['image_url'],
      messageType: json['message_type'] ?? 'text',
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      sender: json['profiles'] != null
          ? ProfileModel.fromJson(json['profiles'])
          : null,
    );
  }
}

class SwapModel {
  final String id;
  final String chatId;
  final String? postId;
  final String initiatorId;
  final String receiverId;
  final String status;
  final DateTime? confirmedAt;
  final DateTime? completedAt;
  final DateTime createdAt;

  SwapModel({
    required this.id,
    required this.chatId,
    this.postId,
    required this.initiatorId,
    required this.receiverId,
    required this.status,
    this.confirmedAt,
    this.completedAt,
    required this.createdAt,
  });

  factory SwapModel.fromJson(Map<String, dynamic> json) {
    return SwapModel(
      id: json['id'] ?? '',
      chatId: json['chat_id'] ?? '',
      postId: json['post_id'],
      initiatorId: json['initiator_id'] ?? '',
      receiverId: json['receiver_id'] ?? '',
      status: json['status'] ?? 'pending',
      confirmedAt: json['confirmed_at'] != null
          ? DateTime.parse(json['confirmed_at'])
          : null,
      completedAt: json['completed_at'] != null
          ? DateTime.parse(json['completed_at'])
          : null,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}

class RatingModel {
  final String id;
  final String swapId;
  final String raterId;
  final String rateeId;
  final int rating;
  final String? review;
  final DateTime createdAt;
  final ProfileModel? rater;

  RatingModel({
    required this.id,
    required this.swapId,
    required this.raterId,
    required this.rateeId,
    required this.rating,
    this.review,
    required this.createdAt,
    this.rater,
  });

  factory RatingModel.fromJson(Map<String, dynamic> json) {
    return RatingModel(
      id: json['id'] ?? '',
      swapId: json['swap_id'] ?? '',
      raterId: json['rater_id'] ?? '',
      rateeId: json['ratee_id'] ?? '',
      rating: json['rating'] ?? 0,
      review: json['review'],
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
      rater: json['profiles'] != null
          ? ProfileModel.fromJson(json['profiles'])
          : null,
    );
  }
}

class NotificationModel {
  final String id;
  final String userId;
  final String type;
  final String title;
  final String? body;
  final Map<String, dynamic> data;
  bool isRead;
  final DateTime createdAt;

  NotificationModel({
    required this.id,
    required this.userId,
    required this.type,
    required this.title,
    this.body,
    this.data = const {},
    this.isRead = false,
    required this.createdAt,
  });

  factory NotificationModel.fromJson(Map<String, dynamic> json) {
    return NotificationModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      type: json['type'] ?? '',
      title: json['title'] ?? '',
      body: json['body'],
      data: Map<String, dynamic>.from(json['data'] ?? {}),
      isRead: json['is_read'] ?? false,
      createdAt: DateTime.parse(
          json['created_at'] ?? DateTime.now().toIso8601String()),
    );
  }
}
