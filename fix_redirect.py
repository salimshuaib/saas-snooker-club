import os

filepath = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_str = """        // Stop the loading spinner and wait a frame to prevent CanvasKit crash
        setState(() => _isProcessing = false);
        await Future.delayed(const Duration(milliseconds: 50));

        if (mounted) {
          context.go('/games');"""

new_str = """        // Stop the loading spinner and wait a frame to prevent CanvasKit crash
        setState(() => _isProcessing = false);
        await Future.delayed(const Duration(milliseconds: 150));

        if (mounted) {
          Navigator.of(context).popUntil((route) => route.isFirst);
          context.go('/live');"""

if old_str in text:
    text = text.replace(old_str, new_str)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(text)
    print("SUCCESS")
else:
    print("FAILED to find old_str")
