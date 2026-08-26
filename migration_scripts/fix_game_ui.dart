import 'dart:io';

void main() {
  var file = File('lib/features/analytics/presentation/widgets/game_and_table_analytics_section.dart');
  var content = file.readAsStringSync();

  content = content.replaceAll('gameAnalytics.totalGamesPlayed', 'gameAnalytics.totalGameSessions');
  content = content.replaceAll("_buildKpiCard(context, 'Hours Played', '\ hrs', Icons.access_time_rounded, AppColors.running),", '');
  content = content.replaceAll("_buildKpiCard(context, 'Avg Duration', '\ min', Icons.timelapse_rounded, AppColors.available),", '');
  content = content.replaceAll("_buildKpiCard(context, 'Avg Bill Size', '₹\', Icons.receipt_long_rounded, AppColors.secondary),", '');

  // gamesByTableType -> categories
  content = content.replaceAll('gameAnalytics.gamesByTableType', 'gameAnalytics.categories');

  // tableType -> categoryName in GameCategoryData
  // gamesPlayed -> transactionCount in GameCategoryData
  // averageSessionMinutes -> averageTransactionValue in GameCategoryData
  
  // Actually, the bar chart code probably loops over gamesByTableType. Let's see it later, I'll just change the properties it reads.
  content = content.replaceAll('.tableType', '.categoryName');
  content = content.replaceAll('.gamesPlayed.toDouble()', '.transactionCount.toDouble()');
  content = content.replaceAll('.gamesPlayed', '.transactionCount');

  // TablePerformanceItem
  // tableType -> tableName
  // gamesPlayed -> sessionsCount
  // averageSessionMinutes -> averageSessionValue
  // totalRevenue -> totalBilled
  content = content.replaceAll('.averageSessionMinutes', '.averageSessionValue');
  content = content.replaceAll('.totalRevenue', '.totalBilled');
  
  file.writeAsStringSync(content);
}
