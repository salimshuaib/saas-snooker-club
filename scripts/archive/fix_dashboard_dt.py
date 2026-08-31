import re

with open('lib/features/dashboard/presentation/screens/dashboard_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("final activeBookingsAsync = ref.watch(dateBookingsStreamProvider(DateTime.now()));", 
'''final now = DateTime.now();
    final activeBookingsAsync = ref.watch(dateBookingsStreamProvider(DateTime(now.year, now.month, now.day)));''')

with open('lib/features/dashboard/presentation/screens/dashboard_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
