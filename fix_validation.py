import os

filepath = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_val = """    if (!_isMultiPayer &&
        !isSplit &&
        _session.gameType == GameType.standard &&
        _paymentMethod == PaymentMethod.credit &&
        (_PlayerProfileName == null ||
            _PlayerProfileName!.toLowerCase().startsWith('default'))) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the customer taking the credit.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }"""

new_val = """    bool hasDefaultCredit = false;
    final isDefaultProfile = _PlayerProfileName == null || _PlayerProfileName!.toLowerCase().startsWith('default');

    if (!_isMultiPayer && _session.gameType == GameType.standard) {
      if (!isSplit && _paymentMethod == PaymentMethod.credit && isDefaultProfile) {
        hasDefaultCredit = true;
      } else if (isSplit) {
        final splits = _playerPaymentSplits[singlePayer] ?? {};
        if (splits.containsKey(PaymentMethod.credit) && splits[PaymentMethod.credit]! > 0) {
          if (isDefaultProfile && singlePayer.toLowerCase().startsWith('default')) {
            hasDefaultCredit = true;
          }
        }
      }
    }

    if (hasDefaultCredit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select the customer taking the credit.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }"""

text = text.replace(old_val, new_val)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
