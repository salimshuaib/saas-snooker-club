import re

with open('lib/features/dashboard/presentation/screens/dashboard_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

card_injection = '''              const Gap(16),
              
              // --- NEW BOOKING CARD ---
              _BookingsDashboardCard(),
              
              const Gap(16),
              GridView.count('''

content = content.replace("              const Gap(16),\n              GridView.count(", card_injection)
content = content.replace("              const Gap(16),\r\n              GridView.count(", card_injection)
content = content.replace("              const Gap(16),\n                GridView.count(", card_injection)
content = content.replace("              const Gap(16),\r\n                GridView.count(", card_injection)

# Just to be sure, let's use a simpler replace
content = content.replace("                const Gap(16),\n                GridView.count(", '''                const Gap(16),
                _BookingsDashboardCard(),
                const Gap(16),
                GridView.count(''')
content = content.replace("                const Gap(16),\r\n                GridView.count(", '''                const Gap(16),
                _BookingsDashboardCard(),
                const Gap(16),
                GridView.count(''')

with open('lib/features/dashboard/presentation/screens/dashboard_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
