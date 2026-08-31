import re

with open('lib/features/bookings/presentation/screens/booking_management_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

# Replace DateTime.now() initialization with normalized date
content = content.replace("DateTime _selectedDate = DateTime.now();", 
'''DateTime _selectedDate = DateTime(DateTime.now().year, DateTime.now().month, DateTime.now().day);''')

with open('lib/features/bookings/presentation/screens/booking_management_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
