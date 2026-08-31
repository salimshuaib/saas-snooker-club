import os
path = 'lib/main_production.dart'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

import_statement = "import 'package:firebase_crashlytics/firebase_crashlytics.dart';\nimport 'dart:ui';"

init_code = """
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  AppLogger.info('Firebase initialized successfully');

  // Initialize Crashlytics
  FlutterError.onError = (errorDetails) {
    FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
  };
  // Pass all uncaught asynchronous errors that aren't handled by the Flutter framework to Crashlytics
  PlatformDispatcher.instance.onError = (error, stack) {
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    return true;
  };
"""

c = c.replace("import 'package:firebase_options.dart';", "import 'package:snooker_club/firebase_options.dart';\n" + import_statement)

c = c.replace("""
  // Initialize Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  AppLogger.info('Firebase initialized successfully');
""", init_code)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
