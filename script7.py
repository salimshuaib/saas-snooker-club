import sys

with open('lib/core/routes/app_router.dart', 'r', encoding='utf-8') as f:
    text = f.read()

imports = '''import 'package:snooker_club/features/games/presentation/screens/game_activity_screen.dart';'''
if 'game_activity_screen.dart' not in text:
    text = text.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + imports)

old_route = '''              GoRoute(
                path: RouteNames.live,
                builder: (context, state) => const TickerMode(enabled: true, child: Scaffold(body: Center(child: Text('Live')))),
              ),'''

new_route = '''              GoRoute(
                path: RouteNames.live,
                builder: (context, state) => const TickerMode(enabled: true, child: GameActivityScreen()),
              ),'''
text = text.replace(old_route, new_route)

with open('lib/core/routes/app_router.dart', 'w', encoding='utf-8') as f:
    f.write(text)
