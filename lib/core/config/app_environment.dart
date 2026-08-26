import 'package:snooker_club/core/utils/logger.dart';

/// Defines the app build variant (Production vs Preview).
///
/// Production: Real Firebase data, full read/write access.
/// Preview: Same UI, real Firebase reads, all writes blocked.
enum AppEnvironment { production, preview }

/// Global app configuration that determines runtime behavior.
///
/// Call [AppConfig.initialize] early in `main()` before `runApp()`.
class AppConfig {
  AppConfig._();

  static AppEnvironment _environment = AppEnvironment.production;

  /// Initialize the app environment. Must be called before runApp().
  static void initialize(AppEnvironment env) => _environment = env;

  /// The current app environment.
  static AppEnvironment get environment => _environment;

  /// Whether this is the Preview build.
  static bool get isPreview => _environment == AppEnvironment.preview;

  /// Whether this is the Production build.
  static bool get isProduction => _environment == AppEnvironment.production;

  /// Guards a write operation in Preview mode.
  ///
  /// Returns `true` if the write was blocked (Preview mode).
  /// Returns `false` if the write should proceed (Production mode).
  ///
  /// Usage:
  /// ```dart
  /// Future<void> deleteGame(String id) async {
  ///   if (AppConfig.guardWrite('deleteGame')) return;
  ///   // ... real Firestore write ...
  /// }
  /// ```
  static bool guardWrite(String operation) {
    if (isPreview) {
      AppLogger.info('[PREVIEW] Write blocked: $operation');
      return true;
    }
    return false;
  }
}
