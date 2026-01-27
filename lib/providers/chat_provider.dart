import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/chat_model.dart';
import '../services/chat_service.dart';
import 'auth_provider.dart';

final chatServiceProvider = Provider((ref) => ChatService());

final userChatsProvider = StreamProvider<List<ChatModel>>((ref) {
  final chatService = ref.watch(chatServiceProvider);
  final user = ref.watch(currentUserProvider).value;

  if (user == null) return Stream.value([]);

  return chatService.watchUserChats(user.id);
});

final chatMessagesProvider = StreamProvider.family<List<MessageModel>, String>((ref, chatId) {
  final chatService = ref.watch(chatServiceProvider);
  return chatService.watchMessages(chatId);
});
