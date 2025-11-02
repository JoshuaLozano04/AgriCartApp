import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class TokenStorageService {
  static const _storage = FlutterSecureStorage();
  static const _tokenKey = 'auth_token';

  /// Save JWT token to secure storage
  Future<void> saveToken(String token) async {
    await _storage.write(key: _tokenKey, value: token);
  }

  /// Get JWT token from secure storage
  Future<String?> getToken() async {
    return await _storage.read(key: _tokenKey);
  }

  /// Delete JWT token from secure storage (logout)
  Future<void> deleteToken() async {
    await _storage.delete(key: _tokenKey);
  }

  /// Check if token exists
  Future<bool> hasToken() async {
    final token = await getToken();
    return token != null && token.isNotEmpty;
  }
}

