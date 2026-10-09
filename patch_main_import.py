import re

file_path = 'lib/main_production.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

if "import 'package:alarm/alarm.dart';" not in content:
    content = content.replace("import 'package:snooker_club/core/services/table_alarm_service.dart';", "import 'package:snooker_club/core/services/table_alarm_service.dart';\nimport 'package:alarm/alarm.dart';")

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
