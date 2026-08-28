import re

# 1. Update credit_providers.dart
with open('lib/features/credit/providers/credit_providers.dart', 'r', encoding='utf-8') as f:
    prov_code = f.read()

new_logic = '''
class CustomerSelectionNotifier extends Notifier<Set<String>> {
  @override
  Set<String> build() => {};
  
  void toggle(String id) {
    if (state.contains(id)) {
      state = {...state}..remove(id);
    } else {
      state = {...state}..add(id);
    }
  }
  
  void clear() => state = {};
}

final customerSelectionProvider = NotifierProvider<CustomerSelectionNotifier, Set<String>>(CustomerSelectionNotifier.new);

  Future<void> deleteMultipleCustomers(Set<String> customerIds) async {
    state = const AsyncValue.loading();
    try {
      final repo = ref.read(creditRepositoryProvider);
      for (final id in customerIds) {
        await repo.deletePlayerProfile(id);
      }
      state = const AsyncValue.data(null);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }
'''
if 'CustomerSelectionNotifier' not in prov_code:
    prov_code = prov_code.replace('  Future<void> deleteCustomer(String customerId) async {', new_logic + '\n  Future<void> deleteCustomer(String customerId) async {')
    with open('lib/features/credit/providers/credit_providers.dart', 'w', encoding='utf-8') as f:
        f.write(prov_code)

# 2. Update credit_screen.dart
with open('lib/features/credit/presentation/screens/credit_screen.dart', 'r', encoding='utf-8') as f:
    screen = f.read()

# Add dart:async if not there
if 'dart:async' not in screen:
    screen = 'import \'dart:async\';\n' + screen
if 'package:flutter/services.dart' not in screen:
    screen = 'import \'package:flutter/services.dart\';\n' + screen


app_bar_old = '''        appBar: AppBar(
          title: const Text('Player Profile'),
          actions: [
            Consumer(
              builder: (context, ref, child) {
                return IconButton(
                  icon: const Icon(Icons.merge_type),
                  tooltip: 'Merge Customers',
                  onPressed: () => _showMergeDialog(context, ref),
                );
              },
            ),
          ],
        ),'''

app_bar_new = '''        appBar: AppBar(
          leading: ref.watch(customerSelectionProvider).isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => ref.read(customerSelectionProvider.notifier).clear(),
                )
              : null,
          title: Text(ref.watch(customerSelectionProvider).isNotEmpty
              ? ' Selected'
              : 'Player Profile'),
          actions: [
            if (ref.watch(customerSelectionProvider).isNotEmpty)
              IconButton(
                icon: const Icon(Icons.delete, color: AppColors.error),
                onPressed: () async {
                  final selectedIds = ref.read(customerSelectionProvider);
                  final verified = await AdminPasscodeDialog.verify(
                    context, ref,
                    subtitle: 'Enter administrator passcode to delete  profile(s).',
                  );
                  if (verified != true || !context.mounted) return;
                  
                  final confirm = await showDialog<bool>(
                    context: context,
                    builder: (ctx) => AlertDialog(
                      title: const Text('Delete Profiles?'),
                      content: Text('Are you sure you want to completely delete  player(s) and all their credit history? This cannot be undone.'),
                      actions: [
                        TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                        FilledButton(
                          onPressed: () => Navigator.pop(ctx, true),
                          style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                          child: const Text('DELETE'),
                        ),
                      ],
                    ),
                  );
                  if (confirm == true) {
                    await ref.read(creditControllerProvider.notifier).deleteMultipleCustomers(selectedIds);
                    ref.read(customerSelectionProvider.notifier).clear();
                  }
                },
              )
            else
              Consumer(
                builder: (context, ref, child) {
                  return IconButton(
                    icon: const Icon(Icons.merge_type),
                    tooltip: 'Merge Customers',
                    onPressed: () => _showMergeDialog(context, ref),
                  );
                },
              ),
          ],
        ),'''

screen = screen.replace(app_bar_old, app_bar_new)

