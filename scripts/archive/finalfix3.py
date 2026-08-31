with open('lib/features/bookings/presentation/screens/booking_management_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("final link = 'https://saas-snooker-club.web.app/?club=' + chr(36) + '{linkIdentifier}';", "final link = 'https://saas-snooker-club.web.app/?club=" + chr(36) + "{linkIdentifier}';")

with open('lib/features/bookings/presentation/screens/booking_management_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
