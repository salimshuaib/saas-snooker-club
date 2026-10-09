import sys

path = 'lib/features/games/presentation/widgets/pending_bills_icon_badge.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("heroTag: 'pendingBillsFab',", "heroTag: null,")

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Disabled heroTag in FAB')
