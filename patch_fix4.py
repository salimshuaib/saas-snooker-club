import re

with open('lib/core/services/table_alarm_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("cancel(alarm.gameId.hashCode)", "cancel(id: alarm.gameId.hashCode)")
content = content.replace("cancel(gameId.hashCode)", "cancel(id: gameId.hashCode)")
content = content.replace("cancel(_currentlyRingingId!)", "cancel(id: _currentlyRingingId!)")

zoned_old = """        await _localNotifications.zonedSchedule(
          gameId.hashCode,
          tableName,
          'Time Over!',
          tz.TZDateTime.from(fireAt, tz.local),
          NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: jsonEncode(alarm.toJson()),
        );"""

zoned_new = """        await _localNotifications.zonedSchedule(
          id: gameId.hashCode,
          title: tableName,
          body: 'Time Over!',
          scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
          notificationDetails: NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          payload: jsonEncode(alarm.toJson()),
        );"""
content = content.replace(zoned_old, zoned_new)

init_old = """      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {"""
init_new = """      await _localNotifications.initialize(
        initializationSettings: initializationSettings,
        onDidReceiveNotificationResponse: (details) {"""
content = content.replace(init_old, init_new)

with open('lib/core/services/table_alarm_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print("Done")
