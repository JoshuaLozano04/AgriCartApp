import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/user.dart';
import '../../services/api_service.dart';
import '../../services/token_storage_service.dart';
import 'auth_event.dart';
import 'auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  final ApiService apiService;
  final TokenStorageService _tokenStorage = TokenStorageService();

  AuthBloc({required this.apiService}) : super(AuthInitial()) {
    on<RegisterEvent>(_onRegister);
    on<LoginEvent>(_onLogin);
    on<VerifyUserEvent>(_onVerifyUser);
    on<LoadUserProfileEvent>(_onLoadUserProfile);
    on<UpdateProfileEvent>(_onUpdateProfile);
    on<LogoutEvent>(_onLogout);
    on<LoadStoredTokenEvent>(_onLoadStoredToken);
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
        emit(AuthError(message: response['message'] ?? 'Registration failed. Please try again.'));
      }
    } catch (e) {
      emit(AuthError(message: 'Something went wrong. Please try again.'));
    }
  }

  Future<void> _onLogin(LoginEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final response = await apiService.login(event.email, event.password);
      if (response['success'] == true && response['user'] != null) {
        // Save token if provided
        if (response['token'] != null) {
          await _tokenStorage.saveToken(response['token']);
        }
        
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
        emit(AuthError(message: response['message'] ?? 'Wrong email or password'));
      }
    } catch (e) {
      emit(AuthError(message: 'Wrong email or password'));
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
      // Check if token exists before making request
      final hasToken = await _tokenStorage.hasToken();
      print('DEBUG AuthBloc: Loading profile, hasToken=$hasToken');
      
      if (!hasToken) {
        emit(AuthUnauthenticated());
        return;
      }
      
      final response = await apiService.getUserProfile();
      if (response['success'] == true && response['user'] != null) {
        final user = User.fromJson(response['user']);
        emit(AuthAuthenticated(user: user));
      } else {
        emit(AuthError(message: 'Failed to load user profile'));
      }
    } catch (e) {
      print('DEBUG AuthBloc: Error loading profile: $e');
      
      // Handle connection errors gracefully
      if (e.toString().contains('Connection refused') || 
          e.toString().contains('SocketException') ||
          e.toString().contains('Failed host lookup')) {
        // Connection error - likely server not running or wrong URL
        // For development: user needs to start server or configure correct URL
        // Don't clear token - might be valid, just can't reach server
        emit(AuthUnauthenticated()); // Go back to login screen
        return;
      }
      
      // If unauthorized, clear token and logout
      if (e.toString().contains('401') || e.toString().contains('Unauthorized')) {
        print('DEBUG AuthBloc: Unauthorized - deleting token');
        await _tokenStorage.deleteToken();
        emit(AuthUnauthenticated());
        return;
      }
      
      // Other errors
      emit(AuthError(message: 'Error loading profile: $e'));
    }
  }
  
  Future<void> _onLoadStoredToken(LoadStoredTokenEvent event, Emitter<AuthState> emit) async {
    emit(AuthLoading());
    try {
      final hasToken = await _tokenStorage.hasToken();
      if (hasToken) {
        // Token exists, load user profile to verify it's valid
        add(LoadUserProfileEvent(userId: ''));  // userId no longer needed
      } else {
        emit(AuthUnauthenticated());
      }
    } catch (e) {
      emit(AuthUnauthenticated());
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
    await _tokenStorage.deleteToken();
    emit(AuthUnauthenticated());
  }
}

