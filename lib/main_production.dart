import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/app.dart';
import 'package:snooker_club/core/config/app_environment.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/services/firestore_service.dart';
import 'package:snooker_club/core/services/local_storage_service.dart';
import 'package:snooker_club/core/utils/logger.dart';
import 'package:snooker_club/firebase_options.dart';

/// Production entry point.
/// Connects to real Firebase with full read/write access.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Set environment to PRODUCTION
  AppConfig.initialize(AppEnvironment.production);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  AppLogger.info('Firebase initialized successfully');

  // Enable Firestore offline persistence
  final firestoreService = FirestoreService();
  await firestoreService.initialize();



  // Initialize local storage
  final localStorageService = LocalStorageService();
  await localStorageService.initialize();

  AppLogger.info('Sharma Billiards PRODUCTION app starting...');

  runApp(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(localStorageService),
      ],
      child: const SnookerClubApp(),
    ),
  );
}
