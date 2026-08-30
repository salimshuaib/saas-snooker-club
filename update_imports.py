import os
path = 'lib/main_production.dart'
with open(path, 'r', encoding='utf-8') as f:
    c = f.read()

c = c.replace(
    "import 'package:snooker_club/firebase_options.dart';",
    "import 'package:snooker_club/firebase_options.dart';\nimport 'package:firebase_crashlytics/firebase_crashlytics.dart';\nimport 'dart:ui';"
)

with open(path, 'w', encoding='utf-8') as f:
    f.write(c)
