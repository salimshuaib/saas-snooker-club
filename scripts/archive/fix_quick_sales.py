import sys
import re

def fix_file(file_path, target, replacement):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()
    if target in content:
        content = content.replace(target, replacement)
        with open(file_path, 'w', encoding='utf-8') as f:
            f.write(content)
        print(f"Fixed {file_path}")
    else:
        print(f"Target not found in {file_path}")

target_qs = """    await Future.delayed(const Duration(milliseconds: 400));
    final salesToDelete = allSales.where((s) => _selectedSaleIds.contains(s.id)).toList();

    try {
      await ref.read(quickSalesRepositoryProvider).deleteQuickSales(salesToDelete);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$selectedCount quick sale${selectedCount > 1 ? 's' : ''} deleted successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      _exitSelectionMode();
    } catch (e) {"""

repl_qs = """    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => const PopScope(canPop: false, child: Center(child: CircularProgressIndicator())),
    );
    try {
      await Future.delayed(const Duration(milliseconds: 400));
      final salesToDelete = allSales.where((s) => _selectedSaleIds.contains(s.id)).toList();
      await ref.read(quickSalesRepositoryProvider).deleteQuickSales(salesToDelete);
      await Future.delayed(const Duration(milliseconds: 500));
      if (!mounted) return;
      Navigator.pop(context); // close loading
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$selectedCount quick sale${selectedCount > 1 ? 's' : ''} deleted successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      _exitSelectionMode();
    } catch (e) {
      if (mounted) Navigator.pop(context); // close loading"""

fix_file('lib/features/quick_sales/presentation/screens/quick_sales_screen.dart', target_qs, repl_qs)
