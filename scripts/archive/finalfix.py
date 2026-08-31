with open('lib/features/bookings/presentation/screens/booking_management_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('https://saas-snooker-club.web.app/?club=;', 'https://saas-snooker-club.web.app/?club=' + chr(36) + '{linkIdentifier};')
content = content.replace('Copied: ', 'Copied: ' + chr(36) + 'link')

with open('lib/features/bookings/presentation/screens/booking_management_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
