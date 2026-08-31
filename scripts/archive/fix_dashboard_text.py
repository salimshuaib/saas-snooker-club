import re

with open('lib/features/dashboard/presentation/screens/dashboard_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("loading: () => Text('Loading...', style: theme.textTheme.bodySmall),", 
"loading: () => Text('Manage table reservations', style: theme.textTheme.bodySmall),")

with open('lib/features/dashboard/presentation/screens/dashboard_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
