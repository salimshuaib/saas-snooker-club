import 'dart:async';
import 'package:flutter/foundation.dart';

/// Reusable debouncer to limit the rate of user input execution,
/// reducing unnecessary provider recalculations and Firebase query evaluations.
class Debouncer {
  final int milliseconds;
  Timer? _timer;

  Debouncer({this.milliseconds = 300});

  /// Execute [action] after waiting [milliseconds] from the last invocation.
  void run(VoidCallback action) {
    if (_timer != null && _timer!.isActive) {
      _timer!.cancel();
    }
    _timer = Timer(Duration(milliseconds: milliseconds), action);
  }

  /// Immediately cancel any pending action.
  void dispose() {
    _timer?.cancel();
    _timer = null;
  }
}
