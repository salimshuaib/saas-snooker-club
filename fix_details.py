import os
import re

filepath = 'lib/features/games/presentation/widgets/table_history_sheet.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

text = re.sub(r"'\$duration[^']+?\$price'", r"'$duration  \\u2022  \\u20B9${price.toStringAsFixed(0)}'", text)
text = text.replace("style: theme.textTheme.labelSmall?.copyWith(", "style: theme.textTheme.bodyMedium?.copyWith(")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
