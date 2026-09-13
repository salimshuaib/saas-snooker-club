import os

filepath = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_success = """      if (mounted) {
        context.go('/games');
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Payment recorded. Table is now available.'),
            backgroundColor: AppColors.success,
          ),
        );
        return; // Skip finally block to prevent setState during disposal
      }"""

new_success = """      if (mounted) {
        // Stop the loading spinner and wait a frame to prevent CanvasKit crash
        setState(() => _isProcessing = false);
        await Future.delayed(const Duration(milliseconds: 50));
        
        if (mounted) {
          context.go('/games');
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Payment recorded. Table is now available.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
        return;
      }"""

text = text.replace(old_success, new_success)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
