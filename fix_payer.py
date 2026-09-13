import os

filepath = 'lib/features/games/presentation/widgets/payer_selection_widget.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_init = """  void initState() {
    super.initState();
    // Default to 'All' being visually active if everyone is selected on first load.
    _isAllExplicitlySelected =
        widget.selectedPayers.length == widget.allPlayers.length;
  }"""
new_init = """  void initState() {
    super.initState();
    _isAllExplicitlySelected = false;
  }"""

text = text.replace(old_init, new_init)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
