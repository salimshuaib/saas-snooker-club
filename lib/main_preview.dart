import 'dart:async';
import 'dart:ui';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
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
import 'package:snooker_club/features/games/domain/config/tables_config.dart';
import 'package:snooker_club/firebase_options_preview.dart';

/// Preview entry point.
/// Connects to a separate staging Firebase project.
/// Safe to read and write without affecting production data.
void main() {
  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Use production environment flag so writes aren't blocked by guardWrite
      AppConfig.initialize(AppEnvironment.production);

      // Set preferred orientations
      await SystemChrome.setPreferredOrientations([
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);

      // Initialize Firebase with the PREVIEW staging project
      await Firebase.initializeApp(
        options: DefaultFirebaseOptionsPreview.currentPlatform,
      );
      AppLogger.info('Firebase initialized (STAGING/PREVIEW mode)');

      // --- TEMPORARY PREVIEW CLUB SETUP ---
      FirebaseAuth.instance.authStateChanges().listen((user) async {
        if (user != null) {
          final db = FirebaseFirestore.instance;
          final clubId = 'preview_club_1';
          
          AppLogger.info('Setting up Preview Club for ${user.email}...');
          
          // 1. Create a dummy club
          await db.collection('clubs').doc(clubId).set({
            'name': 'Staging Club',
            'createdAt': FieldValue.serverTimestamp(),
            'isActive': true,
            'subscriptionEndDate': Timestamp.fromDate(DateTime.now().add(const Duration(days: 365))),
          }, SetOptions(merge: true));

          // 2. Link this user to the club
          await db.collection('user_clubs').doc(user.uid).set({
            'clubId': clubId,
            'role': 'owner',
          }, SetOptions(merge: true));
          
          // 3. Create the staff record
          await db.collection('clubs').doc(clubId).collection('team_members').doc(user.uid).set({
            'name': 'Admin User',
            'email': user.email,
            'role': 'owner',
            'status': 'active',
          }, SetOptions(merge: true));

          // 4. Seed default tables if they don't exist
          final tablesRef = db.collection('clubs').doc(clubId).collection('tables');
          final tablesSnapshot = await tablesRef.limit(1).get();
          if (tablesSnapshot.docs.isEmpty) {
            AppLogger.info('Seeding default tables for preview club...');
            for (final table in TablesConfig.defaultTables) {
              await tablesRef.doc(table.id).set(table.toMap());
            }
          }

          AppLogger.info('SUCCESS: Preview Club configured successfully!');
        }
      });
      // --- END TEMPORARY PREVIEW CLUB SETUP ---

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
