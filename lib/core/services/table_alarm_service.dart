import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:just_audio/just_audio.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;
import 'package:snooker_club/core/utils/logger.dart';

class AlarmInfo {
  final String gameId;
  final String tableName;
  final DateTime fireAt;

  AlarmInfo({
    required this.gameId,
    required this.tableName,
    required this.fireAt,
  });

  Map<String, dynamic> toJson() => {
        'gameId': gameId,
        'tableName': tableName,
        'fireAt': fireAt.toIso8601String(),
      };

  factory AlarmInfo.fromJson(Map<String, dynamic> json) => AlarmInfo(
        gameId: json['gameId'],
        tableName: json['tableName'],
        fireAt: DateTime.parse(json['fireAt']),
      );
}

class TableAlarmService {
  static final TableAlarmService _instance = TableAlarmService._internal();
  factory TableAlarmService() => _instance;
  TableAlarmService._internal();

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();
  
  final Map<String, AlarmInfo> _activeAlarms = {};
  final Map<String, Timer> _activeTimers = {};
  
  final _alarmFiredController = StreamController<AlarmInfo>.broadcast();
  Stream<AlarmInfo> get onAlarmFired => _alarmFiredController.stream;

  final _alarmsChangedController = StreamController<void>.broadcast();
  Stream<void> get onAlarmsChanged => _alarmsChangedController.stream;

  AudioPlayer? _audioPlayer;

  Future<void> initialize() async {
    tz.initializeTimeZones();
    _audioPlayer = AudioPlayer();

    if (!kIsWeb) {
      const AndroidNotificationChannel alarmChannel = AndroidNotificationChannel(
        'table_alarm_channel',
        'Table Alarms',
        description: 'Loud alarm notifications when table time is over',
        importance: Importance.max,
        playSound: true,
        sound: RawResourceAndroidNotificationSound('table_alarm'),
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(alarmChannel);
    }

    await _loadAlarms();
  }

  Future<void> _loadAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsJson = prefs.getString('active_alarms');
    if (alarmsJson != null) {
      final Map<String, dynamic> decoded = jsonDecode(alarmsJson);
      final now = DateTime.now();

      decoded.forEach((key, value) {
        final alarm = AlarmInfo.fromJson(value);
        if (alarm.fireAt.isBefore(now)) {
          if (now.difference(alarm.fireAt).inHours < 1) {
             _onAlarmFired(alarm);
          } else {
            _activeAlarms.remove(key);
          }
        } else {
          _activeAlarms[key] = alarm;
          _scheduleInMemoryTimer(alarm);
        }
      });
      _saveAlarms();
      _alarmsChangedController.add(null);
    }
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final mapped = _activeAlarms.map((key, value) => MapEntry(key, value.toJson()));
    await prefs.setString('active_alarms', jsonEncode(mapped));
  }

  int _generateId(String gameId) {
    return gameId.hashCode.abs();
  }

  Future<void> setAlarm({
    required String gameId,
    required String tableName,
    required int durationMinutes,
  }) async {
    final fireAt = DateTime.now().add(Duration(minutes: durationMinutes));
    final alarm = AlarmInfo(gameId: gameId, tableName: tableName, fireAt: fireAt);
    
    await cancelAlarm(gameId);

    _activeAlarms[gameId] = alarm;
    await _saveAlarms();
    _alarmsChangedController.add(null);

    if (!kIsWeb) {
      final notificationId = _generateId(gameId);
      
      const androidDetails = AndroidNotificationDetails(
        'table_alarm_channel',
        'Table Alarms',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        sound: RawResourceAndroidNotificationSound('table_alarm'),
      );
      
      await _localNotifications.zonedSchedule(
        notificationId,
        tableName,
        'Time Over!',
        tz.TZDateTime.from(fireAt, tz.local),
        const NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        uiLocalNotificationDateInterpretation:
            UILocalNotificationDateInterpretation.absoluteTime,
        payload: jsonEncode(alarm.toJson()),
      );
    }

    _scheduleInMemoryTimer(alarm);
  }

  void _scheduleInMemoryTimer(AlarmInfo alarm) {
    _activeTimers[alarm.gameId]?.cancel();
    
    final duration = alarm.fireAt.difference(DateTime.now());
    if (duration.isNegative) return;

    _activeTimers[alarm.gameId] = Timer(duration, () {
      _onAlarmFired(alarm);
    });
  }

  Future<void> cancelAlarm(String gameId) async {
    if (_activeAlarms.containsKey(gameId)) {
      _activeAlarms.remove(gameId);
      await _saveAlarms();
      _alarmsChangedController.add(null);
    }
    
    _activeTimers[gameId]?.cancel();
    _activeTimers.remove(gameId);

    if (!kIsWeb) {
      final notificationId = _generateId(gameId);
      await _localNotifications.cancel(notificationId);
    }
  }

  Future<void> _onAlarmFired(AlarmInfo alarm) async {
    AppLogger.info('Alarm fired for ${alarm.tableName}');
    _activeAlarms.remove(alarm.gameId);
    _activeTimers.remove(alarm.gameId);
    await _saveAlarms();
    _alarmsChangedController.add(null);

    _alarmFiredController.add(alarm);

    try {
      if (_audioPlayer != null) {
        await _audioPlayer!.setAsset('assets/sounds/table_alarm.wav');
        await _audioPlayer!.setLoopMode(LoopMode.one);
        await _audioPlayer!.play();
        
        Timer(const Duration(seconds: 60), () {
          _audioPlayer?.stop();
        });
      }
    } catch (e) {
      AppLogger.error('Failed to play alarm audio: $e');
    }
  }

  Future<void> dismissAlarm() async {
    try {
      await _audioPlayer?.stop();
    } catch (e) {
      AppLogger.error('Failed to stop audio: $e');
    }
  }

  AlarmInfo? getAlarmInfo(String gameId) {
    return _activeAlarms[gameId];
  }
}
