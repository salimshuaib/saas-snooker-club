import 'package:shared_preferences/shared_preferences.dart';
import 'package:snooker_club/core/utils/logger.dart';

/// Local storage service using SharedPreferences.
/// Used for persisting user preferences (theme, currency, etc.).
class LocalStorageService {
  static const String _themeKey = 'theme_mode';
  static const String _currencyKey = 'currency_code';
  static const String _isLoggedInKey = 'is_logged_in';

  // Printer settings keys
  static const String _printerMacKey = 'printer_mac_address';
  static const String _printerNameKey = 'printer_device_name';
  static const String _printerAutoPrintKey = 'printer_auto_print';
  static const String _printerCopiesKey = 'printer_copies_count';
  static const String _printerPaperWidthKey = 'printer_paper_width';

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

  // ─── Printer Settings ───
  String? getPrinterMac() => _prefs.getString(_printerMacKey);
  Future<void> setPrinterMac(String? mac) async =>
      mac == null ? _prefs.remove(_printerMacKey) : _prefs.setString(_printerMacKey, mac);

  String? getPrinterName() => _prefs.getString(_printerNameKey);
  Future<void> setPrinterName(String? name) async =>
      name == null ? _prefs.remove(_printerNameKey) : _prefs.setString(_printerNameKey, name);

  bool getAutoPrint() => _prefs.getBool(_printerAutoPrintKey) ?? false;
  Future<void> setAutoPrint(bool value) =>
      _prefs.setBool(_printerAutoPrintKey, value);

  int getPrintCopies() => _prefs.getInt(_printerCopiesKey) ?? 1;
  Future<void> setPrintCopies(int value) =>
      _prefs.setInt(_printerCopiesKey, value);

  String? getPaperWidth() => _prefs.getString(_printerPaperWidthKey);
  Future<void> setPaperWidth(String value) =>
      _prefs.setString(_printerPaperWidthKey, value);

  // ─── Clear All ───
  Future<void> clear() => _prefs.clear();
}
