/// User-facing error message constants.
class ErrorMessages {
  ErrorMessages._();

  // Authentication
  static const String invalidCredentials = 'Invalid username or password';
  static const String sessionExpired = 'Your session has expired. Please login again.';
  static const String loginFailed = 'Login failed. Please try again.';

  // Network
  static const String noInternet = 'No internet connection. Please check your network.';
  static const String timeout = 'Request timed out. Please try again.';
  static const String serverError = 'Server error. Please try again later.';

  // General
  static const String unknownError = 'An unexpected error occurred. Please try again.';
  static const String operationFailed = 'Operation failed. Please try again.';
  static const String dataNotFound = 'Requested data not found.';

  // Firestore
  static const String saveFailed = 'Failed to save data. Please try again.';
  static const String loadFailed = 'Failed to load data. Please try again.';
  static const String deleteFailed = 'Failed to delete data. Please try again.';
}
