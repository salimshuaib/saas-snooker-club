import os

filepath = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_pop = """        if (shouldPop == true && mounted) {
          FocusScope.of(context).unfocus();
          await Future.delayed(const Duration(milliseconds: 50));
          if (mounted) Navigator.pop(context);
        }"""
new_pop = """        if (shouldPop == true && mounted) {
          FocusScope.of(context).unfocus();
          await Future.delayed(const Duration(milliseconds: 150));
          if (mounted) Navigator.of(context).pop();
        }"""

if old_pop in text:
    text = text.replace(old_pop, new_pop)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(text)
    print("SUCCESS")
else:
    print("FAILED")
