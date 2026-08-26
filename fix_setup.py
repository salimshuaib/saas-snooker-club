import re

with open('lib/features/games/presentation/widgets/game_setup_sheet.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Fix AppTextField -> TextField
content = content.replace("AppTextField(", "TextField(")

# Fix onAdd / onRemove ternaries
content = content.replace("onAdd: _teamASelections.length < 10 ? () => setState(() => _teamASelections.add(null)) : null,", 
                          "onAdd: () { if (_teamASelections.length < 10) setState(() => _teamASelections.add(null)); },")
content = content.replace("onRemove: _teamASelections.length > 2 ? (i) => setState(() => _teamASelections.removeAt(i)) : null,", 
                          "onRemove: (i) { if (_teamASelections.length > 2) setState(() => _teamASelections.removeAt(i)); },")

content = content.replace("onAdd: _teamASelections.length < 5 ? () => setState(() => _teamASelections.add(null)) : null,", 
                          "onAdd: () { if (_teamASelections.length < 5) setState(() => _teamASelections.add(null)); },")
content = content.replace("onRemove: _teamASelections.length > 1 ? (i) => setState(() => _teamASelections.removeAt(i)) : null,", 
                          "onRemove: (i) { if (_teamASelections.length > 1) setState(() => _teamASelections.removeAt(i)); },")

content = content.replace("onAdd: _teamBSelections.length < 5 ? () => setState(() => _teamBSelections.add(null)) : null,", 
                          "onAdd: () { if (_teamBSelections.length < 5) setState(() => _teamBSelections.add(null)); },")
content = content.replace("onRemove: _teamBSelections.length > 1 ? (i) => setState(() => _teamBSelections.removeAt(i)) : null,", 
                          "onRemove: (i) { if (_teamBSelections.length > 1) setState(() => _teamBSelections.removeAt(i)); },")


with open('lib/features/games/presentation/widgets/game_setup_sheet.dart', 'w', encoding='utf-8') as f:
    f.write(content)
