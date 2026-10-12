import re

file_path = 'lib/main_production.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("  // Register background handler\n  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);\n", "")

firebase_init_code = "  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);\n  AppLogger.info('Firebase initialized successfully');"
new_bg_handler_code = firebase_init_code + "\n\n  if (!kIsWeb) {\n    FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);\n  }"
content = content.replace(firebase_init_code, new_bg_handler_code)

content = content.replace("await pushService.initialize();", "pushService.setup();")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Patched main_production.dart")
