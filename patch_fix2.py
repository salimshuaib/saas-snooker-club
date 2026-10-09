import re

with open('lib/core/services/table_alarm_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("uiLocalNotificationDateInterpretation:\n              UILocalNotificationDateInterpretation.absoluteTime,", "")
content = content.replace("uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,", "")

with open('lib/core/services/table_alarm_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
