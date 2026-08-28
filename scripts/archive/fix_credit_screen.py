import sys

file_path = 'lib/features/credit/presentation/screens/credit_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''                  if (confirm == true) {
                    await ref.read(creditControllerProvider.notifier).deleteMultipleCustomers(selectedIds);
                    ref.read(customerSelectionProvider.notifier).clear();
                  }'''

replacement = '''                  if (confirm == true) {
                    await Future.delayed(const Duration(milliseconds: 400));
                    await ref.read(creditControllerProvider.notifier).deleteMultipleCustomers(selectedIds);
                    ref.read(customerSelectionProvider.notifier).clear();
                  }'''

if target in content:
    content = content.replace(target, replacement)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Replaced successfully")
else:
    print("Target not found")
