missing_code = r'''
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tables = ref.watch(resolvedTablesProvider);
    final stepTitles = ['Select Table', 'Start Time', 'Players', 'Billing', 'Frame Setup'];
    
    final isPerFrame = _gameType == GameType.standard && _billingType == BillingType.perFrame;
    final totalSteps = isPerFrame ? 5 : 4;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCompletedGame ? 'Record Completed Game' : 'Record Ongoing Game'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Step Progress
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: List.generate(totalSteps, (i) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < totalSteps - 1 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: i <= _step ? AppColors.primary : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          Text(
            'Step ${_step + 1} of ${totalSteps} — ${stepTitles[_step]}',
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const Gap(16),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Builder(builder: (context) {
                switch (_step) {
                  case 0: return _buildStep0TableSelection(theme, tables);
                  case 1: return _buildStep1TimeSelection(theme);
                  case 2: return _buildStep2Players(theme);
                  case 3: return _buildStep3Billing(theme);
                  case 4: return _buildStep4Frames(theme);
                  default: return const SizedBox();
                }
              }),
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _step--),
                      child: const Text('Back'),
                    ),
                  ),
                if (_step > 0) const Gap(12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _handleNext,
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_step == totalSteps - 1 ? (widget.isCompletedGame ? 'Generate Bill' : 'Start Game') : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isSelected;

  const _SelectionTile({
    required this.title,
    this.subtitle,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: AppColors.primary, width: 1.5) : Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isSelected ? AppColors.primary : theme.colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const Gap(2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _TeamPlayerFields extends StatelessWidget {
  final String teamLabel;
  final List<PlayerSelection?> selections;
  final void Function(int, PlayerSelection) onChange;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _TeamPlayerFields({
    required this.teamLabel,
    required this.selections,
    required this.onChange,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(teamLabel, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        for (int i = 0; i < selections.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: PlayerSearchField(
                    hint: 'Player ' + (i + 1).toString(),
                    initialSelection: selections[i],
                    onSelected: (val) => onChange(i, val),
                  ),
                ),
                if (selections.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => onRemove(i),
                  ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add Player'),
        ),
      ],
    );
  }
}
'''

with open('lib/features/games/presentation/screens/manual_game_setup_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

if content.strip().endswith('}'):
    content = content[:content.rfind('}')]

with open('lib/features/games/presentation/screens/manual_game_setup_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content + missing_code)
