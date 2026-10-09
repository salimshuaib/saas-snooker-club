import re

file_path = 'lib/core/services/table_alarm_service.dart'

with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("import 'package:flutter_local_notifications/flutter_local_notifications.dart';", "import 'package:flutter_local_notifications/flutter_local_notifications.dart';\nimport 'package:permission_handler/permission_handler.dart';")

content = content.replace("'table_alarm_channel',", "'table_alarm_channel_v2',")

init_content = """    if (_isNativeAlarmSupported) {
      const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
"""
new_init_content = """    if (_isNativeAlarmSupported) {
      // Request battery optimization ignore for background reliability
      try {
        await Permission.ignoreBatteryOptimizations.request();
      } catch (e) {
        AppLogger.error('Failed to request battery optimization ignore: $e');
      }

      const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
"""
content = content.replace(init_content, new_init_content)

with open(file_path, 'w', encoding='utf-8') as f:
    f.write(content)

print("Done")
