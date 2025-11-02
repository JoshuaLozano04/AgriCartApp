import 'package:equatable/equatable.dart';
import '../../models/user.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class RegisterEvent extends AuthEvent {
  final User user;
  final String password;

  const RegisterEvent({required this.user, required this.password});

  @override
  List<Object?> get props => [user, password];
}

class LoginEvent extends AuthEvent {
  final String email;
  final String password;

  const LoginEvent({required this.email, required this.password});

  @override
  List<Object?> get props => [email, password];
}

class VerifyUserEvent extends AuthEvent {
  final String userId;
  final String verificationType; // 'id' or 'phone'
  final String verificationData;

  const VerifyUserEvent({
    required this.userId,
    required this.verificationType,
    required this.verificationData,
  });

  @override
  List<Object?> get props => [userId, verificationType, verificationData];
}

class LoadUserProfileEvent extends AuthEvent {
  final String userId;

  const LoadUserProfileEvent({required this.userId});

  @override
  List<Object?> get props => [userId];
}

class UpdateProfileEvent extends AuthEvent {
  final String userId;
  final Map<String, dynamic> updates;

  const UpdateProfileEvent({required this.userId, required this.updates});

  @override
  List<Object?> get props => [userId, updates];
}

class LogoutEvent extends AuthEvent {
  const LogoutEvent();
}

class LoadStoredTokenEvent extends AuthEvent {
  const LoadStoredTokenEvent();

  @override
  List<Object?> get props => [];
}

