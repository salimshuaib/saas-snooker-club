import os

filepath = 'lib/features/games/presentation/screens/bill_details_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import_stmt; // placeholder just to make sure we have route names", "")

if "import 'package:go_router/go_router.dart';" not in content:
    content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\nimport 'package:go_router/go_router.dart';\nimport 'package:snooker_club/core/routes/route_names.dart';")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)
