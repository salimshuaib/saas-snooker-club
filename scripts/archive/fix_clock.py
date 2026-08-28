import re

def fix_clock():
    path = 'lib/features/dashboard/presentation/screens/dashboard_screen.dart'
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # 1. Remove it from build method
    old_build_start = """  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    
    // Get actual staff member from state
    final currentStaff = ref.watch(currentStaffProvider).value;
    final employeeName = currentStaff?.name ?? 'Admin User';
    
    // Watch real time clock
    final now = ref.watch(realTimeClockProvider).value ?? DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);
    final timeStr = DateFormat('h:mm a').format(now);

    return Scaffold("""
    
    new_build_start = """  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final currency = ref.watch(currencyProvider);
    
    // Get actual staff member from state
    final currentStaff = ref.watch(currentStaffProvider).value;
    final employeeName = currentStaff?.name ?? 'Admin User';

    return Scaffold("""
    content = content.replace(old_build_start, new_build_start)

    # 2. Replace the Date/Time display in the UI
    old_date_time = """                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          dateStr,
                          style: theme.textTheme.labelMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          timeStr,
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),"""
    
    new_date_time = """                    const _RealTimeClockWidget(),"""
    content = content.replace(old_date_time, new_date_time)
    
    # 3. Add _RealTimeClockWidget
    clock_widget = """

class _RealTimeClockWidget extends ConsumerWidget {
  const _RealTimeClockWidget();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final now = ref.watch(realTimeClockProvider).value ?? DateTime.now();
    final dateStr = DateFormat('EEEE, MMMM d').format(now);
    final timeStr = DateFormat('h:mm a').format(now);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          dateStr,
          style: theme.textTheme.labelMedium?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        Text(
          timeStr,
          style: theme.textTheme.titleMedium?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}"""
    content += clock_widget

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_clock()
