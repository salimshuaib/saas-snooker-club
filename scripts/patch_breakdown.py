import sys

path = 'lib/features/games/presentation/screens/combined_settlement_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

# 1. Add getters
getters = '''  double get _totalSelectedAmount {
    return widget.initialBills
        .where((b) => _selectedBillIds.contains(b.id))
        .fold(0.0, (sum, b) => sum + (b.finalAmount ?? b.grandTotal ?? 0.0));
  }

  double get _totalGameCharges {
    return widget.initialBills
        .where((b) => _selectedBillIds.contains(b.id))
        .fold(0.0, (sum, b) => sum + (b.gameCharge ?? 0.0));
  }

  double get _totalOrders {
    return widget.initialBills
        .where((b) => _selectedBillIds.contains(b.id))
        .fold(0.0, (sum, b) => sum + (b.ordersTotal ?? 0.0));
  }

  double get _totalManualGames {
    return widget.initialBills
        .where((b) => _selectedBillIds.contains(b.id))
        .fold(0.0, (sum, b) => sum + b.manualGameCharges.fold<double>(0.0, (s, g) => s + g.calculatedAmount));
  }

  double get _totalDiscount {
    return widget.initialBills
        .where((b) => _selectedBillIds.contains(b.id))
        .fold(0.0, (sum, b) => sum + (b.discountAmount ?? 0.0));
  }'''

content = content.replace('''  double get _totalSelectedAmount {
    return widget.initialBills
        .where((b) => _selectedBillIds.contains(b.id))
        .fold(0.0, (sum, b) => sum + (b.finalAmount ?? b.grandTotal ?? 0.0));
  }''', getters)

# 2. Add local variables in build
build_start = '''  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _totalSelectedAmount;
    final totalGameCharges = _totalGameCharges;
    final totalOrders = _totalOrders;
    final totalManualGames = _totalManualGames;
    final totalDiscount = _totalDiscount;
    final unroundedTotal = totalGameCharges + totalOrders + totalManualGames - totalDiscount;
    final totalRounding = total - unroundedTotal;
    final appSettings = ref.watch(appSettingsProvider).asData?.value;'''

content = content.replace('''  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _totalSelectedAmount;
    final appSettings = ref.watch(appSettingsProvider).asData?.value;''', build_start)

# 3. Add breakdown UI above "Total to Pay"
breakdown_ui = '''                  const Text('Payment Breakdown', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  const Gap(12),
                  if (totalGameCharges > 0)
                    _InfoRow(label: 'Total Game Charges', value: '\u20b9${totalGameCharges.toStringAsFixed(2)}'),
                  if (totalManualGames > 0)
                    _InfoRow(label: 'Manual Games', value: '\u20b9${totalManualGames.toStringAsFixed(2)}'),
                  if (totalOrders > 0)
                    _InfoRow(label: 'Orders Total', value: '\u20b9${totalOrders.toStringAsFixed(2)}'),
                  if (totalDiscount > 0)
                    _InfoRow(
                      label: 'Discount',
                      value: '-\u20b9${totalDiscount.toStringAsFixed(2)}',
                      style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.w500),
                    ),
                  if (totalRounding.abs() > 0.01)
                    _InfoRow(
                      label: 'Rounding',
                      value: '${totalRounding > 0 ? '+' : '-'}\u20b9${totalRounding.abs().toStringAsFixed(2)}',
                    ),
                  const Divider(height: 24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total to Pay','''

content = content.replace('''                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total to Pay',''', breakdown_ui)

# 4. Add _InfoRow class at the end of the file
info_row_class = '''
class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final TextStyle? style;

  const _InfoRow({
    required this.label,
    required this.value,
    this.style,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: style ?? const TextStyle(fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
'''
content += info_row_class

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched combined settlement screen breakdown')
