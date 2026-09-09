import 'package:flutter/material.dart';

class PayerSelectionWidget extends StatelessWidget {
  final List<String> allPlayers;
  final List<String> selectedPayers;
  final ValueChanged<List<String>> onChanged;
  final String title;

  const PayerSelectionWidget({
    Key? key,
    required this.allPlayers,
    required this.selectedPayers,
    required this.onChanged,
    this.title = 'Who Will Pay?',
  }) : super(key: key);

  void _togglePlayer(String player) {
    final List<String> newSelection = List.from(selectedPayers);
    if (newSelection.contains(player)) {
      newSelection.remove(player);
    } else {
      newSelection.add(player);
    }
    onChanged(newSelection);
  }

  void _toggleAll() {
    if (selectedPayers.length == allPlayers.length) {
      onChanged([]);
    } else {
      onChanged(List.from(allPlayers));
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAllSelected = selectedPayers.length == allPlayers.length && allPlayers.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 12),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            ChoiceChip(
              label: const Text('All'),
              selected: isAllSelected,
              onSelected: (_) => _toggleAll(),
              selectedColor: theme.colorScheme.primaryContainer,
              labelStyle: TextStyle(
                fontWeight: isAllSelected ? FontWeight.bold : FontWeight.normal,
                color: isAllSelected ? theme.colorScheme.onPrimaryContainer : null,
              ),
            ),
            ...allPlayers.map((player) {
              final isSelected = selectedPayers.contains(player);
              return ChoiceChip(
                label: Text(player),
                selected: isSelected,
                onSelected: (_) => _togglePlayer(player),
                selectedColor: theme.colorScheme.primaryContainer,
                labelStyle: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? theme.colorScheme.onPrimaryContainer : null,
                ),
              );
            }).toList(),
          ],
        ),
      ],
    );
  }
}
