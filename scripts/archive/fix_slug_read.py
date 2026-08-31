with open('lib/features/bookings/presentation/screens/booking_management_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace("final slug = ref.read(appSettingsProvider).business.slug;", "final slug = ref.read(clubProfileProvider).value?.slug;")

with open('lib/features/bookings/presentation/screens/booking_management_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
