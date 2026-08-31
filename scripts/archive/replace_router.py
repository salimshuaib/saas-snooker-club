with open('lib/core/routes/app_router.dart', 'r', encoding='utf-8') as f:
    content = f.read()

content = content.replace('''      GoRoute(
        path: RouteNames.games,''', '''      GoRoute(
        path: RouteNames.bookings,
        builder: (context, state) => const TickerMode(enabled: true, child: BookingManagementScreen()),
      ),
      GoRoute(
        path: RouteNames.games,''')

with open('lib/core/routes/app_router.dart', 'w', encoding='utf-8') as f:
    f.write(content)
