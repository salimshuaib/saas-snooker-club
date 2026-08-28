import re

with open('lib/features/games/presentation/screens/billing_screen.dart', 'r') as f:
    code = f.read()

target = '''  Future<void> _confirmPayment() async {
    if (!_isMultiRoundTP && _session.matchType == MatchType.loserPays && _winnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a winner before confirming payment.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_isMultiRoundTP && _paymentMethod == PaymentMethod.credit && _creditCustomerName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the customer taking the credit.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final finalSession = _isMultiRoundTP
        ? _session.copyWith(
            endTime: DateTime.now(),
            status: TableStatus.available,
            playerPaymentMethods: _playerPaymentMethods,
            playerLiabilities: _calculatedLiabilities,
            gameCharge: _gameCharge,
            baseGameCharge: _baseGameCharge,
            overtimeMinutes: _overtimeMinutes,
            overtimeCharge: _overtimeCharge,
            ordersTotal: _ordersTotal,
            grandTotal: _grandTotal,
          )'''

replacement = '''  Future<void> _confirmPayment() async {
    if (!_isMultiRoundTP && _session.matchType == MatchType.loserPays && _winnerId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select a winner before confirming payment.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    if (!_isMultiRoundTP && _paymentMethod == PaymentMethod.credit && _creditCustomerName == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the customer taking the credit.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    final finalSession = _isMultiRoundTP
        ? _session.copyWith(
            endTime: DateTime.now(),
            status: TableStatus.available,
            playerPaymentMethods: _playerPaymentMethods,
            playerLiabilities: _calculatedLiabilities,
            gameCharge: _gameCharge,
            baseGameCharge: _baseGameCharge,
            overtimeMinutes: _overtimeMinutes,
            overtimeCharge: _overtimeCharge,
            ordersTotal: _ordersTotal,
            grandTotal: _grandTotal,
            date: DateFormat('yyyy-MM-dd').format(DateTime.now()),
          )'''

code = code.replace(target, replacement)

with open('lib/features/games/presentation/screens/billing_screen.dart', 'w') as f:
    f.write(code)

print("Billing screen patched successfully")
