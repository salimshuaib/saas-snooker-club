import 'dart:async';
import 'package:flutter/material.dart';
import 'package:snooker_club/core/services/table_alarm_service.dart';
import 'package:snooker_club/features/games/presentation/widgets/alarm_overlay.dart';

class AlarmListenerWrapper extends StatefulWidget {
  final Widget child;

  const AlarmListenerWrapper({Key? key, required this.child}) : super(key: key);

  @override
  State<AlarmListenerWrapper> createState() => _AlarmListenerWrapperState();
}

class _AlarmListenerWrapperState extends State<AlarmListenerWrapper> {
  StreamSubscription? _sub;

  @override
  void initState() {
    super.initState();
    _sub = TableAlarmService().onAlarmFired.listen((alarm) {
      if (mounted) {
        AlarmOverlay.show(context, alarm);
      }
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return widget.child;
  }
}
