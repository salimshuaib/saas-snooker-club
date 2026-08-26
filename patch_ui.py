import os

def patch_ui():
    path = 'lib/features/games/presentation/screens/table_details_screen.dart'
    if not os.path.exists(path):
        return
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()
        
    old_end_game = """          const Gap(8),
          // End Game
          SizedBox(
            width: double.infinity,
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
          ),"""
          
    new_end_game = """          const Gap(8),
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
          
    content = content.replace(old_end_game, new_end_game)
    
    if 'Future<void> _handleCancelGame' not in content:
        old_show = "  Future<void> _showOrdersSheet(GameSession game, BuildContext context) async {"
        new_show = """  Future<void> _handleCancelGame(GameSession game, BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Game?'),
        content: const Text('Are you sure you want to cancel this game? This will free the table and delete the game record.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
            child: const Text('Yes, Cancel'),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted || !context.mounted) return;

    await ref
        .read(gameSessionControllerProvider.notifier)
        .cancelGame(game.id, game.tableId, game.orders);
        
    if (mounted && context.mounted) {
       Navigator.of(context).pop();
       ScaffoldMessenger.of(context).showSnackBar(
         const SnackBar(content: Text('Game cancelled successfully'), backgroundColor: AppColors.success),
       );
    }
  }

  Future<void> _showOrdersSheet(GameSession game, BuildContext context) async {"""
        content = content.replace(old_show, new_show)
        
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    patch_ui()
