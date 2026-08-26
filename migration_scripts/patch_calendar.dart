import 'dart:io';

void main() {
  var file = File('lib/features/dashboard/presentation/screens/todays_revenue_details_screen.dart');
  var content = file.readAsStringSync();
  
  // 1. Add import
  if (!content.contains('financial_summary_card.dart')) {
    content = content.replaceFirst(
      "import 'package:snooker_club/core/providers/app_providers.dart';",
      "import 'package:snooker_club/core/providers/app_providers.dart';\nimport 'package:snooker_club/features/dashboard/presentation/widgets/financial_summary_card.dart';"
    );
  }

  // Replace Revenue Breakdown Card
  var startStr = "// ─── Revenue Breakdown Card ───";
  var startIndex = content.indexOf(startStr);
  
  var endStr = "// ─── Game Transactions Header ───";
  var endIndex = content.indexOf(endStr);
  
  if (startIndex != -1 && endIndex != -1) {
    var replacement = '''// ─── Revenue Breakdown Card ───
                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: const FinancialSummaryCard(
                      forSelectedDate: true,
                      isInteractive: false,
                    ),
                  ),
                ),

                ''';
    content = content.substring(0, startIndex) + replacement + content.substring(endIndex);
    file.writeAsStringSync(content);
    print('Calendar updated correctly!');
  } else {
    print('Could not find replace targets: ' + startIndex.toString() + ', ' + endIndex.toString());
  }
}
