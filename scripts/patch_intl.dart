import 'dart:io';

void main() {
  final file = File('lib/features/games/data/games_repository.dart');
  var content = file.readAsStringSync();
  
  if (!content.contains('package:intl/intl.dart')) {
    final idx = content.indexOf('import');
    content = content.substring(0, idx) + "import 'package:intl/intl.dart';\n" + content.substring(idx);
    file.writeAsStringSync(content);
  }
}
