import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

import 'package:snooker_club/core/utils/logger.dart';
import 'package:snooker_club/core/routes/app_router.dart';
import 'package:snooker_club/features/games/presentation/widgets/alarm_overlay.dart';

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

  factory AlarmInfo.fromJson(Map<String, dynamic> json) {
    return AlarmInfo(
      gameId: json['gameId'],
      tableName: json['tableName'],
      fireAt: DateTime.parse(json['fireAt']),
    );
  }
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

  final FlutterTts _flutterTts = FlutterTts();
  Timer? _ttsLoopTimer;

  Future<void> initialize() async {
    tz.initializeTimeZones();
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);

    if (!kIsWeb) {
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
        settings: initializationSettings,
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
  }

  Future<void> _loadPersistedAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsList = prefs.getStringList('active_table_alarms') ?? [];

    final now = DateTime.now();

    for (final alarmStr in alarmsList) {
      try {
        final alarm = AlarmInfo.fromJson(jsonDecode(alarmStr));
        if (alarm.fireAt.isAfter(now)) {
          _activeAlarms[alarm.gameId] = alarm;
          _scheduleInMemoryTimer(alarm);
        }
      } catch (e) {
        AppLogger.error('Failed to parse persisted alarm: $e');
      }
    }
    _alarmsChangedController.add(null);
  }

  Future<void> _saveAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsList =
        _activeAlarms.values.map((a) => jsonEncode(a.toJson())).toList();
    await prefs.setStringList('active_table_alarms', alarmsList);
    _alarmsChangedController.add(null);
  }

  Future<void> setAlarm({
    required String gameId,
    required String tableName,
    required int durationMinutes,
  }) async {
    cancelAlarm(gameId); // cancel existing

    final fireAt = DateTime.now().add(Duration(minutes: durationMinutes));
    final alarm = AlarmInfo(gameId: gameId, tableName: tableName, fireAt: fireAt);

    _activeAlarms[gameId] = alarm;
    _scheduleInMemoryTimer(alarm);
    await _saveAlarms();

    if (!kIsWeb) {
      final androidDetails = AndroidNotificationDetails(
        'table_alarm_channel',
        'Table Alarms',
        channelDescription: 'Loud alarm notifications when table time is over',
        importance: Importance.max,
        priority: Priority.max,
        fullScreenIntent: true,
        playSound: true,
        sound: const RawResourceAndroidNotificationSound('table_alarm'),
      );

      final notificationId = gameId.hashCode;
      await _localNotifications.zonedSchedule(
        id: notificationId,
        title: tableName,
        body: 'Time Over!',
        scheduledDate: tz.TZDateTime.from(fireAt, tz.local),
        notificationDetails: NotificationDetails(android: androidDetails),
        androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
        payload: jsonEncode(alarm.toJson()),
      );
    }
  }

  void _scheduleInMemoryTimer(AlarmInfo alarm) {
    final delay = alarm.fireAt.difference(DateTime.now());
    _activeTimers[alarm.gameId] = Timer(delay, () {
      _onAlarmFired(alarm);
    });
  }

  Future<void> cancelAlarm(String gameId) async {
    if (_activeAlarms.containsKey(gameId)) {
      _activeAlarms.remove(gameId);
      _activeTimers[gameId]?.cancel();
      _activeTimers.remove(gameId);
      await _saveAlarms();

      if (!kIsWeb) {
        final notificationId = gameId.hashCode;
        await _localNotifications.cancel(id: notificationId);
      }
    }
  }

  void _onAlarmFired(AlarmInfo alarm) {
    _activeAlarms.remove(alarm.gameId);
    _activeTimers.remove(alarm.gameId);
    _saveAlarms();
    _alarmFiredController.add(alarm);

    if (rootNavigatorKey.currentContext != null) {
      AlarmOverlay.show(rootNavigatorKey.currentContext!, alarm);
    }

    try {
      // Configure TTS for maximum clarity
      await _flutterTts.setLanguage("en-IN");
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      final textToSpeak = '${alarm.tableName} time over';
      
      // Wait for the loud background alarm to finish playing before speaking
      await Future.delayed(const Duration(seconds: 4));
      
      await _flutterTts.speak(textToSpeak);
      
      int speakCount = 0;
      _ttsLoopTimer?.cancel();
      _ttsLoopTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        speakCount++;
        if (speakCount > 15) {
          timer.cancel();
          return;
        }
        await _flutterTts.speak(textToSpeak);
      });
    } catch (e) {
      AppLogger.error('Failed to play alarm TTS: $e');
    }
  }

  Future<void> dismissAlarm() async {
    try {
      _ttsLoopTimer?.cancel();
      await _flutterTts.stop();
    } catch (e) {
      AppLogger.error('Failed to stop TTS: $e');
    }
  }

  AlarmInfo? getAlarmInfo(String gameId) {
    return _activeAlarms[gameId];
  }
}
