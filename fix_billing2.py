import os

filepath = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_code = """          if (mounted) {
            Navigator.of(context).popUntil((route) => route.isFirst); // safely pop BillingScreen and any dialogs instead of context.go
            messenger.showSnackBar("""

new_code = """          if (mounted) {
            Navigator.of(context).pop(); // safely pop BillingScreen
            messenger.showSnackBar("""

text = text.replace(old_code, new_code)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)

