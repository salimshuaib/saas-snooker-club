import sys

file_path = 'lib/features/quick_sales/presentation/screens/quick_sales_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''    if (confirm != true || !mounted) return;

    final salesToDelete = allSales.where((s) => _selectedSaleIds.contains(s.id)).toList();

    try {
      await ref.read(quickSalesRepositoryProvider).deleteQuickSales(salesToDelete);'''

replacement = '''    if (confirm != true || !mounted) return;

    await Future.delayed(const Duration(milliseconds: 400));
    final salesToDelete = allSales.where((s) => _selectedSaleIds.contains(s.id)).toList();

    try {
      await ref.read(quickSalesRepositoryProvider).deleteQuickSales(salesToDelete);'''

if target in content:
    content = content.replace(target, replacement)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Replaced quick_sales_screen")
else:
    print("Target not found in quick_sales_screen")
