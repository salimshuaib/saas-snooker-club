import re

with open('lib/core/services/table_alarm_service.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace alarm package import with flutter_local_notifications
content = content.replace("import 'package:alarm/alarm.dart';", "import 'package:flutter_local_notifications/flutter_local_notifications.dart';\nimport 'package:timezone/timezone.dart' as tz;\nimport 'package:timezone/data/latest_all.dart' as tz;")

content = content.replace("final bool _isNativeAlarmSupported = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);", "final bool _isNativeAlarmSupported = !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);\n  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();")

init_old = """  Future<void> initialize() async {
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);

    if (_isNativeAlarmSupported) {
      _ringSubscription = Alarm.ringStream.stream.listen((alarmSettings) {
        final alarm = _activeAlarms.values.cast<AlarmInfo?>().firstWhere(
            (a) => a?.gameId.hashCode == alarmSettings.id, orElse: () => null);
        if (alarm != null) {
          _onAlarmFired(alarm);
        } else {
          // If the alarm is not in our active list but rang, stop it
          Alarm.stop(alarmSettings.id);
        }
      });
    }
    
    await _loadPersistedAlarms();
  }"""

init_new = """  Future<void> initialize() async {
    tz.initializeTimeZones();
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);

    if (_isNativeAlarmSupported) {
      const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
        'table_alarm_channel',
        'Table Alarms',
        description: 'Loud alarm notifications when table time is over',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('table_alarm'),
      );
      final androidPlugin = _localNotifications.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await androidPlugin?.createNotificationChannel(alarmChannel);
      await androidPlugin?.requestExactAlarmsPermission();

      const initializationSettings = InitializationSettings(
        android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        iOS: DarwinInitializationSettings(),
      );

      await _localNotifications.initialize(
        initializationSettings,
        onDidReceiveNotificationResponse: (details) {
          if (details.payload != null) {
            try {
              final alarm = AlarmInfo.fromJson(jsonDecode(details.payload!));
              _onAlarmFired(alarm);
            } catch (e) {
              AppLogger.error('Failed to parse alarm payload: $e');
            }
          }
        },
      );
    }
    
    await _loadPersistedAlarms();
  }"""

content = content.replace(init_old, init_new)

load_old = """           if (_isNativeAlarmSupported) await Alarm.stop(alarm.gameId.hashCode);"""
load_new = """           if (_isNativeAlarmSupported) await _localNotifications.cancel(alarm.gameId.hashCode);"""
content = content.replace(load_old, load_new)

set_old = """    if (_isNativeAlarmSupported) {
      final alarmSettings = AlarmSettings(
        id: gameId.hashCode,
        dateTime: fireAt,
        assetAudioPath: 'assets/sounds/alarm-sren.mp3',
        loopAudio: true,
        vibrate: true,
        volumeSettings: VolumeSettings.fade(
          volume: 1.0,
          fadeDuration: const Duration(seconds: 3),
        ),
        notificationSettings: NotificationSettings(
          title: tableName,
          body: 'Time Over!',
          stopButton: 'Stop',
        ),
      );
      
      try {
        await Alarm.set(alarmSettings: alarmSettings);
      } catch (e) {
        AppLogger.error('Failed to schedule exact alarm: $e');
      }
    } else {"""
set_new = """    if (_isNativeAlarmSupported) {
      final androidDetails = AndroidNotificationDetails(
        'table_alarm_channel',
        'Table Alarms',
        channelDescription: 'Loud alarm notifications when table time is over',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('table_alarm'),
        additionalFlags: Int32List.fromList(<int>[4]), // FLAG_INSISTENT for continuous loop
      );
      
      try {
        await _localNotifications.zonedSchedule(
          gameId.hashCode,
          tableName,
          'Time Over!',
          tz.TZDateTime.from(fireAt, tz.local),
          NotificationDetails(android: androidDetails),
          androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
          uiLocalNotificationDateInterpretation:
              UILocalNotificationDateInterpretation.absoluteTime,
          payload: jsonEncode(alarm.toJson()),
        );
      } catch (e) {
        AppLogger.error('Failed to schedule exact alarm: $e');
      }
      
      // Also set fallback timer in case app is open, so we get the internal UI overlay
      final duration = fireAt.difference(DateTime.now());
      _fallbackTimers[gameId] = Timer(duration.isNegative ? Duration.zero : duration, () {
        final active = _activeAlarms[gameId];
        if (active != null) {
          _onAlarmFired(active);
        }
      });
    } else {"""
content = content.replace(set_old, set_new)

cancel_old1 = """      if (_isNativeAlarmSupported) {
        await Alarm.stop(gameId.hashCode);
      }"""
cancel_new1 = """      if (_isNativeAlarmSupported) {
        await _localNotifications.cancel(gameId.hashCode);
      }"""
content = content.replace(cancel_old1, cancel_new1)

cancel_old2 = """      if (_isNativeAlarmSupported && _currentlyRingingId != null) {
        await Alarm.stop(_currentlyRingingId!);
        _currentlyRingingId = null;
      }
      
      if (_isNativeAlarmSupported) {
        try {
           final hasAlarm = await Alarm.hasAlarm();
           if (hasAlarm) {
               await Alarm.stopAll();
           }
        } catch (_) {}
      }"""
cancel_new2 = """      if (_isNativeAlarmSupported && _currentlyRingingId != null) {
        await _localNotifications.cancel(_currentlyRingingId!);
        _currentlyRingingId = null;
      }
      
      if (_isNativeAlarmSupported) {
        try {
           await _localNotifications.cancelAll();
        } catch (_) {}
      }"""
content = content.replace(cancel_old2, cancel_new2)

content = content.replace("StreamSubscription<AlarmSettings>? _ringSubscription;", "")
content = content.replace("import 'dart:typed_data';", "")
content = "import 'dart:typed_data';\n" + content

with open('lib/core/services/table_alarm_service.dart', 'w', encoding='utf-8') as f:
    f.write(content)
print('Done parsing')
