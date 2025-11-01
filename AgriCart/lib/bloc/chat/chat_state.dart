import 'package:equatable/equatable.dart';
import '../../models/message.dart';

abstract class ChatState extends Equatable {
  const ChatState();

  @override
  List<Object?> get props => [];
}

class ChatInitial extends ChatState {}

class ChatLoading extends ChatState {}

class ChatLoaded extends ChatState {
  final List<Message> messages;

  const ChatLoaded({required this.messages});

  @override
  List<Object?> get props => [messages];
}

class MessageSent extends ChatState {
  final String messageId;

  const MessageSent({required this.messageId});

  @override
  List<Object?> get props => [messageId];
}

class ChatError extends ChatState {
  final String message;

  const ChatError({required this.message});

  @override
  List<Object?> get props => [message];
}

