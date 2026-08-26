import 'package:snooker_club/core/error/app_exception.dart';
import 'package:snooker_club/core/utils/logger.dart';

/// Centralized error handler for the application.
class ErrorHandler {
  ErrorHandler._();

  /// Handle an error and return a user-friendly message.
  static String handle(dynamic error) {
    AppLogger.error('Error caught', error: error);

    if (error is AppException) {
      return error.message;
    }

    // Firebase errors will be handled here when Firebase is connected
    // if (error is FirebaseAuthException) { ... }
    // if (error is FirebaseException) { ... }

    return 'An unexpected error occurred. Please try again.';
  }

  /// Handle error and execute callback.
  static Future<T?> guard<T>(Future<T> Function() action) async {
    try {
      return await action();
    } catch (error, stackTrace) {
      AppLogger.error('Guarded error', error: error, stackTrace: stackTrace);
      return null;
    }
  }
}
