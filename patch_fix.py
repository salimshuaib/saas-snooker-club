import re

with open('lib/core/services/table_alarm_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

getter = "bool get _isNativeAlarmSupported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);"
getter_new = "bool get _isNativeAlarmSupported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);\n  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();"

content = content.replace(getter, getter_new)

with open('lib/core/services/table_alarm_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
