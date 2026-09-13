import os

filepath = 'lib/features/games/data/games_repository.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("editedBy: employeeName,", "editedBy: currentUserName,")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)

filepath = 'lib/features/quick_sales/data/quick_sales_repository.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

text = text.replace("editedBy: employeeName,", "editedBy: currentUserName,")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
