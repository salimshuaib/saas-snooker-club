import 'dart:async';
import 'dart:convert';
import 'package:alarm/alarm.dart';
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
  static final TableAlarmService _instance = TableAlarmService._internal();
  factory TableAlarmService() => _instance;
  TableAlarmService._internal();

  final Map<String, AlarmInfo> _activeAlarms = {};
  final Map<String, Timer> _fallbackTimers = {};

  final _alarmFiredController = StreamController<AlarmInfo>.broadcast();
  Stream<AlarmInfo> get onAlarmFired => _alarmFiredController.stream;

  final _alarmsChangedController = StreamController<void>.broadcast();
  Stream<void> get onAlarmsChanged => _alarmsChangedController.stream;

  final FlutterTts _flutterTts = FlutterTts();
  final AudioPlayer _sirenPlayer = AudioPlayer();
  Timer? _ttsLoopTimer;
  StreamSubscription<AlarmSettings>? _ringSubscription;
  int? _currentlyRingingId;

  Future<void> initialize() async {
    await _flutterTts.setVolume(1.0);
    await _flutterTts.setSpeechRate(0.5);
    await _flutterTts.setPitch(1.0);

    if (!kIsWeb) {
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
           if (!kIsWeb) await Alarm.stop(alarm.gameId.hashCode);
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

    if (!kIsWeb) {
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

      if (!kIsWeb) {
        await Alarm.stop(gameId.hashCode);
      }
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

    if (rootNavigatorKey.currentContext != null) {
      AlarmOverlay.show(rootNavigatorKey.currentContext!, alarm);
    }

    if (kIsWeb || (defaultTargetPlatform != TargetPlatform.android && defaultTargetPlatform != TargetPlatform.iOS)) {
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

      final textToSpeak = '${alarm.tableName} time over';

      // The alarm package natively loops the siren on mobile. For desktop/web, we just triggered it above.
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
      await _sirenPlayer.stop();
      
      if (!kIsWeb && _currentlyRingingId != null) {
        await Alarm.stop(_currentlyRingingId!);
        _currentlyRingingId = null;
      }
      
      // Catch-all to stop any active alarms playing via alarm package
      if (!kIsWeb) {
        try {
           final hasAlarm = await Alarm.hasAlarm();
           if (hasAlarm) {
               await Alarm.stopAll();
           }
        } catch (_) {}
      }
    } catch (e) {
      AppLogger.error('Failed to stop TTS: $e');
    }
  }

  AlarmInfo? getAlarmInfo(String gameId) {
    return _activeAlarms[gameId];
  }
}
