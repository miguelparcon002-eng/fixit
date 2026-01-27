import 'package:uuid/uuid.dart';
import '../core/config/supabase_config.dart';
import '../core/constants/db_constants.dart';
import '../models/chat_model.dart';

class ChatService {
  final _supabase = SupabaseConfig.client;
  final _uuid = const Uuid();

  Future<ChatModel> createOrGetChat({
    required String customerId,
    required String technicianId,
    String? bookingId,
  }) async {
    final existingChat = await _supabase
        .from(DBConstants.chats)
        .select()
        .eq('customer_id', customerId)
        .eq('technician_id', technicianId)
        .maybeSingle();

    if (existingChat != null) {
      return ChatModel.fromJson(existingChat);
    }

    final chatId = _uuid.v4();
    final response = await _supabase.from(DBConstants.chats).insert({
      'id': chatId,
      'customer_id': customerId,
      'technician_id': technicianId,
      'booking_id': bookingId,
      'unread_count_customer': 0,
      'unread_count_technician': 0,
    }).select().single();

    return ChatModel.fromJson(response);
  }

  Future<MessageModel> sendMessage({
    required String chatId,
    required String senderId,
    required String message,
    String? imageUrl,
  }) async {
    final messageId = _uuid.v4();

    final response = await _supabase.from(DBConstants.messages).insert({
      'id': messageId,
      'chat_id': chatId,
      'sender_id': senderId,
      'message': message,
      'image_url': imageUrl,
      'is_read': false,
    }).select().single();

    await _supabase.from(DBConstants.chats).update({
      'last_message': message,
      'last_message_at': DateTime.now().toIso8601String(),
    }).eq('id', chatId);

    return MessageModel.fromJson(response);
  }

  Future<List<MessageModel>> getMessages({
    required String chatId,
    int limit = 50,
    int offset = 0,
  }) async {
    final response = await _supabase
        .from(DBConstants.messages)
        .select()
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .range(offset, offset + limit - 1);

    return (response as List).map((e) => MessageModel.fromJson(e)).toList();
  }

  Future<List<ChatModel>> getUserChats(String userId) async {
    final response = await _supabase
        .from(DBConstants.chats)
        .select()
        .or('customer_id.eq.$userId,technician_id.eq.$userId')
        .order('last_message_at', ascending: false);

    return (response as List).map((e) => ChatModel.fromJson(e)).toList();
  }

  Future<void> markMessagesAsRead({
    required String chatId,
    required String userId,
  }) async {
    await _supabase
        .from(DBConstants.messages)
        .update({'is_read': true})
        .eq('chat_id', chatId)
        .neq('sender_id', userId);

    final chat = await _supabase
        .from(DBConstants.chats)
        .select()
        .eq('id', chatId)
        .single();

    final chatModel = ChatModel.fromJson(chat);

    if (chatModel.customerId == userId) {
      await _supabase
          .from(DBConstants.chats)
          .update({'unread_count_customer': 0})
          .eq('id', chatId);
    } else {
      await _supabase
          .from(DBConstants.chats)
          .update({'unread_count_technician': 0})
          .eq('id', chatId);
    }
  }

  Stream<List<MessageModel>> watchMessages(String chatId) {
    return _supabase
        .from(DBConstants.messages)
        .stream(primaryKey: ['id'])
        .eq('chat_id', chatId)
        .order('created_at', ascending: false)
        .map((data) => data.map((e) => MessageModel.fromJson(e)).toList());
  }

  Stream<List<ChatModel>> watchUserChats(String userId) {
    return _supabase
        .from(DBConstants.chats)
        .stream(primaryKey: ['id'])
        .order('last_message_at', ascending: false)
        .map((data) =>
            data.where((chat) =>
              chat['customer_id'] == userId || chat['technician_id'] == userId
            ).map((e) => ChatModel.fromJson(e)).toList()
        );
  }
}
