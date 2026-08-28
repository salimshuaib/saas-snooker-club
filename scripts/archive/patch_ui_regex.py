import os

path = 'lib/features/games/presentation/screens/table_details_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import re

pattern = r"        const Gap\(8\),\n        // End Game\n        SizedBox\([\s\S]*?        \),"

def replacer(match):
    return """        const Gap(8),
        Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton.icon(
                onPressed: () => _handleCancelGame(game, context),
                icon: const Icon(Icons.cancel_outlined, color: AppColors.error),
                label: const Text('Cancel', style: TextStyle(color: AppColors.error)),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.error),
                ),
              ),
            ),
            const Gap(8),
            Expanded(
              flex: 2,
              child: FilledButton.icon(
                onPressed: () => _handleEndGame(game, context),
                icon: const Icon(Icons.flag),
                label: Text(
                  game.billingType == BillingType.perFrame
                      ? (game.matchType == MatchType.loserPays
                            ? 'Finish Round ${game.rounds.length + 1}'
                            : 'Finish Frame ${game.framesPlayed + 1}')
                      : 'End Game',
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.creditStatus,
                ),
              ),
            ),
          ],
        ),"""

new_content = re.sub(pattern, replacer, content)

with open(path, 'w', encoding='utf-8') as f:
    f.write(new_content)
