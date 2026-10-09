import sys

path = 'lib/features/games/presentation/screens/game_activity_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_code = '''                          Text(
                            table.status.displayName.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: table.status == TableStatus.available
                                  ? AppColors.available
                                  : AppColors.running,
                              fontWeight: FontWeight.bold,
                            ),
                          ),'''

new_code = '''                          Text(
                            table.isTimeNotSure 
                                ? 'NOT SURE' 
                                : table.status.displayName.toUpperCase(),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: table.isTimeNotSure
                                  ? Colors.red
                                  : (table.status == TableStatus.available
                                      ? AppColors.available
                                      : (table.status == TableStatus.paused 
                                          ? AppColors.paused 
                                          : AppColors.running)),
                              fontWeight: FontWeight.bold,
                            ),
                          ),'''

content = content.replace(old_code, new_code)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched _showTablesList')
