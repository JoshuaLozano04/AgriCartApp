import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService apiService;

  AuthBloc({required this.apiService}) : super(AuthInitial()) {
    on<RegisterEvent>(_onRegister);
    on<LoginEvent>(_onLogin);
    on<VerifyUserEvent>(_onVerifyUser);
    on<LoadUserProfileEvent>(_onLoadUserProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<LogoutEvent>(_onLogout);
  }

  Future<void> _onRegister(RegisterEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await apiService.register(event.user, event.password);
      if (response['success'] == true) {
        emit(RegisterSuccess(userId: response['user_id']));
        // Load user profile after registration
        add(LoadUserProfileEvent(userId: response['user_id']));
      } else {
        emit(AuthError(message: response['message'] ?? 'Registration failed'));
      }
    } catch (e) {
      emit(AuthError(message: 'Registration error: $e'));
    }
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await apiService.login(event.email, event.password);
      if (response['success'] == true && response['user'] != null) {
        final userData = response['user'];
        final user = User(
          userId: userData['user_id'] ?? '',
          email: userData['email'] ?? '',
          fullName: userData['full_name'] ?? '',
          phoneNumber: userData['phone_number'] ?? '',
          role: userData['role'] ?? 'buyer',
          isVerified: userData['is_verified'] ?? false,
        );
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthError(message: response['message'] ?? 'Login failed'));
      }
    } catch (e) {
      emit(AuthError(message: 'Login error: $e'));
    }
  }

  Future<void> _onVerifyUser(VerifyUserEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // Note: Verification endpoint would need to be added to ApiService
      // For now, this is a placeholder
      emit(VerificationSuccess(isVerified: true));
    } catch (e) {
      emit(AuthError(message: 'Verification error: $e'));
    }
  }

  Future<void> _onLoadUserProfile(LoadUserProfileEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await apiService.getUserProfile(event.userId);
      if (response['success'] == true && response['user'] != null) {
        final user = User.fromJson(response['user']);
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthError(message: 'Failed to load user profile'));
      }
    } catch (e) {
      emit(AuthError(message: 'Error loading profile: $e'));
    }
  }

  Future<void> _onUpdateProfile(UpdateProfileEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      // Note: Update profile endpoint would need to be added to ApiService
      // For now, reload profile after update
      add(LoadUserProfileEvent(userId: event.userId));
    } catch (e) {
      emit(AuthError(message: 'Update error: $e'));
    }
  }

  Future<void> _onLogout(LogoutEvent event, Emitter<AuthState> emit) async {
    emit(AuthUnauthenticated());
  }
}

