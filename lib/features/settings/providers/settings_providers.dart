import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/features/games/domain/config/pricing_config.dart';
import 'package:snooker_club/features/inventory/domain/models/inventory_models.dart';
import 'package:snooker_club/features/settings/data/settings_repository.dart';
import 'package:snooker_club/features/settings/domain/models/settings_models.dart';

import 'package:snooker_club/core/providers/club_scope_provider.dart';

final settingsRepositoryProvider = Provider<SettingsRepository>((ref) {
  final firestoreService = ref.watch(firestoreServiceProvider);
  final clubId = ref.watch(clubIdProvider);
  return SettingsRepository(firestoreService, clubId: clubId);
});

enum FirebaseSyncStatus {
  connected('Connected'),
  offline('Offline'),
  synchronizing('Synchronizing...');

  final String displayName;
  const FirebaseSyncStatus(this.displayName);
}

class FirebaseSyncStatusNotifier extends Notifier<FirebaseSyncStatus> {
  @override
  FirebaseSyncStatus build() => FirebaseSyncStatus.connected;

  void setStatus(FirebaseSyncStatus status) {
    state = status;
  }
}

final firebaseSyncStatusProvider =
    NotifierProvider<FirebaseSyncStatusNotifier, FirebaseSyncStatus>(
      FirebaseSyncStatusNotifier.new,
    );

final appSettingsProvider = NotifierProvider<AppSettingsNotifier, AppSettings>(
  AppSettingsNotifier.new,
);

class AppSettingsNotifier extends Notifier<AppSettings> {
  StreamSubscription<AppSettings>? _subscription;

  @override
  AppSettings build() {
    final repo = ref.watch(settingsRepositoryProvider);

    _subscription?.cancel();

    if (repo.clubId == null) {
      return const AppSettings();
    }

    // Subscribe to live settings stream from Firestore
    _subscription = repo.watchSettings().listen(
      (newSettings) {
        Future.microtask(() {
          state = newSettings;
          _updateStaticConfigs(newSettings);
          ref
              .read(firebaseSyncStatusProvider.notifier)
              .setStatus(FirebaseSyncStatus.connected);
        });
      },
      onError: (_) {
        Future.microtask(() {
          ref
              .read(firebaseSyncStatusProvider.notifier)
              .setStatus(FirebaseSyncStatus.offline);
        });
      },
    );

    ref.onDispose(() {
      _subscription?.cancel();
    });

    return const AppSettings();
  }

  void _updateStaticConfigs(AppSettings settings) {
    TablePricingConfig.updateFromSettings(settings);
    InventoryItem.lowStockThreshold = settings.inventory.lowStockThreshold;
    InventoryItem.defaultInitialQuantity =
        settings.inventory.defaultInitialQuantity;
    InventoryItem.enableLowStockAlerts =
        settings.inventory.enableLowStockAlerts;
  }

  Future<void> updateBusinessSettings(BusinessSettings business) async {
    await _save(state.copyWith(business: business));
  }

  Future<void> updateGameSettings(GameSettings game) async {
    await _save(state.copyWith(game: game));
  }

  Future<void> updatePricingSettings(PricingSettings pricing) async {
    await _save(state.copyWith(pricing: pricing));
  }

  Future<void> updateInventorySettings(InventorySettings inventory) async {
    await _save(state.copyWith(inventory: inventory));
  }

  Future<void> updateSecuritySettings(SecuritySettings security) async {
    await _save(state.copyWith(security: security));
  }

  Future<void> updateNotificationSettings(
    NotificationSettings notifications,
  ) async {
    await _save(state.copyWith(notifications: notifications));
  }

  Future<void> updateBookingSettings(BookingSettings booking) async {
    await _save(state.copyWith(booking: booking));
  }

  Future<void> updateBillingFeatures(BillingFeatures billingFeatures) async {
    await _save(state.copyWith(billingFeatures: billingFeatures));
  }

  Future<void> _save(AppSettings newSettings) async {
    state = newSettings;
    _updateStaticConfigs(newSettings);
    ref
        .read(firebaseSyncStatusProvider.notifier)
        .setStatus(FirebaseSyncStatus.synchronizing);
    try {
      await ref.read(settingsRepositoryProvider).saveSettings(newSettings);
      ref
          .read(firebaseSyncStatusProvider.notifier)
          .setStatus(FirebaseSyncStatus.connected);
    } catch (e) {
      ref
          .read(firebaseSyncStatusProvider.notifier)
          .setStatus(FirebaseSyncStatus.offline);
      rethrow;
    }
  }

  Future<void> forceManualSync() async {
    ref
        .read(firebaseSyncStatusProvider.notifier)
        .setStatus(FirebaseSyncStatus.synchronizing);
    try {
      final updated = await ref.read(settingsRepositoryProvider).forceSync();
      state = updated;
      _updateStaticConfigs(updated);
      ref
          .read(firebaseSyncStatusProvider.notifier)
          .setStatus(FirebaseSyncStatus.connected);
    } catch (e) {
      ref
          .read(firebaseSyncStatusProvider.notifier)
          .setStatus(FirebaseSyncStatus.offline);
      rethrow;
    }
  }

  Future<void> clearLocalCache() async {
    await ref.read(settingsRepositoryProvider).clearLocalCache();
  }
}

final clubFeatureProvider = Provider.family<bool, String>((ref, featureKey) {
  final settings = ref.watch(appSettingsProvider);
  switch (featureKey) {
    case 'raceEnabled':
      return settings.features.raceEnabled;
    case 'rummyEnabled':
      return settings.features.rummyEnabled;
    case 'inventoryEnabled':
      return settings.features.inventoryEnabled;
    case 'quickSalesEnabled':
      return settings.features.quickSalesEnabled;
    case 'creditEnabled':
      return settings.features.creditEnabled;
    case 'perMinuteEnabled':
      return settings.features.perMinuteEnabled;
    case 'perFrameEnabled':
      return settings.features.perFrameEnabled;
    default:
      return true;
  }
});
