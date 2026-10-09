import re

with open('lib/core/services/table_alarm_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# I will just use regex to replace zonedSchedule
zoned_pattern = re.compile(r"await _localNotifications\.zonedSchedule\(\s*gameId\.hashCode,\s*tableName,\s*'Time Over!',\s*tz\.TZDateTime\.from\(fireAt,\s*tz\.local\),\s*NotificationDetails\(android:\s*androidDetails\),\s*androidScheduleMode:\s*AndroidScheduleMode\.exactAllowWhileIdle,\s*payload:\s*jsonEncode\(alarm\.toJson\(\)\),\s*\);", re.MULTILINE)

zoned_new = """await _localNotifications.zonedSchedule(
          id: gameId.hashCode,
          title: tableName,
          body: 'Time Over!',
          scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
          notificationDetails: NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: jsonEncode(alarm.toJson()),
        );"""

content = zoned_pattern.sub(zoned_new, content)

with open('lib/core/services/table_alarm_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
