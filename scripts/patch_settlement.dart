import 'dart:io';

void main() {
  final file = File('lib/features/games/presentation/screens/combined_settlement_screen.dart');
  var content = file.readAsStringSync();
  
  final startIdx = content.indexOf('Future<void> _confirmSettlement() async {');
  
  // find end bracket
  int braceCount = 0;
  bool started = false;
  int endIdx = startIdx;
  for (int i = startIdx; i < content.length; i++) {
    if (content[i] == '{') {
      braceCount++;
      started = true;
    } else if (content[i] == '}') {
      braceCount--;
      if (started && braceCount == 0) {
        endIdx = i + 1;
        break;
      }
    }
  }

  final newMethod = '''
  Future<void> _confirmSettlement() async {
    if (_selectedBillIds.isEmpty || _isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      final billsToSettle = _localBills
          .where((b) => _selectedBillIds.contains(b.id))
          .toList();

      final repo = ref.read(gamesRepositoryProvider);

      final unroundedTotal = billsToSettle.fold(0.0, (sum, b) => sum + (b.finalAmount ?? b.grandTotal ?? 0.0));
      final roundedTotal = BillingUtils.roundAmount(unroundedTotal);

      PaymentMethod methodToUse = _paymentMethod;
      if (_playerPaymentSplits.isNotEmpty && _playerPaymentSplits.length == 1) {
        methodToUse = _playerPaymentSplits.keys.first;
      }
      
      final isSplit = _playerPaymentSplits.length > 1;

      await repo.settlePendingBillsCombined(
        billsToSettle,
        paymentMethod: methodToUse,
        paidBy: widget.customerName,
        customerName: widget.customerName,
        roundedTotal: roundedTotal,
        playerPaymentSplits: isSplit ? {widget.customerName: _playerPaymentSplits} : null,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Successfully settled \${billsToSettle.length} bill(s).'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to settle bills: \$e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }
''';

  content = content.substring(0, startIdx) + newMethod + content.substring(endIdx);
  file.writeAsStringSync(content);
}
