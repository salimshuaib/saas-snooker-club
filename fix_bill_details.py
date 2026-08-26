with open('lib/features/games/presentation/screens/bill_details_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

old_row = "_InfoRow(label: 'Game Type', value: session.tableType.displayName),"
new_row = "_InfoRow(label: 'Table Type', value: session.tableType.displayName),\n                  _InfoRow(label: 'Game Type', value: session.gameType.displayName),"

content = content.replace(old_row, new_row)

with open('lib/features/games/presentation/screens/bill_details_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
