import re

path = r'C:\Users\Shuai\Desktop\Saas Snooker Club\lib\features\games\presentation\screens\table_details_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# I want to replace everything from             Container( under if (needsLoserSelect)
# until the end of the _RoundCompletionDialogState class

target = '''            Container(
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
                      'Winner: \\nLoser (Pays): ',
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

replacement = '''            Container(
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

content = content.replace(target, replacement)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
