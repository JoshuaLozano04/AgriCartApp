import 'package:equatable/equatable.dart';

abstract class ChatEvent extends Equatable {
  const ChatEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversationEvent extends ChatEvent {
  final String user1Id;
  final String user2Id;

  const LoadConversationEvent({
    required this.user1Id,
    required this.user2Id,
  });

  @override
  List<Object?> get props => [user1Id, user2Id];
}

class SendMessageEvent extends ChatEvent {
  final String senderId;
  final String receiverId;
  final String message;

  const SendMessageEvent({
    required this.senderId,
    required this.receiverId,
    required this.message,
  });

  @override
  List<Object?> get props => [senderId, receiverId, message];
}

class RefreshConversationEvent extends ChatEvent {
  final String user1Id;
  final String user2Id;

  const RefreshConversationEvent({
    required this.user1Id,
    required this.user2Id,
  });

  @override
  List<Object?> get props => [user1Id, user2Id];
}

