import os
path = 'android/app/build.gradle.kts'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace(
    'id("dev.flutter.flutter-gradle-plugin")\n    // Firebase: processes google-services.json\n    id("com.google.gms.google-services")',
    'id("dev.flutter.flutter-gradle-plugin")\n    // Firebase: processes google-services.json\n    id("com.google.gms.google-services")\n    id("com.google.firebase.crashlytics")'
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
