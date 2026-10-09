import sys

path = 'lib/features/games/presentation/widgets/active_game_card.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# Replace the beginning of _handleMarkAsPending
old_code = '''  Future<void> _handleMarkAsPending(GameSession game, BuildContext context) async {
    showModalBottomSheet('''

new_code = '''  Future<void> _handleMarkAsPending(GameSession game, BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Mark as Pending?'),
        content: const Text(
          'Are you willing to end this game and mark payment as pending?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('No'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: FilledButton.styleFrom(backgroundColor: Colors.orange),
            child: const Text('Yes'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    if (!context.mounted) return;

    showModalBottomSheet('''

content = content.replace(old_code, new_code)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched _handleMarkAsPending in active_game_card.dart')
