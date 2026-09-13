import os

filepath = 'lib/features/games/presentation/widgets/active_game_card.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_content = """    return AlertDialog(
      title: const Text('Frame Completed'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PayerSelectionWidget(
              allPlayers: widget.game.allPlayers,
              selectedPayers: _selectedPayers,
              onChanged: (newPayers) {
                setState(() {
                  _selectedPayers = newPayers;
                });
              },
            ),
          ],
        ),
      ),
      actions: ["""

new_content = """    final allDefault = widget.game.allPlayers.every((p) => p.toLowerCase().startsWith('default'));

    return AlertDialog(
      title: const Text('Frame Completed'),
      content: allDefault ? const Text('The frame has been completed. What would you like to do next?') : SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            PayerSelectionWidget(
              allPlayers: widget.game.allPlayers,
              selectedPayers: _selectedPayers,
              onChanged: (newPayers) {
                setState(() {
                  _selectedPayers = newPayers;
                });
              },
            ),
          ],
        ),
      ),
      actions: ["""

text = text.replace(old_content, new_content)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
