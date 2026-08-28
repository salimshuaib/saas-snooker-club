import re

path = r'C:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\presentation\screens\table_details_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''import 'package:snooker_club/features/settings/providers/settings_providers.dart';'''
replacement = '''import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_club/core/routes/app_router.dart';'''

content = content.replace(target, replacement)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
