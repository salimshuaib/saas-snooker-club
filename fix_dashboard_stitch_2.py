import os
import re

filepath = 'lib/features/dashboard/presentation/screens/dashboard_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

# Let's add a darker, sharper container for the stats cards.
booking_card = """class _BookingsDashboardCard extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = DateTime.now();
    final activeBookingsAsync = ref.watch(
      dateBookingsStreamProvider(DateTime(now.year, now.month, now.day)),
    ); 
    final isDesktop = MediaQuery.sizeOf(context).width > 800;

    return InkWell(
      onTap: () => context.push(RouteNames.bookings),
      borderRadius: BorderRadius.circular(isDesktop ? 4 : 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDesktop ? const Color(0xFF15191E) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(isDesktop ? 4 : 16),
          border: Border.all(color: isDesktop ? const Color(0xFF3E4A56) : theme.colorScheme.outlineVariant),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.error.withOpacity(0.1),
                borderRadius: BorderRadius.circular(isDesktop ? 4 : 50),
              ),
              child: const Icon(Icons.calendar_month, color: AppColors.error),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Reservations & Bookings',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: isDesktop ? Colors.white : null,
                    ),
                  ),
                  const SizedBox(height: 4),
                  activeBookingsAsync.when(
                    data: (bookings) {
                      final pendingCount = bookings.where((b) => b.status == BookingStatus.pending).length;
                      if (pendingCount > 0) {
                        return Text(
                          '$pendingCount PENDING REQUESTS',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: AppColors.error,
                            fontWeight: FontWeight.bold,
                            letterSpacing: isDesktop ? 1.2 : null,
                          ),
                        );
                      }
                      return Text('Manage table reservations', style: theme.textTheme.bodySmall?.copyWith(color: isDesktop ? Colors.grey : null));
                    },
                    loading: () => Text('...', style: theme.textTheme.bodySmall),
                    error: (_, __) => Text('Error', style: theme.textTheme.bodySmall),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Colors.grey),
          ],
        ),
      ),
    );
  }
}"""

text = re.sub(r'class _BookingsDashboardCard extends ConsumerWidget \{.*?\n\}\n\}', booking_card + '\n', text, flags=re.DOTALL)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
print("SUCCESS")
