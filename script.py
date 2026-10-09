import re

with open('lib/core/services/table_alarm_service.dart', 'r') as f:
    content = f.read()

content = content.replace('!kIsWeb', '_isNativeAlarmSupported')
content = content.replace('kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)', '!_isNativeAlarmSupported')
content = content.replace('class TableAlarmService {', 'class TableAlarmService {\n  bool get _isNativeAlarmSupported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);')

with open('lib/core/services/table_alarm_service.dart', 'w') as f:
    f.write(content)
