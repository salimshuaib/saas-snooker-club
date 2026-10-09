import 'dart:io';

void main() {
  final file = File('lib/features/games/domain/models/game_models.dart');
  var content = file.readAsStringSync();
  
  final oldLine = "startTime: (map['startTime'] as Timestamp).toDate(),";
  final newLine = "startTime: map['startTime'] is String ? DateTime.parse(map['startTime']) : (map['startTime'] as Timestamp).toDate(),";
  
  content = content.replaceFirst(oldLine, newLine);
  
  file.writeAsStringSync(content);
}
