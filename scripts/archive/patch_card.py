with open('lib/features/credit/presentation/screens/credit_screen.dart', 'r', encoding='utf-8') as f:
    code = f.read()

part1 = 'class _CustomerCard extends ConsumerWidget {'
card_idx = code.find(part1)

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

if card_idx != -1:
    code = code[:card_idx] + card_new
    with open('lib/features/credit/presentation/screens/credit_screen.dart', 'w', encoding='utf-8') as f:
        f.write(code)
    print("Replaced")
else:
    print("Not found")
