import os

filepath = 'lib/features/games/presentation/widgets/table_history_sheet.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

# Replace price calculation
text = text.replace(
    "final num price = game.grandTotal ?? 0;",
    "final num price = game.roundedAmount ?? game.finalAmount ?? game.grandTotal ?? 0;"
)

# Replace start time style
text = text.replace(
    "style: theme.textTheme.labelMedium?.copyWith(",
    "style: theme.textTheme.titleSmall?.copyWith("
)

# Replace player style
text = text.replace(
    "style: theme.textTheme.bodyMedium?.copyWith(\n                    fontWeight: FontWeight.w600,",
    "style: theme.textTheme.titleMedium?.copyWith(\n                    fontWeight: FontWeight.bold,"
)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
