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
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:snooker_club/core/services/push_notification_service.dart';
import 'package:snooker_club/core/services/table_alarm_service.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message: ${message.messageId}');
}

/// Preview entry point.
/// Connects to real Firebase for READS, but all WRITES are blocked.
/// Use this to safely experiment with UI changes.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Set environment to PREVIEW — this blocks all write operations
  AppConfig.initialize(AppEnvironment.preview);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase (needed for reads and plugin compatibility)
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppLogger.info('Firebase initialized (PREVIEW mode - writes blocked)');

  // Initialize Push Notifications
  try {
    final pushService = PushNotificationService();
    await pushService.initialize();
  } catch (e) {
    AppLogger.error('Failed to initialize push notifications: $e');
  }

  // Initialize Table Alarms
  try {
    await TableAlarmService().initialize();
  } catch (e) {
    AppLogger.error('Failed to initialize table alarms: $e');
  }

  // Enable Firestore offline persistence
  final firestoreService = FirestoreService();
  await firestoreService.initialize();

  // Initialize local storage
  final localStorageService = LocalStorageService();
  await localStorageService.initialize();

  AppLogger.info('S&B Manager PREVIEW app starting...');

  runApp(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(localStorageService),
      ],
      child: const SnookerClubApp(),
    ),
  );
}
