import re

with open('lib/features/dashboard/presentation/screens/dashboard_screen.dart', 'r', encoding='utf-8') as f:
    content = f.read()

import_statement = '''import 'package:snooker_club/features/dashboard/presentation/widgets/financial_summary_card.dart';
import 'package:snooker_club/core/routes/route_names.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_club/features/bookings/data/bookings_repository.dart';
import 'package:snooker_club/features/bookings/domain/models/booking_models.dart';'''

content = content.replace("import 'package:snooker_club/features/dashboard/presentation/widgets/financial_summary_card.dart';", import_statement)

card_injection = '''                ),
                const Gap(16),
                
                // --- NEW BOOKING CARD ---
                _BookingsDashboardCard(),
                
                const Gap(16),
                GridView.count('''

# Replace GridView.count with card_injection
content = re.sub(r'                \),\s*const Gap\(16\),\s*GridView\.count\(', card_injection, content)

card_widget = '''
class _BookingsDashboardCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final activeBookingsAsync = ref.watch(dateBookingsStreamProvider(DateTime.now())); // Just getting today's bookings for the badge

    return InkWell(
      onTap: () => context.push(RouteNames.bookings),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: theme.colorScheme.outlineVariant),
          boxShadow: [
            BoxShadow(
              color: AppColors.error.withOpacity(0.1),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ]
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_month, color: AppColors.error),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Bookings', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  activeBookingsAsync.when(
                    data: (bookings) {
                      final pendingCount = bookings.where((b) => b.status == BookingStatus.pending).length;
                      if (pendingCount > 0) {
                        return Text('$pendingCount pending requests', style: theme.textTheme.bodySmall?.copyWith(color: AppColors.error, fontWeight: FontWeight.bold));
                      }
                      return Text('Manage table reservations', style: theme.textTheme.bodySmall);
                    },
                    loading: () => Text('Loading...', style: theme.textTheme.bodySmall),
                    error: (_, __) => Text('Manage table reservations', style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    );
  }
}

class _ModuleCard extends StatelessWidget {'''

content = content.replace("class _ModuleCard extends StatelessWidget {", card_widget)

with open('lib/features/dashboard/presentation/screens/dashboard_screen.dart', 'w', encoding='utf-8') as f:
    f.write(content)
