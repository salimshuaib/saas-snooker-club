import re

path = r'C:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\presentation\screens\table_details_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the whole class _RoundCompletionDialogState
# First let's find it.
start_idx = content.find('class _RoundCompletionDialogState extends State<_RoundCompletionDialog> {')
end_idx = content.find('}\n\nclass _TableStatusChip', start_idx)

if start_idx != -1 and end_idx != -1:
    new_class = '''class _RoundCompletionDialogState extends State<_RoundCompletionDialog> {
  String? _selectedWinner;
  String? _selectedLoser;

  @override
  void initState() {
    super.initState();
    final candidates = widget.game.mode == GameMode.team
        ? ['Team A', 'Team B']
        : widget.game.allPlayers;
    if (candidates.isNotEmpty) {
      _selectWinner(candidates.first);
    }
  }

  void _selectWinner(String winner) {
    setState(() {
      _selectedWinner = winner;
      if (widget.game.mode == GameMode.team) {
        _selectedLoser = winner == 'Team A' ? 'Team B' : 'Team A';
      } else {
        final remaining = widget.game.allPlayers
            .where((p) => p != winner)
            .toList();
        if (remaining.length == 1) {
          _selectedLoser = remaining.first;
        } else if (remaining.isNotEmpty &&
            (_selectedLoser == null || _selectedLoser == winner)) {
          _selectedLoser = remaining.first;
        }
      }
    });
  }

  String _getDisplayName(String id) {
    if (id == 'Team A') return widget.game.teamA.join(' & ');
    if (id == 'Team B') return widget.game.teamB.join(' & ');
    return id;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final candidates = widget.game.mode == GameMode.team
        ? ['Team A', 'Team B']
        : widget.game.allPlayers;
    final needsLoserSelect =
        !widget.isRace && widget.game.mode != GameMode.team && widget.game.allPlayers.length > 2;

    return AlertDialog(
      title: Text(widget.isRace ? 'Game Complete' : 'Round  Complete'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.isRace ? 'Who won this game?' : 'Who won this round?',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Gap(8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: candidates.map((c) {
                final isSel = _selectedWinner == c;
                return ChoiceChip(
                  label: Text(_getDisplayName(c)),
                  selected: isSel,
                  onSelected: (selected) {
                    if (selected) _selectWinner(c);
                  },
                );
              }).toList(),
            ),
            const Gap(16),
            if (needsLoserSelect) ...[
              Text(
                'Who lost this round? (Loser Pays)',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: candidates.where((c) => c != _selectedWinner).map((
                  c,
                ) {
                  final isSel = _selectedLoser == c;
                  return ChoiceChip(
                    label: Text(_getDisplayName(c)),
                    selected: isSel,
                    onSelected: (selected) {
                      if (selected) setState(() => _selectedLoser = c);
                    },
                    selectedColor: AppColors.error.withValues(alpha: 0.2),
                  );
                }).toList(),
              ),
              const Gap(16),
            ],
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.info_outline,
                    size: 20,
                    color: AppColors.primary,
                  ),
                  const Gap(8),
                  Expanded(
                    child: Text(
                      widget.isRace 
                        ? 'Winner: '
                        : 'Winner: \\nLoser (Pays): ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            if (!widget.isRace) ...[
              const Gap(16),
              Text(
                'Play One More Round?',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ],
        ),
      ),
      actions: widget.isRace
          ? [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () {
                  if (_selectedWinner == null) return;
                  Navigator.pop(context, {
                    'winner': _selectedWinner!,
                  });
                },
                child: const Text('Continue to Billing'),
              ),
            ]
          : [
              TextButton(
                onPressed: () {
                  if (_selectedWinner == null || _selectedLoser == null) return;
                  Navigator.pop(context, {
                    'winner': _selectedWinner!,
                    'loser': _selectedLoser!,
                    'continue': false,
                  });
                },
                child: const Text('No, Finish & Bill'),
              ),
              FilledButton(
                onPressed: () {
                  if (_selectedWinner == null || _selectedLoser == null) return;
                  Navigator.pop(context, {
                    'winner': _selectedWinner!,
                    'loser': _selectedLoser!,
                    'continue': true,
                  });
                },
                child: const Text('Yes, Next Round'),
              ),
            ],
    );
  }
}'''
    # We must also replace the class _RoundCompletionDialog constructor to include isRace
    # Let's just write that out too.
    content = content[:start_idx] + new_class + content[end_idx:]

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
