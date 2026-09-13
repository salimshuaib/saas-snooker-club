import os

filepath = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_str = """        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          context.go('/live');
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Payment recorded. Table is now available.'),
              backgroundColor: AppColors.success,
            ),
          );
        }"""

new_str = """        if (mounted) {
          // Show success message
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Payment recorded. Table is now available.'),
              backgroundColor: AppColors.success,
            ),
          );
          
          // Pop the BillingScreen gracefully
          Navigator.of(context).pop();
          
          // Wait for the pop animation to finish, then safely switch tabs using the global router
          Future.delayed(const Duration(milliseconds: 350), () {
            ref.read(appRouterProvider).go('/live');
          });
        }"""

if old_str in text:
    text = text.replace(old_str, new_str)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(text)
    print("SUCCESS")
else:
    print("FAILED to find old_str")
