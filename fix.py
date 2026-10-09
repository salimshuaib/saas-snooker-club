import re

with open('lib/core/services/table_alarm_service.dart', 'r') as f:
    content = f.read()

content = re.sub(r'bool get _isNativeAlarmSupported => .*?\n\s*bool get _isNativeAlarmSupported => .*?\n', 'bool get _isNativeAlarmSupported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);\n', content)

with open('lib/core/services/table_alarm_service.dart', 'w') as f:
    f.write(content)
