import os

filepath = 'lib/features/analytics/providers/analytics_providers.dart'

with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("yield* repo.watchQuickSalesByDateRange(tr.start, tr.end);", "await Future.delayed(const Duration(milliseconds: 100));\n  yield* repo.watchQuickSalesByDateRange(tr.start, tr.end);")
content = content.replace("yield* db\n      .collectionGroup('payments')", "await Future.delayed(const Duration(milliseconds: 100));\n    yield* db\n      .collectionGroup('payments')")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print(f"Updated {filepath}")
