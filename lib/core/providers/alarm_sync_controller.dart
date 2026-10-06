import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/services/table_alarm_service.dart';
import 'package:snooker_club/core/utils/logger.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';

final alarmSyncControllerProvider = Provider<AlarmSyncController>((ref) {
  final controller = AlarmSyncController(ref);
  ref.onDispose(controller.dispose);
  return controller;
});

class AlarmSyncController {
  final Ref ref;
  final Map<String, DateTime> _syncedAlarms = {};
  final Map<String, DateTime> _locallyAutoCheckedOutAt = {};
  Timer? _autoCheckoutTimer;
  String? _autoCheckoutInFlightFor;
  bool _alarmsCancelledForOffDuty = false;

  AlarmSyncController(this.ref) {
    _initializeSync();
  }

  void _initializeSync() {
    // Listen to changes in both running games and current staff state
    ref.listen<AsyncValue<List<GameSession>>>(runningGamesProvider, (
      previous,
      next,
    ) {
      _evaluateAlarms(next.value ?? [], ref.read(currentStaffProvider).value);
    });

    ref.listen<AsyncValue<StaffMember?>>(currentStaffProvider, (
      previous,
      next,
    ) {
      _evaluateAlarms(ref.read(runningGamesProvider).value ?? [], next.value);
    });

    _evaluateAlarms(
      ref.read(runningGamesProvider).value ?? [],
      ref.read(currentStaffProvider).value,
    );
  }

  void _evaluateAlarms(List<GameSession> games, StaffMember? staff) {
    if (staff == null) {
      _cancelAllLocalAlarmsIfNeeded();
      _autoCheckoutTimer?.cancel();
      return;
    }

    final localCheckoutTime = _locallyAutoCheckedOutAt[staff.id];
    if (localCheckoutTime != null &&
        staff.lastCheckInTime != null &&
        staff.lastCheckInTime!.isAfter(localCheckoutTime)) {
      _locallyAutoCheckedOutAt.remove(staff.id);
    }

    if (_locallyAutoCheckedOutAt.containsKey(staff.id)) {
      _autoCheckoutTimer?.cancel();
      _cancelAllLocalAlarmsIfNeeded();
      return;
    }

    _scheduleAutoCheckout(staff);
    if (_locallyAutoCheckedOutAt.containsKey(staff.id)) {
      _cancelAllLocalAlarmsIfNeeded();
      return;
    }

    if (!staff.isCheckedIn) {
      _cancelAllLocalAlarmsIfNeeded();
      return;
    }
    _alarmsCancelledForOffDuty = false;

    final currentValidAlarmIds = <String>{};

    for (final game in games) {
      final alarmTime = game.alarmTime;
      // Only process alarms that are in the future
      if (alarmTime != null && alarmTime.isAfter(DateTime.now())) {
        currentValidAlarmIds.add(game.id);

        // If this alarm is not already active, or its time has changed, update it locally
        if (_syncedAlarms[game.id] != alarmTime) {
          final alarmService = TableAlarmService();

          alarmService.setAlarm(
            gameId: game.id,
            tableName: game.tableName,
            fireAt: alarmTime,
          );
          _syncedAlarms[game.id] = alarmTime;
        }
      }
    }

    // Cancel any local alarms that are no longer present in the cloud list
    final toRemove = _syncedAlarms.keys
        .where((id) => !currentValidAlarmIds.contains(id))
        .toList();
    for (final gameId in toRemove) {
      TableAlarmService().cancelAlarm(gameId);
      _syncedAlarms.remove(gameId);
    }
  }

  void _scheduleAutoCheckout(StaffMember staff) {
    _autoCheckoutTimer?.cancel();
    _autoCheckoutTimer = null;

    if (!staff.isCheckedIn || staff.lastCheckInTime == null) return;

    final remaining = staff.lastCheckInTime!
        .add(const Duration(hours: 24))
        .difference(DateTime.now());
    if (remaining <= Duration.zero) {
      unawaited(_autoCheckOut(staff.id, staff.lastCheckInTime!));
      return;
    }

    _autoCheckoutTimer = Timer(remaining, () {
      unawaited(_autoCheckOut(staff.id, staff.lastCheckInTime!));
    });
  }

  Future<void> _autoCheckOut(String staffId, DateTime checkInTime) async {
    if (_autoCheckoutInFlightFor == staffId) return;
    _autoCheckoutInFlightFor = staffId;
    _locallyAutoCheckedOutAt[staffId] = checkInTime;
    _cancelAllLocalAlarmsIfNeeded();
    try {
      await ref.read(teamRepositoryProvider).checkOutStaff(staffId);
    } catch (error, stackTrace) {
      AppLogger.error(
        'Automatic staff check-out failed',
        error: error,
        stackTrace: stackTrace,
      );
    } finally {
      _autoCheckoutInFlightFor = null;
    }
  }

  void _cancelAllLocalAlarmsIfNeeded() {
    if (_alarmsCancelledForOffDuty) return;
    _alarmsCancelledForOffDuty = true;
    _syncedAlarms.clear();
    unawaited(_cancelAlarms());
  }

  Future<void> _cancelAlarms() async {
    try {
      await TableAlarmService().cancelAllAlarms();
    } catch (error, stackTrace) {
      AppLogger.error(
        'Failed to cancel local alarms after staff check-out',
        error: error,
        stackTrace: stackTrace,
      );
    }
  }

  void dispose() {
    _autoCheckoutTimer?.cancel();
  }
}
