import 'package:equatable/equatable.dart';

abstract class ChatImageState extends Equatable {
  const ChatImageState();
  @override
  List<Object?> get props => [];
}

class ChatImageInitial extends ChatImageState {}

class ChatImagePicking extends ChatImageState {}

class ChatImageUploading extends ChatImageState {
  final String localPath;
  const ChatImageUploading(this.localPath);
  @override
  List<Object?> get props => [localPath];
}

class ChatImageUploadSuccess extends ChatImageState {
  final String imageUrl;
  const ChatImageUploadSuccess(this.imageUrl);
  @override
  List<Object?> get props => [imageUrl];
}

class ChatImageUploadFailure extends ChatImageState {
  final String localPath;
  final String error;
  const ChatImageUploadFailure({required this.localPath, required this.error});
  @override
  List<Object?> get props => [localPath, error];
}
