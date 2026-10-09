import 'dart:typed_data';
import 'dart:async';
import 'dart:convert';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz;
import 'package:flutter/foundation.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:audioplayers/audioplayers.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  bool get _isNativeAlarmSupported => !kIsWeb && (defaultTargetPlatform == TargetPlatform.android || defaultTargetPlatform == TargetPlatform.iOS);
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  static final TableAlarmService _instance = TableAlarmService._internal();
  factory TableAlarmService() => _instance;
  TableAlarmService._internal();

  final Map<String, AlarmInfo> _activeAlarms = {};
  final Map<String, Timer> _fallbackTimers = {};

  final _alarmFiredController = StreamController<AlarmInfo>.broadcast();
  Stream<AlarmInfo> get onAlarmFired => _alarmFiredController.stream;

  final _alarmsChangedController = StreamController<void>.broadcast();
  Stream<void> get onAlarmsChanged => _alarmsChangedController.stream;

  final List<AlarmInfo> ringingAlarms = [];
  final _ringingAlarmsController = StreamController<List<AlarmInfo>>.broadcast();
  Stream<List<AlarmInfo>> get onRingingAlarmsChanged => _ringingAlarmsController.stream;

  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _sirenPlayer = AudioPlayer();
  Timer? _ttsLoopTimer;
  
  int? _currentlyRingingId;

  Future<void> initialize() async {
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
  }

  Future<void> _loadPersistedAlarms() async {
    final prefs = await SharedPreferences.getInstance();
    final alarmsList = prefs.getStringList('active_table_alarms') ?? [];

    final now = DateTime.now();
    bool needsSave = false;

    for (final alarmStr in alarmsList) {
      try {
        final alarm = AlarmInfo.fromJson(jsonDecode(alarmStr));
        if (alarm.fireAt.isAfter(now)) {
          _activeAlarms[alarm.gameId] = alarm;
        } else {
           // Cleanup stale alarms
           needsSave = true;
           if (_isNativeAlarmSupported) await _localNotifications.cancel(alarm.gameId.hashCode);
        }
      } catch (e) {
        AppLogger.error('Failed to parse persisted alarm: $e');
      }
    }
    if (needsSave) {
      await _saveAlarms();
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
    required DateTime fireAt,
  }) async {
    await cancelAlarm(gameId); // cancel existing

    final alarm = AlarmInfo(gameId: gameId, tableName: tableName, fireAt: fireAt);

    _activeAlarms[gameId] = alarm;
    await _saveAlarms();

    if (_isNativeAlarmSupported) {
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
    } else {
      // Fallback timer only for Web/Desktop where the native alarm package is unavailable
      final duration = fireAt.difference(DateTime.now());
      _fallbackTimers[gameId] = Timer(duration.isNegative ? Duration.zero : duration, () {
        final active = _activeAlarms[gameId];
        if (active != null) {
          _onAlarmFired(active);
        }
      });
    }
  }

  Future<void> cancelAlarm(String gameId) async {
    _fallbackTimers[gameId]?.cancel();
    _fallbackTimers.remove(gameId);
    
    // Stop manual siren if it happens to be ringing for this game
    if (_currentlyRingingId == gameId.hashCode) {
      await _sirenPlayer.stop();
      _currentlyRingingId = null;
    }

    if (_activeAlarms.containsKey(gameId)) {
      _activeAlarms.remove(gameId);
      await _saveAlarms();

      if (_isNativeAlarmSupported) {
        await _localNotifications.cancel(gameId.hashCode);
      }
    }
    
    // Also remove from ringing queue if it's there
    if (ringingAlarms.any((a) => a.gameId == gameId)) {
       await dismissAlarmForGame(gameId);
    }
  }

  Future<void> _onAlarmFired(AlarmInfo alarm) async {
    // Guard: prevent double-fire if alarm was already handled
    if (!_activeAlarms.containsKey(alarm.gameId)) return;

    _fallbackTimers[alarm.gameId]?.cancel();
    _fallbackTimers.remove(alarm.gameId);

    _currentlyRingingId = alarm.gameId.hashCode;
    _activeAlarms.remove(alarm.gameId);
    _saveAlarms();
    _alarmFiredController.add(alarm);

    // Add to ringing queue if not already there
    if (!ringingAlarms.any((a) => a.gameId == alarm.gameId)) {
      ringingAlarms.add(alarm);
      _ringingAlarmsController.add(List.unmodifiable(ringingAlarms));
    }

    if (rootNavigatorKey.currentContext != null && ringingAlarms.length == 1) {
      // Only push the dialog if this is the FIRST alarm in the queue
      AlarmOverlay.show(rootNavigatorKey.currentContext!);
    }

    if (!_isNativeAlarmSupported) {
      try {
        await _sirenPlayer.setVolume(1.0);
        await _sirenPlayer.setReleaseMode(ReleaseMode.loop);
        await _sirenPlayer.play(AssetSource('sounds/table_alarm.wav'));
      } catch (e) {
        AppLogger.error('Failed to play manual siren: $e');
      }
    }

    try {
      await _flutterTts.setLanguage('en-IN');
      await _flutterTts.setSpeechRate(0.45);
      await _flutterTts.setPitch(1.0);
      await _flutterTts.setVolume(1.0);

      String getTtsText() {
         return ringingAlarms.length > 1 
           ? '${ringingAlarms.length} tables time over' 
           : '${ringingAlarms.first.tableName} time over';
      }

      await _flutterTts.speak(getTtsText());

      int speakCount = 0;
      _ttsLoopTimer?.cancel();
      _ttsLoopTimer = Timer.periodic(const Duration(seconds: 5), (timer) async {
        speakCount++;
        if (speakCount > 15 || ringingAlarms.isEmpty) {
          timer.cancel();
          return;
        }
        await _flutterTts.speak(getTtsText());
      });
    } catch (e) {
      AppLogger.error('Failed to play alarm TTS: $e');
    }
  }

  Future<void> dismissAllAlarms() async {
    try {
      ringingAlarms.clear();
      _ringingAlarmsController.add([]);

      _ttsLoopTimer?.cancel();
      await _flutterTts.stop();
      await _sirenPlayer.stop();
      
      if (_isNativeAlarmSupported && _currentlyRingingId != null) {
        await _localNotifications.cancel(_currentlyRingingId!);
        _currentlyRingingId = null;
      }
      
      if (_isNativeAlarmSupported) {
        try {
           await _localNotifications.cancelAll();
        } catch (_) {}
      }
    } catch (e) {
      AppLogger.error('Failed to dismiss alarms: $e');
    }
  }

  Future<void> dismissAlarmForGame(String gameId) async {
    try {
      ringingAlarms.removeWhere((a) => a.gameId == gameId);
      _ringingAlarmsController.add(List.unmodifiable(ringingAlarms));

      if (_isNativeAlarmSupported) {
        await _localNotifications.cancel(gameId.hashCode);
      }

      if (ringingAlarms.isEmpty) {
        // If no more ringing alarms, stop the global audio
        _ttsLoopTimer?.cancel();
        await _flutterTts.stop();
        await _sirenPlayer.stop();
      }
    } catch (e) {
      AppLogger.error('Failed to dismiss alarm for game $gameId: $e');
    }
  }

  AlarmInfo? getAlarmInfo(String gameId) {
    return _activeAlarms[gameId];
  }
}

