import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversationEvent extends ChatEvent {
  final String user2Id;
  // user1Id comes from token

  const LoadConversationEvent({
    required this.user2Id,
  });

  @override
  List<Object?> get props => [user2Id];
}

class SendMessageEvent extends ChatEvent {
  final String receiverId;
  final String message;
  // senderId comes from token

  const SendMessageEvent({
    required this.receiverId,
    required this.message,
  });

  @override
  List<Object?> get props => [receiverId, message];
}

class RefreshConversationEvent extends ChatEvent {
  final String user2Id;
  // user1Id comes from token

  const RefreshConversationEvent({
    required this.user2Id,
  });

  @override
  List<Object?> get props => [user2Id];
}

