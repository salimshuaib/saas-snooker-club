import sys

file_path = 'lib/features/quick_sales/presentation/screens/quick_sale_details_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''    if (confirm != true || !context.mounted) return;

    try {
      await ref.read(quickSalesRepositoryProvider).deleteQuickSales([s]);'''

replacement = '''    if (confirm != true || !context.mounted) return;

    await Future.delayed(const Duration(milliseconds: 400));
    try {
      await ref.read(quickSalesRepositoryProvider).deleteQuickSales([s]);'''

if target in content:
    content = content.replace(target, replacement)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Replaced quick_sale_details_screen")
else:
    print("Target not found in quick_sale_details_screen")
