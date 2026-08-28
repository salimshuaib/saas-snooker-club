import 'dart:io';

void main() {
  var file = File(
    'lib/features/analytics/presentation/widgets/revenue_trend_chart_card.dart',
  );
  var content = file.readAsStringSync();

  content = content.replaceAll('data.totalRevenue', 'data.totalBilled');
  content = content.replaceAll('Total Revenue', 'Total Billed');

  content = content.replaceAll('data.gameRevenue', 'data.totalGameBilled');
  content = content.replaceAll('Game Revenue', 'Total Game Billed');

  content = content.replaceAll(
    'data.quickSaleRevenue',
    'data.totalQuickSaleBilled',
  );
  content = content.replaceAll('Quick Sales', 'Quick Sales Billed');

  content = content.replaceAll(
    'data.creditOutstanding',
    'data.outstandingCredit',
  );

  content = content.replaceAll('data.cashReceived', 'data.cashCollected');
  content = content.replaceAll('Cash Received', 'Cash Collected');

  content = content.replaceAll('data.upiReceived', 'data.upiCollected');
  content = content.replaceAll('UPI Received', 'UPI Collected');

  file.writeAsStringSync(content);
}
