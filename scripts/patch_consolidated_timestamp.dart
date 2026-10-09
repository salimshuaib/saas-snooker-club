import 'dart:io';

void main() {
  final file = File('lib/features/games/data/games_repository.dart');
  var content = file.readAsStringSync();
  
  final oldLine = "'startTime': earliestStartTime?.toIso8601String() ?? now.toIso8601String(),";
  final newLine = "'startTime': earliestStartTime != null ? Timestamp.fromDate(earliestStartTime) : Timestamp.fromDate(now),";
  
  content = content.replaceFirst(oldLine, newLine);
  
  final oldLine2 = "'endTime': now.toIso8601String(),";
  final newLine2 = "'endTime': Timestamp.fromDate(now),";
  
  content = content.replaceFirst(oldLine2, newLine2);
  
  file.writeAsStringSync(content);
}
