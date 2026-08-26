import 'package:snooker_club/core/error/app_exception.dart';
import 'package:snooker_club/core/utils/logger.dart';

/// Authentication service.
/// Currently uses hardcoded credentials.
/// Will be replaced with Firebase Auth in a future phase.
class AuthService {
  bool _isLoggedIn = false;

  /// Whether the user is currently authenticated.
  bool get isLoggedIn => _isLoggedIn;

  /// Attempt to login with username and password.
  Future<bool> login(String username, String password) async {
    AppLogger.info('Login attempt for user: $username');
    await Future.delayed(const Duration(milliseconds: 400));

    if (username.trim().isNotEmpty && password.isNotEmpty) {
      _isLoggedIn = true;
      AppLogger.info('Login successful');
      return true;
    }

    AppLogger.warning('Login failed: invalid credentials');
    throw const AuthException(
      message: 'Invalid username or password',
      code: 'invalid-credentials',
    );
  }

  /// Log out the current user.
  Future<void> logout() async {
    AppLogger.info('User logged out');
    _isLoggedIn = false;
  }

  /// Check if session is still valid.
  Future<bool> checkSession() async {
    // Simulate checking persisted session
    await Future.delayed(const Duration(milliseconds: 300));
    return _isLoggedIn;
  }
}
