import os

filepath = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_code = """        if (shouldPop == true && mounted) {
          Navigator.pop(context);
        }"""
new_code = """        if (shouldPop == true && mounted) {
          FocusScope.of(context).unfocus();
          await Future.delayed(const Duration(milliseconds: 50));
          if (mounted) Navigator.pop(context);
        }"""

text = text.replace(old_code, new_code)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
