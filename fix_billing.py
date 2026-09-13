import os

filepath = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_code = """          // Stop the loading spinner and wait a frame to prevent CanvasKit crash
          setState(() => _isProcessing = false);
          await Future.delayed(const Duration(milliseconds: 50));

          if (mounted) {
            context.go('/games');"""

new_code = """          // Stop the loading spinner and wait a frame to prevent CanvasKit crash
          setState(() => _isProcessing = false);
          await Future.delayed(const Duration(milliseconds: 150)); // wait for any dialog to fade

          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst); // safely pop BillingScreen and any dialogs instead of context.go"""

text = text.replace(old_code, new_code)

old_popscope = """        if (shouldPop == true && mounted) {
          FocusScope.of(context).unfocus();
          await Future.delayed(const Duration(milliseconds: 50));
          if (mounted) Navigator.pop(context);
        }"""
new_popscope = """        if (shouldPop == true && mounted) {
          FocusScope.of(context).unfocus();
          await Future.delayed(const Duration(milliseconds: 150));
          if (mounted) Navigator.of(context).pop();
        }"""
text = text.replace(old_popscope, new_popscope)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)

