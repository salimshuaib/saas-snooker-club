import os

filepath = 'lib/features/games/presentation/widgets/payer_selection_widget.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_all = """          const SizedBox(height: 16),
          _buildOptionTile(
            context,
            title: 'All',
            isSelected: isAllSelected,
            onTap: _toggleAll,
          ),"""
new_all = """          const SizedBox(height: 16),
          if (widget.allPlayers.length > 1)
            _buildOptionTile(
              context,
              title: 'All',
              isSelected: isAllSelected,
              onTap: _toggleAll,
            ),"""

text = text.replace(old_all, new_all)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
