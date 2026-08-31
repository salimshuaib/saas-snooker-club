import re

with open('lib/features/bookings/presentation/screens/booking_management_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("final link = 'https://saas-snooker-club.web.app/?club=';", "final link = 'https://saas-snooker-club.web.app/?club=\';")
content = content.replace("Text('Copied: ');", "Text('Copied: \');")

with open('lib/features/bookings/presentation/screens/booking_management_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
