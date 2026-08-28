import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snooker_club/core/config/app_environment.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:snooker_club/core/constants/firebase_constants.dart';
import 'package:snooker_club/core/services/firestore_service.dart';
import 'package:snooker_club/core/utils/logger.dart';
import 'package:snooker_club/features/settings/domain/models/settings_models.dart';

class SettingsRepository {
  final FirestoreService _firestoreService;
  final String? clubId;
  static const String _docId = 'club_config';
  static const String _localPrefsKey = 'cached_app_settings';

  SettingsRepository(this._firestoreService, {this.clubId});

  FirebaseFirestore get _db => _firestoreService.db;

  DocumentReference get _settingsDoc {
    if (clubId == null) throw Exception('clubId cannot be null for SettingsRepository');
    return _db.collection(FirebaseConstants.clubsCollection).doc(clubId).collection(FirebaseConstants.settingsCollection).doc(_docId);
  }

  /// Watch live settings updates from Firestore.
  Stream<AppSettings> watchSettings() {
    return _settingsDoc
        .snapshots()
        .map((snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            final settings = AppSettings.fromMap(snapshot.data()! as Map<String, dynamic>);
            _saveToLocalBackup(settings);
            return settings;
          }
          return const AppSettings();
        })
        .handleError((error) {
          if (error is FirebaseException && error.code == 'permission-denied') {
            AppLogger.info('Settings stream closed due to logout (permission-denied)');
          } else {
            AppLogger.error('Error streaming settings from Firestore: $error');
          }
        });
  }

  /// Fetch current settings (from server or cache).
  Future<AppSettings> getSettings({bool forceServer = false}) async {
    try {
      final snapshot = await _settingsDoc
          .get(forceServer ? const GetOptions(source: Source.server) : null);
      if (snapshot.exists && snapshot.data() != null) {
        final settings = AppSettings.fromMap(snapshot.data()! as Map<String, dynamic>);
        await _saveToLocalBackup(settings);
        return settings;
      }
    } catch (e) {
      AppLogger.warning('Could not load settings from Firestore: $e. Falling back to local cache.');
    }
    return _loadFromLocalBackup();
  }

  /// Save settings to Firestore and local cache.
  Future<void> saveSettings(AppSettings settings) async {
    if (AppConfig.guardWrite('SettingsRepository.saveSettings')) return;
    final toSave = settings.copyWith(lastSyncTime: DateTime.now());
    try {
      await _settingsDoc
          .set(toSave.toMap(), SetOptions(merge: true));
      AppLogger.info('Settings synced to Firestore successfully.');
      await _saveToLocalBackup(toSave);
    } catch (e) {
      AppLogger.error('Failed to sync settings to Firestore: $e.');
      rethrow;
    }
  }

  /// Force a manual sync with Firebase.
  Future<AppSettings> forceSync() async {
    final settings = await getSettings(forceServer: true);
    await saveSettings(settings);
    return settings;
  }

  /// Clear local offline cached data without affecting cloud data.
  Future<void> clearLocalCache() async {
    if (AppConfig.guardWrite('SettingsRepository.clearLocalCache')) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_localPrefsKey);
      await _db.clearPersistence();
      AppLogger.info('Local persistence and cache cleared successfully.');
    } catch (e) {
      AppLogger.warning('Error clearing local cache: $e');
    }
  }

  Future<void> _saveToLocalBackup(AppSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_localPrefsKey, jsonEncode(settings.toMap()));
    } catch (e) {
      AppLogger.warning('Failed to save settings to local storage: $e');
    }
  }

  Future<AppSettings> _loadFromLocalBackup() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final jsonStr = prefs.getString(_localPrefsKey);
      if (jsonStr != null) {
        final map = jsonDecode(jsonStr) as Map<String, dynamic>;
        return AppSettings.fromMap(map);
      }
    } catch (e) {
      AppLogger.error('Failed to load settings from local storage: $e');
    }
    return const AppSettings();
  }
  Future<void> migrateTablesPricing() async {}
}
