class ChatModel {
  final String id;
  final String customerId;
  final String technicianId;
  final String? bookingId;
  final String? lastMessage;
  final DateTime? lastMessageAt;
  final int unreadCountCustomer;
  final int unreadCountTechnician;
  final DateTime createdAt;
  final DateTime? updatedAt;

  ChatModel({
    required this.id,
    required this.customerId,
    required this.technicianId,
    this.bookingId,
    this.lastMessage,
    this.lastMessageAt,
    this.unreadCountCustomer = 0,
    this.unreadCountTechnician = 0,
    required this.createdAt,
    this.updatedAt,
  });

  factory ChatModel.fromJson(Map<String, dynamic> json) {
    return ChatModel(
      id: json['id'] as String,
      customerId: json['customer_id'] as String,
      technicianId: json['technician_id'] as String,
      bookingId: json['booking_id'] as String?,
      lastMessage: json['last_message'] as String?,
      lastMessageAt: json['last_message_at'] != null
          ? DateTime.parse(json['last_message_at'] as String)
          : null,
      unreadCountCustomer: json['unread_count_customer'] as int? ?? 0,
      unreadCountTechnician: json['unread_count_technician'] as int? ?? 0,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'customer_id': customerId,
      'technician_id': technicianId,
      'booking_id': bookingId,
      'last_message': lastMessage,
      'last_message_at': lastMessageAt?.toIso8601String(),
      'unread_count_customer': unreadCountCustomer,
      'unread_count_technician': unreadCountTechnician,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt?.toIso8601String(),
    };
  }
}

class MessageModel {
  final String id;
  final String chatId;
  final String senderId;
  final String message;
  final String? imageUrl;
  final bool isRead;
  final DateTime createdAt;

  MessageModel({
    required this.id,
    required this.chatId,
    required this.senderId,
    required this.message,
    this.imageUrl,
    this.isRead = false,
    required this.createdAt,
  });

  factory MessageModel.fromJson(Map<String, dynamic> json) {
    return MessageModel(
      id: json['id'] as String,
      chatId: json['chat_id'] as String,
      senderId: json['sender_id'] as String,
      message: json['message'] as String,
      imageUrl: json['image_url'] as String?,
      isRead: json['is_read'] as bool? ?? false,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'chat_id': chatId,
      'sender_id': senderId,
      'message': message,
      'image_url': imageUrl,
      'is_read': isRead,
      'created_at': createdAt.toIso8601String(),
    };
  }
}
