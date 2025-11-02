import 'package:flutter_bloc/flutter_bloc.dart';
import '../../services/api_service.dart';
import 'chat_event.dart';
import 'chat_state.dart';

class ChatBloc extends Bloc<ChatEvent, ChatState> {
  final ApiService apiService;

  ChatBloc({required this.apiService}) : super(ChatInitial()) {
    on<LoadConversationEvent>(_onLoadConversation);
    on<SendMessageEvent>(_onSendMessage);
    on<RefreshConversationEvent>(_onRefreshConversation);
  }

  Future<void> _onLoadConversation(
    LoadConversationEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      // user1Id comes from token, only need user2Id
      final messages = await apiService.getConversation(
        event.user2Id,
      );
      emit(ChatLoaded(messages: messages));
    } catch (e) {
      emit(ChatError(message: 'Failed to load conversation: $e'));
    }
  }

  Future<void> _onSendMessage(
    SendMessageEvent event,
    Emitter<ChatState> emit,
  ) async {
    try {
      // senderId comes from token, only need receiverId
      final response = await apiService.sendMessage(
        event.receiverId,
        event.message,
      );
      if (response['success'] == true) {
        emit(MessageSent(messageId: response['message_id']));
        // Reload conversation after sending
        add(LoadConversationEvent(
          user2Id: event.receiverId,
        ));
      } else {
        emit(ChatError(message: response['message'] ?? 'Failed to send message'));
      }
    } catch (e) {
      emit(ChatError(message: 'Error sending message: $e'));
    }
  }

  Future<void> _onRefreshConversation(
    RefreshConversationEvent event,
    Emitter<ChatState> emit,
  ) async {
    emit(ChatLoading());
    try {
      // user1Id comes from token, only need user2Id
      final messages = await apiService.getConversation(
        event.user2Id,
      );
      emit(ChatLoaded(messages: messages));
    } catch (e) {
      emit(ChatError(message: 'Failed to refresh conversation: $e'));
    }
  }
}

