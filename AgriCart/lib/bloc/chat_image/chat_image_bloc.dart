import 'dart:io';

import 'package:bloc/bloc.dart';
import 'package:image_picker/image_picker.dart';

import '../../services/api_service.dart';
import 'chat_image_event.dart';
import 'chat_image_state.dart';

class ChatImageBloc extends Bloc<ChatImageEvent, ChatImageState> {
  final ApiService apiService;
  final ImagePicker _picker = ImagePicker();

  ChatImageBloc({required this.apiService}) : super(ChatImageInitial()) {
    on<ChatImagePickRequested>(_onPickRequested);
    on<ChatImageRetryRequested>(_onRetryRequested);
  }

  Future<void> _onPickRequested(ChatImagePickRequested event, Emitter<ChatImageState> emit) async {
    emit(ChatImagePicking());
    try {
      final picked = await _picker.pickImage(source: event.source, imageQuality: 85);
      if (picked == null) {
        emit(ChatImageInitial());
        return;
      }
      emit(ChatImageUploading(picked.path));
      final file = File(picked.path);
      final uploadResp = await apiService.uploadChatImage(file);
      final imageUrl = uploadResp['image_url'] as String?;
      if (imageUrl == null) {
        emit(ChatImageUploadFailure(localPath: picked.path, error: 'No image_url in response'));
        return;
      }
      // send message containing image
      final sendResp = await apiService.sendImageMessage(event.receiverId, imageUrl);
      if (sendResp['status'] != 'success') {
        emit(ChatImageUploadFailure(localPath: picked.path, error: 'Message send failed'));
        return;
      }
      emit(ChatImageUploadSuccess(imageUrl));
      // Return to initial so UI can allow new picks
      emit(ChatImageInitial());
    } catch (e) {
      emit(ChatImageUploadFailure(localPath: '', error: e.toString()));
    }
  }

  Future<void> _onRetryRequested(ChatImageRetryRequested event, Emitter<ChatImageState> emit) async {
    emit(ChatImageUploading(event.localPath));
    try {
      final file = File(event.localPath);
      if (!file.existsSync()) {
        emit(ChatImageUploadFailure(localPath: event.localPath, error: 'Local file missing'));
        return;
      }
      final uploadResp = await apiService.uploadChatImage(file);
      final imageUrl = uploadResp['image_url'] as String?;
      if (imageUrl == null) {
        emit(ChatImageUploadFailure(localPath: event.localPath, error: 'No image_url in response'));
        return;
      }
      final sendResp = await apiService.sendImageMessage(event.receiverId, imageUrl);
      if (sendResp['status'] != 'success') {
        emit(ChatImageUploadFailure(localPath: event.localPath, error: 'Message send failed'));
        return;
      }
      emit(ChatImageUploadSuccess(imageUrl));
      emit(ChatImageInitial());
    } catch (e) {
      emit(ChatImageUploadFailure(localPath: event.localPath, error: e.toString()));
    }
  }
}