# Replace _CustomerCard
card_old = '''class _CustomerCard extends ConsumerWidget {
  final PlayerProfile customer;
  final Currency currency;

  const _CustomerCard({required this.customer, required this.currency});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dtFmt = DateFormat('MMM d, yyyy');

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: theme.colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: () {
          // Navigate to details
          context.push('/more/credit/details', extra: customer);
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                radius: 24,
                child: Text(
                  customer.name.isNotEmpty ? customer.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Gap(4),
                    Text(
                      'Last updated: \',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        CurrencyHelper.formatWhole(customer.outstandingAmount, currency),
                        style: theme.textTheme.titleMedium?.copyWith(
                          color: AppColors.error,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(4),
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: AppColors.error, size: 20),
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                        onPressed: () async {
                          final verified = await AdminPasscodeDialog.verify(
                            context, ref,
                            subtitle: 'Enter administrator passcode to delete this player profile.',
                          );
                          if (verified != true || !context.mounted) return;
                          
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete Player?'),
                              content: Text('Are you sure you want to completely delete \ and all their credit history? This cannot be undone.'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('CANCEL')),
                                FilledButton(
                                  onPressed: () => Navigator.pop(ctx, true),
                                  style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                                  child: const Text('DELETE'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true) {
                            ref.read(creditControllerProvider.notifier).deleteCustomer(customer.id);
                          }
                        },
                      ),
                    ],
                  ),
                  const Gap(4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: customer.outstandingAmount > 0 ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      customer.outstandingAmount > 0 ? 'Outstanding' : 'Cleared',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: customer.outstandingAmount > 0 ? AppColors.error : AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}'''

card_new = '''class _CustomerCard extends ConsumerStatefulWidget {
  final PlayerProfile customer;
  final Currency currency;

  const _CustomerCard({required this.customer, required this.currency});

  @override
  ConsumerState<_CustomerCard> createState() => _CustomerCardState();
}

class _CustomerCardState extends ConsumerState<_CustomerCard> {
  Timer? _timer;
  bool _longPressTriggered = false;

  void _startTimer() {
    final isSelectionMode = ref.read(customerSelectionProvider).isNotEmpty;
    if (isSelectionMode) return;
    
    _timer = Timer(const Duration(seconds: 3), () {
      HapticFeedback.heavyImpact();
      _longPressTriggered = true;
      ref.read(customerSelectionProvider.notifier).toggle(widget.customer.id);
    });
  }

  void _cancelTimer() {
    _timer?.cancel();
    _timer = null;
  }

  @override
  void dispose() {
    _cancelTimer();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final dtFmt = DateFormat('MMM d, yyyy');
    final isSelected = ref.watch(customerSelectionProvider).contains(widget.customer.id);
    final isSelectionMode = ref.watch(customerSelectionProvider).isNotEmpty;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      color: isSelected ? theme.colorScheme.primaryContainer.withValues(alpha: 0.4) : theme.colorScheme.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: isSelected ? theme.colorScheme.primary : theme.colorScheme.outlineVariant, width: isSelected ? 2 : 1),
      ),
      child: InkWell(
        onTapDown: (_) => _startTimer(),
        onTapCancel: () => _cancelTimer(),
        onTap: () {
          _cancelTimer();
          if (_longPressTriggered) {
            _longPressTriggered = false;
            return;
          }
          if (isSelectionMode) {
            ref.read(customerSelectionProvider.notifier).toggle(widget.customer.id);
          } else {
            context.push('/more/credit/details', extra: widget.customer);
          }
        },
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              if (isSelectionMode)
                Padding(
                  padding: const EdgeInsets.only(right: 12),
                  child: Icon(
                    isSelected ? Icons.check_circle : Icons.radio_button_unchecked,
                    color: isSelected ? theme.colorScheme.primary : theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              CircleAvatar(
                backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                radius: 24,
                child: Text(
                  widget.customer.name.isNotEmpty ? widget.customer.name[0].toUpperCase() : '?',
                  style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.bold, fontSize: 20),
                ),
              ),
              const Gap(16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.customer.name,
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Gap(4),
                    Text(
                      'Last updated: \',
                      style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    CurrencyHelper.formatWhole(widget.customer.outstandingAmount, widget.currency),
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: widget.customer.outstandingAmount > 0 ? AppColors.error.withValues(alpha: 0.1) : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.customer.outstandingAmount > 0 ? 'Outstanding' : 'Cleared',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: widget.customer.outstandingAmount > 0 ? AppColors.error : AppColors.success,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}'''

screen = screen.replace(card_old, card_new)

with open('lib/features/credit/presentation/screens/credit_screen.dart', 'w', encoding='utf-8') as f:
    f.write(screen)
