import sys

file_path = 'lib/features/quick_sales/presentation/screens/quick_sale_details_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''    if (result == true && context.mounted) {
      try {
        await ref.read(quickSalesRepositoryProvider).updateQuickSalePaymentMethod('''

replacement = '''    if (result == true && context.mounted) {
      await Future.delayed(const Duration(milliseconds: 400));
      try {
        await ref.read(quickSalesRepositoryProvider).updateQuickSalePaymentMethod('''

if target in content:
    content = content.replace(target, replacement)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Replaced updateQuickSalePaymentMethod in quick_sale_details_screen")
else:
    print("Target not found in updateQuickSalePaymentMethod")
