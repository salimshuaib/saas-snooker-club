import sys

file_path = 'lib/features/credit/presentation/screens/credit_screen.dart'
with open(file_path, 'r', encoding='utf-8') as f:
    content = f.read()

target = '''                  if (confirm == true) {
                    await Future.delayed(const Duration(milliseconds: 400));
                    await ref.read(creditControllerProvider.notifier).deleteMultipleCustomers(selectedIds);
                    ref.read(customerSelectionProvider.notifier).clear();
                  }'''

replacement = '''                  if (confirm == true) {
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
                      await ref.read(creditControllerProvider.notifier).deleteMultipleCustomers(selectedIds);
                      // Add a small delay to ensure Firestore streams have emitted before unlocking the UI
                      await Future.delayed(const Duration(milliseconds: 500));
                      ref.read(customerSelectionProvider.notifier).clear();
                    } finally {
                      if (context.mounted) Navigator.pop(context);
                    }
                  }'''

if target in content:
    content = content.replace(target, replacement)
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Replaced loading dialog in credit_screen")
else:
    print("Target not found in credit_screen")
