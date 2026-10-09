import 'dart:io';

void main() {
  final file = File('lib/features/dashboard/presentation/widgets/financial_summary_card.dart');
  var content = file.readAsStringSync();

  final startIf = content.indexOf('if (!forSelectedDate)');
  final endIf = content.indexOf('],', startIf);
  
  final oldSection = content.substring(startIf, endIf);
  var newSection = oldSection.replaceFirst('if (!forSelectedDate)', 'if (!forSelectedDate) ...[');
  
  newSection += '''
                    _buildRow(
                      \\'Pending Bills\\',
                      summary.pendingBillsAmount,
                      currency,
                      theme,
                      color: Colors.orange,
                    ),
                  ''';
                  
  content = content.substring(0, startIf) + newSection + content.substring(endIf);
  file.writeAsStringSync(content);
  print('Done');
}

