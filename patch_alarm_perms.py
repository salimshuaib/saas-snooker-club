import re

file_path = 'lib/core/services/table_alarm_service.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

import_statement = "import 'package:permission_handler/permission_handler.dart';\n"
if "package:permission_handler" not in content:
    content = content.replace("import 'package:alarm/alarm.dart';", import_statement + "import 'package:alarm/alarm.dart';")

init_code = """    if (_isNativeAlarmSupported) {
      try {
        if (await Permission.scheduleExactAlarm.isDenied) {
          await Permission.scheduleExactAlarm.request();
        }
        if (await Permission.ignoreBatteryOptimizations.isDenied) {
          await Permission.ignoreBatteryOptimizations.request();
        }
      } catch (e) {
        AppLogger.error('Failed to request alarm permissions: $e');
      }

      _ringSubscription = Alarm.ringStream.stream.listen((alarmSettings) {"""

content = content.replace("""    if (_isNativeAlarmSupported) {
      _ringSubscription = Alarm.ringStream.stream.listen((alarmSettings) {""", init_code)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
