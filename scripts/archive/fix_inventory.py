import sys

file_path = 'lib/features/inventory/presentation/screens/product_details_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''    if (confirm == true) {
      await Future.delayed(const Duration(milliseconds: 400));
      await ref.read(inventoryRepositoryProvider).disableProduct(item.id);
      if (!context.mounted) return;
      Navigator.pop(context);
    }'''

replacement = '''    if (confirm == true) {
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => const PopScope(
          canPop: false,
          child: Center(child: CircularProgressIndicator()),
        ),
      );
      try {
        await Future.delayed(const Duration(milliseconds: 400));
        await ref.read(inventoryRepositoryProvider).disableProduct(item.id);
        await Future.delayed(const Duration(milliseconds: 500));
      } finally {
        if (context.mounted) {
          Navigator.pop(context); // pop loading
          Navigator.pop(context); // pop product details
        }
      }
    }'''

if target in content:
    content = content.replace(target, replacement)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Replaced loading dialog in product_details_screen")
else:
    print("Target not found in product_details_screen")
