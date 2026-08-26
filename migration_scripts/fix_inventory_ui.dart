import 'dart:io';

void main() {
  var file = File('lib/features/analytics/presentation/widgets/inventory_and_product_analytics_section.dart');
  var content = file.readAsStringSync();

  content = content.replaceAll('final InventoryInsightsData inventoryInsights;', '');
  content = content.replaceAll('required this.inventoryInsights,', '');

  // Remove the '8. Inventory Valuation & Category Insights' block
  var insightsBlock = '''const SizedBox(height: AppSpacing.xl),
        Text(
          '8. Inventory Valuation & Category Insights',
          style: AppTypography.textTheme.titleMedium!.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: AppSpacing.md),
        _buildInventoryInsightsCard(context, isDark),''';
  
  content = content.replaceFirst(insightsBlock, '');

  // BestSellingProductItem properties
  content = content.replaceAll('.category', '.productName');
  content = content.replaceAll('.revenue', '.salesAmount');

  file.writeAsStringSync(content);
}
