import os

filepath = 'lib/features/dashboard/presentation/screens/desktop_dashboard_layout.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

# Fix unused import
text = text.replace("import 'package:snooker_club/core/helpers/currency_helper.dart';\n", "")

# Fix valueOrNull -> value
text = text.replace(".valueOrNull", ".value")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
print("SUCCESS")
