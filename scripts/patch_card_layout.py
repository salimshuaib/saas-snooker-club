import sys
import re

path = 'lib/features/games/presentation/widgets/game_activity_card.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Conditionally hide the top right history button
old_history_icon = '''                IconButton(
                  onPressed: () {
                    AppModal.showBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      builder: (_) => TableHistorySheet(table: table),
                    );
                  },
                  icon: const Icon(Icons.history, size: 22),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  tooltip: 'History',
                ),'''

new_history_icon = '''                if (!isAvailable)
                  IconButton(
                    onPressed: () {
                      AppModal.showBottomSheet(
                        context: context,
                        isScrollControlled: true,
                        builder: (_) => TableHistorySheet(table: table),
                      );
                    },
                    icon: const Icon(Icons.history, size: 22),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    tooltip: 'History',
                  ),'''

content = content.replace(old_history_icon, new_history_icon)

# 2. Change Manual button to a Row with Manual and History
old_manual_button = '''                  OutlinedButton.icon(
                    onPressed: () {
                      final employeeId = ref.read(currentStaffProvider).value?.id ?? '';
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => ManualGameSetupScreen(
                            employeeId: employeeId,
                            isCompletedGame: false,
                            initialTable: table,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.edit_document, size: 18),
                    label: const Text('Manual'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),'''

new_manual_button = '''                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            final employeeId = ref.read(currentStaffProvider).value?.id ?? '';
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => ManualGameSetupScreen(
                                  employeeId: employeeId,
                                  isCompletedGame: false,
                                  initialTable: table,
                                ),
                              ),
                            );
                          },
                          icon: const Icon(Icons.edit_document, size: 18),
                          label: const Text('Manual', overflow: TextOverflow.ellipsis, maxLines: 1),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                      const Gap(12),
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            AppModal.showBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => TableHistorySheet(table: table),
                            );
                          },
                          icon: const Icon(Icons.history, size: 18),
                          label: const Text('History', overflow: TextOverflow.ellipsis, maxLines: 1),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),'''

content = content.replace(old_manual_button, new_manual_button)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched game_activity_card.dart layout')
