import 'package:equatable/equatable.dart';
import 'package:image_picker/image_picker.dart';

abstract class ChatImageEvent extends Equatable {
  const ChatImageEvent();
  @override
  List<Object?> get props => [];
}

class ChatImagePickRequested extends ChatImageEvent {
  final ImageSource source;
  final String receiverId;
  const ChatImagePickRequested({required this.source, required this.receiverId});
  @override
  List<Object?> get props => [source, receiverId];
}

class ChatImageRetryRequested extends ChatImageEvent {
  final String localPath;
  final String receiverId;
  const ChatImageRetryRequested({required this.localPath, required this.receiverId});
  @override
  List<Object?> get props => [localPath, receiverId];
}

class ChatImageUploadRequested extends ChatImageEvent {
  final String localPath;
  final String receiverId;
  const ChatImageUploadRequested({required this.localPath, required this.receiverId});
  @override
  List<Object?> get props => [localPath, receiverId];
}
