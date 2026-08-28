import 'dart:io';

void main() {
  var file = File(
    'lib/features/dashboard/presentation/screens/dashboard_screen.dart',
  );
  var content = file.readAsStringSync();

  // 1. Add import
  if (!content.contains('financial_summary_card.dart')) {
    content = content.replaceFirst(
      "import 'package:snooker_club/features/dashboard/presentation/screens/inventory_status_screen.dart';",
      "import 'package:snooker_club/features/dashboard/presentation/screens/inventory_status_screen.dart';\nimport 'package:snooker_club/features/dashboard/presentation/widgets/financial_summary_card.dart';",
    );
  }

  // Find start and end indices
  var startStr = "// Quick Stats";
  var startIndex = content.indexOf(startStr);

  var endStr = "final qsCount = ref.watch(todaysQuickSalesCountProvider);";
  var endSearchIndex = content.indexOf(endStr);

  // Back up to the Row declaration
  var trueEndIndex = content.lastIndexOf("Row(", endSearchIndex);
  var gapIndex = content.lastIndexOf("const Gap(24)", trueEndIndex);

  if (startIndex != -1 && gapIndex != -1) {
    var replacement = '''// Quick Stats
                Text(
                  'Overview',
                  style: theme.textTheme.titleMedium,
                ),
                const Gap(12),
                
                // --- PHASE 5: NEW FINANCIAL SUMMARY ---
                const FinancialSummaryCard(),
                const Gap(12),

                // Table Status Grid
                Row(
                  children: [
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final runningCount = ref.watch(runningTablesCountProvider);
                          return InfoCard(
                            title: 'Running Tables',
                            value: runningCount.toString(),
                            icon: Icons.table_restaurant,
                            iconColor: AppColors.running,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const RunningTablesScreen(),
                                ),
                              );
                            },
                          );
                        }
                      ),
                    ),
                    const Gap(12),
                    Expanded(
                      child: Consumer(
                        builder: (context, ref, child) {
                          final availableCount = ref.watch(availableTablesCountProvider);
                          return InfoCard(
                            title: 'Available Tables',
                            value: availableCount.toString(),
                            icon: Icons.check_circle_outline,
                            iconColor: AppColors.available,
                            onTap: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => const AvailableTablesScreen(),
                                ),
                              );
                            },
                          );
                        }
                      ),
                    ),
                  ],
                ),
                ''';
    content =
        content.substring(0, startIndex) +
        replacement +
        content.substring(gapIndex);
    file.writeAsStringSync(content);
    print('Dashboard updated correctly!');
  } else {
    print(
      'Could not find replace targets: ' +
          startIndex.toString() +
          ', ' +
          gapIndex.toString(),
    );
  }
}
