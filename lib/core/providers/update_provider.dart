import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/utils/version_parser.dart';
import 'package:snooker_club/core/utils/debug_logger.dart';
import 'package:snooker_club/features/settings/domain/models/app_config.dart';

/// Represents the state of the app update mechanism.
class UpdateState {
  final bool isForceUpdateRequired;
  final bool isOptionalUpdateAvailable;
  final String updateUrl;
  final String updateMessage;
  final String currentVersion;
  final String latestVersion;

  const UpdateState({
    required this.isForceUpdateRequired,
    required this.isOptionalUpdateAvailable,
    required this.updateUrl,
    required this.updateMessage,
    required this.currentVersion,
    required this.latestVersion,
  });

  factory UpdateState.initial() {
    return const UpdateState(
      isForceUpdateRequired: false,
      isOptionalUpdateAvailable: false,
      updateUrl: '',
      updateMessage: '',
      currentVersion: '',
      latestVersion: '',
    );
  }
}

/// Provides the current package info (app version).
final packageInfoProvider = FutureProvider<PackageInfo>((ref) async {
  return await PackageInfo.fromPlatform();
});

/// Streams the AppVersionConfig from Firestore.
final appVersionConfigProvider = StreamProvider<AppVersionConfig>((ref) {
  final firestore = ref.watch(firestoreServiceProvider).db;
  return firestore.collection('settings').doc('app_config').snapshots().map((
    snapshot,
  ) {
    if (!snapshot.exists || snapshot.data() == null) {
      return AppVersionConfig(
        minimumRequiredVersion: '0.0.0',
        latestVersion: '0.0.0',
        forceUpdate: false,
        updateUrl: '',
        updateMessage: 'Please update the app.',
      );
    }
    return AppVersionConfig.fromMap(snapshot.data()!);
  });
});

/// Evaluates if an update is required by comparing the local version and remote config.
final updateStateProvider = Provider<UpdateState>((ref) {
  if (kIsWeb) {
    return UpdateState.initial();
  }

  final packageInfoAsync = ref.watch(packageInfoProvider);
  final configAsync = ref.watch(appVersionConfigProvider);

  // If either is still loading or has an error, we do not force an update yet.
  if (packageInfoAsync.isLoading ||
      configAsync.isLoading ||
      packageInfoAsync.hasError ||
      configAsync.hasError) {
    logToFirestore(
      'Initial state: pkgLoad=${packageInfoAsync.isLoading}, cfgLoad=${configAsync.isLoading}, pkgErr=${packageInfoAsync.hasError}, cfgErr=${configAsync.hasError}',
    );
    return UpdateState.initial();
  }

  final currentVersion = packageInfoAsync.value!.version;
  final config = configAsync.value!;

  final isBelowMinimum = VersionParser.isLower(
    currentVersion,
    config.minimumRequiredVersion,
  );
  final isBelowLatest = VersionParser.isLower(
    currentVersion,
    config.latestVersion,
  );

  // If force_update is manually toggled true globally in Firestore, block everyone unless they are on the very latest version.
  final isForceUpdateRequired =
      isBelowMinimum || (config.forceUpdate && isBelowLatest);

  logToFirestore(
    'Evaluated state: cur=$currentVersion, min=${config.minimumRequiredVersion}, latest=${config.latestVersion}, forceUpdate=${config.forceUpdate} -> req=$isForceUpdateRequired',
  );

  return UpdateState(
    isForceUpdateRequired: isForceUpdateRequired,
    isOptionalUpdateAvailable: !isForceUpdateRequired && isBelowLatest,
    updateUrl: config.updateUrl,
    updateMessage: config.updateMessage,
    currentVersion: currentVersion,
    latestVersion: config.latestVersion,
  );
});
