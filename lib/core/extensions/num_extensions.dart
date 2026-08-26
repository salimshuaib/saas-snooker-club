/// Numeric utility extensions.
extension NumExtensions on num {
  /// Convert minutes to a duration string (e.g., '1h 30m').
  String get toDurationString {
    final totalMinutes = toInt();
    final hours = totalMinutes ~/ 60;
    final minutes = totalMinutes % 60;
    if (hours > 0 && minutes > 0) return '${hours}h ${minutes}m';
    if (hours > 0) return '${hours}h';
    return '${minutes}m';
  }

  /// Convert seconds to a timer string (e.g., '01:30:45').
  String get toTimerString {
    final totalSeconds = toInt();
    final hours = totalSeconds ~/ 3600;
    final minutes = (totalSeconds % 3600) ~/ 60;
    final seconds = totalSeconds % 60;
    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }
}
