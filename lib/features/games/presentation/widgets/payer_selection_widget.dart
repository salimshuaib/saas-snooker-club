import 'package:flutter/material.dart';

class PayerSelectionWidget extends StatefulWidget {
  final List<String> allPlayers;
  final List<String> selectedPayers;
  final ValueChanged<List<String>> onChanged;
  final String title;
  final void Function(String)? onEditPlayer;
  final VoidCallback? onAddPlayer;

  const PayerSelectionWidget({
    super.key,
    required this.allPlayers,
    required this.selectedPayers,
    required this.onChanged,
    this.title = 'Who will Pay?',
    this.onEditPlayer,
    this.onAddPlayer,
  });

  @override
  State<PayerSelectionWidget> createState() => _PayerSelectionWidgetState();
}

class _PayerSelectionWidgetState extends State<PayerSelectionWidget> {
  late bool _isAllExplicitlySelected;

  @override
  void initState() {
    super.initState();
    // Default to 'All' being visually active if everyone is selected on first load.
    _isAllExplicitlySelected = widget.selectedPayers.length == widget.allPlayers.length;
  }

  @override
  void didUpdateWidget(covariant PayerSelectionWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    // If the parent cleared the selection entirely, clear our flag.
    if (widget.selectedPayers.isEmpty) {
      _isAllExplicitlySelected = false;
    }
  }

  void _togglePlayer(String player) {
    final wasAllSelected = _isAllExplicitlySelected && widget.selectedPayers.length == widget.allPlayers.length;
    setState(() => _isAllExplicitlySelected = false);

    if (wasAllSelected) {
      // Since individual rows look "unselected" when All is active, 
      // tapping one should select ONLY that player.
      widget.onChanged([player]);
      return;
    }

    final List<String> newSelection = List.from(widget.selectedPayers);
    if (newSelection.contains(player)) {
      newSelection.remove(player);
    } else {
      newSelection.add(player);
    }
    
    widget.onChanged(newSelection);
  }

  void _toggleAll() {
    // If they click 'All', we explicitly activate the visual 'All' state.
    setState(() => _isAllExplicitlySelected = true);
    widget.onChanged(List.from(widget.allPlayers));
  }

  Widget _buildOptionTile(
    BuildContext context, {
    required String title,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    final theme = Theme.of(context);
    const highlightColor = Colors.red;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Material(
        color: isSelected 
            ? highlightColor.withValues(alpha: 0.15)
            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: isSelected 
                  ? Border.all(color: highlightColor.withValues(alpha: 0.5), width: 1.5)
                  : Border.all(color: Colors.transparent, width: 1.5),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.person_outline, 
                  color: isSelected ? highlightColor : theme.colorScheme.onSurfaceVariant,
                  size: 22,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Row(
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                          color: isSelected ? highlightColor : theme.colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  const Icon(
                    Icons.check_circle,
                    color: highlightColor,
                    size: 20,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAllSelected = _isAllExplicitlySelected && widget.selectedPayers.length == widget.allPlayers.length && widget.allPlayers.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(widget.title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          _buildOptionTile(
            context,
            title: 'All',
            isSelected: isAllSelected,
            onTap: _toggleAll,
          ),
          ...widget.allPlayers.map((player) {
            // If "All" is explicitly selected, visually unselect the individual rows.
            // Otherwise, show their true individual selection status.
            final isSelected = !isAllSelected && widget.selectedPayers.contains(player);
            return _buildOptionTile(
              context,
              title: player,
              isSelected: isSelected,
              onTap: () => _togglePlayer(player),
            );
          }),
          if (widget.onAddPlayer != null) ...[
            const SizedBox(height: 8),
            TextButton.icon(
              onPressed: widget.onAddPlayer,
              icon: const Icon(Icons.person_add),
              label: const Text('Add Player to Bill'),
              style: TextButton.styleFrom(
                alignment: Alignment.center,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
