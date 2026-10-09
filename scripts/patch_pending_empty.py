import sys

path = 'lib/features/games/presentation/screens/pending_bills_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

old_list = '''              Expanded(
                child: ListView.builder('''

new_list = '''              Expanded(
                child: grouped.isEmpty 
                  ? Center(
                      child: Text(
                        'No pending bills for this date.',
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    )
                  : ListView.builder('''

content = content.replace(old_list, new_list)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched empty state in pending_bills_screen.dart')
