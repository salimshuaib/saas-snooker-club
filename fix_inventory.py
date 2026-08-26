import sys

file_path = 'lib/features/inventory/presentation/screens/product_details_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''    if (confirm == true) {
      await ref.read(inventoryRepositoryProvider).disableProduct(item.id);'''

replacement = '''    if (confirm == true) {
      await Future.delayed(const Duration(milliseconds: 400));
      await ref.read(inventoryRepositoryProvider).disableProduct(item.id);'''

if target in content:
    content = content.replace(target, replacement)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Replaced product_details_screen")
else:
    print("Target not found in product_details_screen")
