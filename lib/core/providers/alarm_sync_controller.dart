import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/services/table_alarm_service.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/features/floors/providers/floor_providers.dart';

final alarmSyncControllerProvider = Provider<AlarmSyncController>((ref) {
  return AlarmSyncController(ref);
});

class AlarmSyncController {
  final Ref ref;
  final Map<String, DateTime> _syncedAlarms = {};
  
  AlarmSyncController(this.ref) {
    _initializeSync();
  }

  void _initializeSync() {
    // Listen to changes in both running games, current staff state, and selected floor
    ref.listen<AsyncValue<List<GameSession>>>(runningGamesProvider, (previous, next) {
      _evaluateAlarms(next.value ?? [], ref.read(currentStaffProvider).value, ref.read(selectedFloorIdProvider));
    });

    ref.listen<AsyncValue<StaffMember?>>(currentStaffProvider, (previous, next) {
      _evaluateAlarms(ref.read(runningGamesProvider).value ?? [], next.value, ref.read(selectedFloorIdProvider));
    });

    ref.listen<String?>(selectedFloorIdProvider, (previous, next) {
      _evaluateAlarms(ref.read(runningGamesProvider).value ?? [], ref.read(currentStaffProvider).value, next);
    });
  }

  void _evaluateAlarms(List<GameSession> games, StaffMember? staff, String? selectedFloorId) {
    if (staff == null) {
      _cancelAllLocalAlarms();
      return;
    }

    // Auto-checkout rule
    bool isActiveCheckIn = staff.isCheckedIn;
    if (isActiveCheckIn && staff.lastCheckInTime != null) {
      final hoursSinceCheckIn = DateTime.now().difference(staff.lastCheckInTime!).inHours;
      if (hoursSinceCheckIn >= 24) {
        isActiveCheckIn = false;
        try {
          ref.read(teamRepositoryProvider).checkOutStaff(staff.id, autoCheckedOut: true);
        } catch (_) {}
      }
    }

    final currentValidAlarmIds = <String>{};

    for (final game in games) {
      // 1. Floor filter: Always respect the currently viewed floor
      if (selectedFloorId != null && game.floorId != selectedFloorId) {
        continue;
      }

      // 2. Persona filter: Checked-in staff get all alarms. Off-duty staff get only their own alarms.
      bool shouldRing = false;
      if (isActiveCheckIn) {
        shouldRing = true;
      } else if (game.alarmSetByUserId == staff.id) {
        shouldRing = true;
      }

      if (!shouldRing) {
        continue;
      }

      final alarmTime = game.alarmTime;
      // Process alarms that are set and not extremely old (e.g. within the last 12 hours)
      // This ensures if we switch floors, an already-ringing alarm instantly syncs and rings for us.
      if (alarmTime != null && alarmTime.isAfter(DateTime.now().subtract(const Duration(hours: 12)))) {
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
    final toRemove = _syncedAlarms.keys.where((id) => !currentValidAlarmIds.contains(id)).toList();
    for (final gameId in toRemove) {
      TableAlarmService().cancelAlarm(gameId);
      _syncedAlarms.remove(gameId);
    }
  }

  void _cancelAllLocalAlarms() {
    for (final gameId in _syncedAlarms.keys) {
      TableAlarmService().cancelAlarm(gameId);
    }
    _syncedAlarms.clear();
  }
}
