import sys

path = 'lib/features/games/presentation/screens/game_activity_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_code = '''                                    Builder(
                                      builder: (innerContext) => _StatusBadge(
                                        label: 'Running',
                                        count: tables.where((t) => t.status == TableStatus.running || t.status == TableStatus.paused).length,
                                        color: AppColors.running,
                                        onTap: () => _showTablesList('''

new_code = '''                                    Builder(
                                      builder: (innerContext) {
                                        final notSureCount = tables.where((t) => (t.status == TableStatus.running || t.status == TableStatus.paused) && t.isTimeNotSure).length;
                                        if (notSureCount == 0) return const SizedBox.shrink();
                                        return Padding(
                                          padding: const EdgeInsets.only(right: 8.0),
                                          child: _StatusBadge(
                                            label: 'Not Sure',
                                            count: notSureCount,
                                            color: Colors.red,
                                            onTap: () => _showTablesList(
                                              innerContext,
                                              'All Tables',
                                              'Not Sure Games',
                                              tables.where((t) => (t.status == TableStatus.running || t.status == TableStatus.paused) && t.isTimeNotSure).toList(),
                                              allTables: tables,
                                              existingTypes: existingTypes,
                                              snookerTables: snookerTables,
                                              poolTables: poolTables,
                                              consoleTables: consoleTables,
                                              otherTables: otherTables,
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                    Builder(
                                      builder: (innerContext) => _StatusBadge(
                                        label: 'Running',
                                        count: tables.where((t) => t.status == TableStatus.running || t.status == TableStatus.paused).length,
                                        color: AppColors.running,
                                        onTap: () => _showTablesList('''

content = content.replace(old_code, new_code)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)

print('Patched game_activity_screen.dart')
