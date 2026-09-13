import re

filepath = 'lib/features/dashboard/presentation/screens/dashboard_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Replace _StatCard
stat_card_start = text.find('class _StatCard extends StatelessWidget {')
if stat_card_start != -1:
    stat_card_end = text.find('class _BookingsDashboardCard', stat_card_start)
    if stat_card_end == -1: stat_card_end = text.find('class _ModuleCard', stat_card_start)
    if stat_card_end == -1: stat_card_end = len(text)
    
    # Actually wait, _StatCard might be at the end.
    
    # Let's just find the exact block for _StatCard
    match = re.search(r'class _StatCard extends StatelessWidget \{.*?\n\}\n', text, re.DOTALL)
    if match:
        old_stat = match.group(0)
        new_stat = """class _StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;

  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.iconColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width > 800;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isDesktop ? 4 : 16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDesktop ? const Color(0xFF15191E) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(isDesktop ? 4 : 16),
          border: Border.all(
            color: isDesktop ? const Color(0xFF2C353F) : theme.colorScheme.outlineVariant, 
            width: 1
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: isDesktop ? 20 : 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.labelMedium?.copyWith(
                      color: isDesktop ? const Color(0xFF94A3B8) : theme.colorScheme.onSurfaceVariant,
                      letterSpacing: isDesktop ? 1.1 : null,
                      fontWeight: FontWeight.bold,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              value,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: isDesktop ? Colors.white : theme.colorScheme.onSurface,
                fontFamily: isDesktop ? 'monospace' : null,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
"""
        text = text.replace(old_stat, new_stat)
        print("Replaced _StatCard")

# 2. Replace _BookingsDashboardCard
match = re.search(r'class _BookingsDashboardCard extends ConsumerWidget \{.*?\n\}\n\}', text, re.DOTALL)
if match:
    old_booking = match.group(0)
    new_booking = """class _BookingsDashboardCard extends ConsumerWidget {
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
    text = text.replace(old_booking, new_booking)
    print("Replaced _BookingsDashboardCard")
else:
    print("Failed to replace _BookingsDashboardCard")

# 3. Replace _ModuleCard
match = re.search(r'class _ModuleCard extends StatelessWidget \{.*?\n\}\n\}', text, re.DOTALL)
if match:
    old_module = match.group(0)
    new_module = """class _ModuleCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String description;
  final Color color;
  final VoidCallback onTap;

  const _ModuleCard({
    required this.icon,
    required this.label,
    required this.description,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktop = MediaQuery.sizeOf(context).width > 800;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(isDesktop ? 4 : 16),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isDesktop ? const Color(0xFF1A2026) : theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(isDesktop ? 4 : 16),
          border: Border.all(color: isDesktop ? const Color(0xFF2C353F) : theme.colorScheme.outlineVariant),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(isDesktop ? 4 : 10),
                  ),
                  child: Icon(icon, color: color, size: 22),
                ),
                Icon(
                  Icons.arrow_forward,
                  color: isDesktop ? Colors.grey : theme.colorScheme.onSurfaceVariant.withOpacity(0.5),
                  size: 20,
                ),
              ],
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: theme.textTheme.titleSmall?.copyWith(color: isDesktop ? Colors.white : null)),
                Text(
                  description,
                  style: theme.textTheme.labelSmall?.copyWith(
                    color: isDesktop ? const Color(0xFF94A3B8) : theme.colorScheme.onSurfaceVariant,
                    fontSize: 10,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}"""
    text = text.replace(old_module, new_module)
    print("Replaced _ModuleCard")
else:
    print("Failed to replace _ModuleCard")

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
print("ALL DONE")
