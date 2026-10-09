import sys

path = 'lib/features/games/presentation/widgets/active_game_card.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_button = """        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
                  minimumSize: const Size(0, 36),
                  backgroundColor: Colors.orange.withOpacity(0.15),
                  foregroundColor: Colors.orange.shade700,
                ),
                icon: const Icon(Icons.pending_actions, size: 16),
                label: const Text(
                  'Mark as Pending',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                onPressed: () => _handleMarkAsPending(game, context),
              ),
            ),
          ],
        ),"""

new_buttons = """        Row(
          children: [
            Expanded(
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  minimumSize: const Size(0, 36),
                ),
                icon: const Icon(Icons.edit_document, size: 16),
                label: const Text(
                  'Manual Entry',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () {
                  final employeeId = ref.read(currentStaffProvider).value?.id ?? '';
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => ManualGameSetupScreen(
                        employeeId: employeeId,
                        isCompletedGame: true,
                        initialTable: widget.table,
                      ),
                    ),
                  );
                },
              ),
            ),
            const Gap(8),
            Expanded(
              child: FilledButton.tonalIcon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
                  minimumSize: const Size(0, 36),
                  backgroundColor: Colors.orange.withOpacity(0.15),
                  foregroundColor: Colors.orange.shade700,
                ),
                icon: const Icon(Icons.pending_actions, size: 16),
                label: const Text(
                  'Pending Bill',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                onPressed: () => _handleMarkAsPending(game, context),
              ),
            ),
          ],
        ),"""

if old_button in content:
    content = content.replace(old_button, new_buttons)
    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)
    print("Replaced successfully!")
else:
    print("WARNING: Could not find old_button.")
