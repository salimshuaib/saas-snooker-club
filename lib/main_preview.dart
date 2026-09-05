import 'dart:async';
import 'dart:ui';
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

/// Preview entry point.
/// Connects to real Firebase for READS, but all WRITES are blocked.
/// Use this to safely experiment with UI changes.
void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Set environment to PREVIEW — this blocks all write operations
      AppConfig.initialize(AppEnvironment.preview);

      // Set preferred orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Initialize Firebase (needed for reads and plugin compatibility)
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
      AppLogger.info('Firebase initialized (PREVIEW mode - writes blocked)');

      // Enable Firestore offline persistence
      final firestoreService = FirestoreService();
      await firestoreService.initialize();

      // Initialize local storage
      final localStorageService = LocalStorageService();
      await localStorageService.initialize();

      AppLogger.info('S&B Manager PREVIEW app starting...');

      // Filter out harmless Flutter Web engine disposal assertions
      final originalOnError = FlutterError.onError;
      FlutterError.onError = (errorDetails) {
        final errorString = errorDetails.exceptionAsString();
        final stackString = errorDetails.stack?.toString() ?? '';
        if (errorString.contains('EngineFlutterView') || 
            errorString.contains('window.dart:99:12') ||
            stackString.contains('window.dart:99:12')) {
          return; // Silently ignore
        }
        if (originalOnError != null) {
          originalOnError(errorDetails);
        } else {
          FlutterError.presentError(errorDetails);
        }
      };

      final originalPlatformOnError = PlatformDispatcher.instance.onError;
      PlatformDispatcher.instance.onError = (error, stack) {
        final errorString = error.toString();
        final stackString = stack.toString();
        if (errorString.contains('EngineFlutterView') || 
            errorString.contains('window.dart:99:12') ||
            stackString.contains('window.dart:99:12')) {
          return true; // Handled (silently ignored)
        }
        if (originalPlatformOnError != null) {
          return originalPlatformOnError(error, stack);
        }
        return false;
      };

      runApp(
        ProviderScope(
          overrides: [
            localStorageServiceProvider.overrideWithValue(localStorageService),
          ],
          child: const SnookerClubApp(),
        ),
      );
    },
    (error, stack) {
      final errorString = error.toString();
      if (errorString.contains('EngineFlutterView') || 
          errorString.contains('window.dart:99:12')) {
        return;
      }
      debugPrint('Uncaught Error: $error');
    },
    zoneSpecification: ZoneSpecification(
      print: (self, parent, zone, line) {
        if (line.contains('EngineFlutterView') || 
            line.contains('window.dart:99:12') || 
            line.contains('isDisposed') ||
            line.contains('EXCEPTION CAUGHT BY SCHEDULER LIBRARY')) {
          return;
        }
        parent.print(zone, line);
      },
    ),
  );
}
