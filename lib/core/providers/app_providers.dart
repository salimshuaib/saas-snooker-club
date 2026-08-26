import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/models/currency.dart';
import 'package:snooker_club/core/services/auth_service.dart';
import 'package:snooker_club/core/services/firestore_service.dart';
import 'package:snooker_club/core/services/local_storage_service.dart';
import 'package:snooker_club/core/services/storage_service.dart';

// ─── Services ───
final localStorageServiceProvider = Provider<LocalStorageService>((ref) {
  return LocalStorageService();
});

final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

final firestoreServiceProvider = Provider<FirestoreService>((ref) {
  return FirestoreService();
});

final storageServiceProvider = Provider<StorageService>((ref) {
  return StorageService();
});

// ─── Theme Mode ───
final themeModeProvider = NotifierProvider<ThemeModeNotifier, ThemeMode>(ThemeModeNotifier.new);

class ThemeModeNotifier extends Notifier<ThemeMode> {
  @override
  ThemeMode build() {
    final localStorage = ref.read(localStorageServiceProvider);
    final saved = localStorage.getThemeMode();
    if (saved != null) {
      return ThemeMode.values.firstWhere(
        (m) => m.name == saved,
        orElse: () => ThemeMode.dark,
      );
    }
    return ThemeMode.dark;
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    state = mode;
    await ref.read(localStorageServiceProvider).setThemeMode(mode.name);
  }

  Future<void> toggleTheme() async {
    final newMode = state == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    await setThemeMode(newMode);
  }
}

// ─── Currency ───
final currencyProvider = NotifierProvider<CurrencyNotifier, Currency>(CurrencyNotifier.new);

class CurrencyNotifier extends Notifier<Currency> {
  @override
  Currency build() {
    final localStorage = ref.read(localStorageServiceProvider);
    final savedCode = localStorage.getCurrencyCode();
    if (savedCode != null) {
      return Currency.fromCode(savedCode);
    }
    return Currency.defaultCurrency;
  }

  Future<void> setCurrency(Currency currency) async {
    state = currency;
    await ref.read(localStorageServiceProvider).setCurrencyCode(currency.code);
  }
}

// ─── Auth State ───
final isLoggedInProvider = NotifierProvider<AuthStateNotifier, bool>(AuthStateNotifier.new);

class AuthStateNotifier extends Notifier<bool> {
  @override
  bool build() {
    final localStorage = ref.read(localStorageServiceProvider);
    return localStorage.getIsLoggedIn();
  }

  Future<void> login(String username, String password) async {
    final authService = ref.read(authServiceProvider);
    await authService.login(username, password);
    state = true;
    await ref.read(localStorageServiceProvider).setIsLoggedIn(true);
  }

  Future<void> logout() async {
    final authService = ref.read(authServiceProvider);
    await authService.logout();
    state = false;
    await ref.read(localStorageServiceProvider).setIsLoggedIn(false);
  }
}

// --- Revenue Details Date Provider ---
/// Provider for the currently selected date on the Revenue Details screen.
final revenueDetailsDateProvider = NotifierProvider<RevenueDetailsDateNotifier, DateTime>(RevenueDetailsDateNotifier.new);

class RevenueDetailsDateNotifier extends Notifier<DateTime> {
  @override
  DateTime build() => DateTime.now();

  void setDate(DateTime date) {
    state = date;
  }
}

