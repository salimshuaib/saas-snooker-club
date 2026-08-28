import re

def replace_block(file_path):
    with open(file_path, 'r', encoding='utf-8') as f:
        content = f.read()

    start_str = "class _TeamPlayerFields extends StatelessWidget {"
    start_idx = content.find(start_str)
    if start_idx == -1:
        print("Could not find _TeamPlayerFields")
        return

    # Find the end of _TeamPlayerFields
    brace_count = 0
    end_idx = -1
    for i in range(start_idx + len(start_str) - 1, len(content)):
        if content[i] == '{':
            brace_count += 1
        elif content[i] == '}':
            brace_count -= 1
            if brace_count == 0:
                end_idx = i
                break
                
    if end_idx == -1:
        print("Could not find end of _TeamPlayerFields")
        return

    new_class = """class _TeamPlayerFields extends StatefulWidget {
  final String teamLabel;
  final List<PlayerSelection?> selections;
  final void Function(int, PlayerSelection) onChange;
  final VoidCallback onAdd;
  final void Function(int index) onRemove;

  const _TeamPlayerFields({
    required this.teamLabel,
    required this.selections,
    required this.onChange,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  State<_TeamPlayerFields> createState() => _TeamPlayerFieldsState();
}

class _TeamPlayerFieldsState extends State<_TeamPlayerFields> {
  bool _isExpanded = true;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    // Check max from label, eg "Team A (Max 5)"
    int maxPlayers = 5;
    if (widget.teamLabel.contains('10')) maxPlayers = 10;
    
    final labelCount = '${widget.teamLabel.split(' (')[0]} (${widget.selections.length}/$maxPlayers)';

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5)),
      ),
      child: Theme(
        data: theme.copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          initiallyExpanded: _isExpanded,
          onExpansionChanged: (val) => setState(() => _isExpanded = val),
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
          title: Text(
            labelCount,
            style: theme.textTheme.labelLarge?.copyWith(fontWeight: FontWeight.w700),
          ),
          childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          children: [
            ...List.generate(widget.selections.length, (i) {
              return Padding(
                key: ValueKey('player_field_$i'),
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: PlayerSearchField(
                        key: ValueKey('search_$i'),
                        hint: 'Player ${i + 1}',
                        onSelected: (val) => widget.onChange(i, val),
                      ),
                    ),
                    if (widget.selections.length > 1) ...[
                      const Gap(8),
                      IconButton(
                        icon: const Icon(Icons.remove_circle_outline),
                        onPressed: () => widget.onRemove(i),
                        color: AppColors.error,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                    ],
                  ],
                ),
              );
            }),
            if (widget.selections.length < maxPlayers)
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton.icon(
                  onPressed: widget.onAdd,
                  icon: const Icon(Icons.add, size: 20),
                  label: const Text('Add Player'),
                  style: TextButton.styleFrom(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}"""

    content = content[:start_idx] + new_class + content[end_idx+1:]
    with open(file_path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Successfully replaced _TeamPlayerFields")

if __name__ == "__main__":
    replace_block("lib/features/games/presentation/widgets/game_setup_sheet.dart")
