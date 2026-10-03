import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
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
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:snooker_club/core/services/push_notification_service.dart';
import 'package:snooker_club/core/services/table_alarm_service.dart';
import 'dart:ui';
import 'package:alarm/alarm.dart';

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  print('Handling a background message: ${message.messageId}');
}

/// Production entry point.
/// Connects to real Firebase with full read/write access.
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize alarm package
  await Alarm.init();

  // Register background handler
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Set environment to PRODUCTION
  AppConfig.initialize(AppEnvironment.production);

  // Set preferred orientations
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Initialize Firebase
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  AppLogger.info('Firebase initialized successfully');

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

  // Debug: log persisted auth state
  final persistedUser = FirebaseAuth.instance.currentUser;
  AppLogger.info(
    'Persisted user at startup: ${persistedUser?.email ?? "NONE (not logged in)"}',
  );

  // Initialize Crashlytics
  if (!kIsWeb) {
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  // Enable Firestore offline persistence
  final firestoreService = FirestoreService();
  await firestoreService.initialize();

  // Initialize local storage
  final localStorageService = LocalStorageService();
  await localStorageService.initialize();

  AppLogger.info('S&B Manager PRODUCTION app starting...');


  runApp(
    ProviderScope(
      overrides: [
        localStorageServiceProvider.overrideWithValue(localStorageService),
      ],
      child: const SnookerClubApp(),
    ),
  );
}

