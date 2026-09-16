void main() {
  final startTime = DateTime(2026, 9, 16, 11, 50, 0); // 11:50 AM
  final endTime = DateTime(2026, 9, 16, 23, 55, 0); // 11:55 PM
  
  final duration = endTime.difference(startTime);
  print(duration);
}
