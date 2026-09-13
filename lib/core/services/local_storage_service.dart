import 'package:shared_preferences/shared_preferences.dart';
import 'package:snooker_club/core/utils/logger.dart';

/// Local storage service using SharedPreferences.
/// Used for persisting user preferences (theme, currency, etc.).
class LocalStorageService {
  static const String _themeKey = 'theme_mode';
  static const String _currencyKey = 'currency_code';
  static const String _isLoggedInKey = 'is_logged_in';

  late final SharedPreferences _prefs;

  /// Initialize the service.
  Future<void> initialize() async {
    _prefs = await SharedPreferences.getInstance();
    AppLogger.info('LocalStorageService initialized');
  }

  // ─── Theme ───
  String? getThemeMode() => _prefs.getString(_themeKey);
  Future<void> setThemeMode(String mode) => _prefs.setString(_themeKey, mode);

  // ─── Currency ───
  String? getCurrencyCode() => _prefs.getString(_currencyKey);
  Future<void> setCurrencyCode(String code) =>
      _prefs.setString(_currencyKey, code);

  // ─── Auth Session ───
  bool getIsLoggedIn() => _prefs.getBool(_isLoggedInKey) ?? false;
  Future<void> setIsLoggedIn(bool value) =>
      _prefs.setBool(_isLoggedInKey, value);

  // ─── Clear All ───
  Future<void> clear() => _prefs.clear();
}
