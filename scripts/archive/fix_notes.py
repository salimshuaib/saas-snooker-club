import re

with open('lib/features/bookings/presentation/screens/booking_management_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("if (booking.notes.isNotEmpty) ...[", "if (booking.notes != null && booking.notes!.isNotEmpty) ...[")

with open('lib/features/bookings/presentation/screens/booking_management_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
