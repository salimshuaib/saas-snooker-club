import os
import re

filepath = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    content = f.read()

import_statement = "import 'package:snooker_club/features/games/presentation/widgets/pending_bill_customer_sheet.dart';"
if import_statement not in content:
    content = content.replace("import 'package:snooker_club/features/games/presentation/widgets/player_split_payment_sheet.dart';",
                              "import 'package:snooker_club/features/games/presentation/widgets/player_split_payment_sheet.dart';\n" + import_statement)

mark_as_pending_code = '''
  Future<void> _markAsPending(String customerId, String customerName) async {
    if (_isProcessing) return;

    setState(() {
      _isProcessing = true;
    });

    try {
      final finalEndTime = _isTimeManuallyEdited
          ? _session.endTime ?? DateTime.now()
          : DateTime.now();
      
      final finalSession = _session.copyWith(
        endTime: finalEndTime,
        gameCharge: _gameCharge,
        baseGameCharge: _baseGameCharge,
        overtimeMinutes: _overtimeMinutes,
        overtimeCharge: _overtimeCharge,
        ordersTotal: _ordersTotal,
        manualGamesTotal: _manualGamesTotal,
        grandTotal: _finalTotal,
        roundedAmount: _roundedTotal,
        finalAmount: _roundedTotal,
        discountAmount: _discountAmount,
        discountPercent: double.tryParse(_discountPercentController.text) ?? 0.0,
        playerPaymentSplits: _playerPaymentSplits,
        playerLiabilities: _customLiabilities,
      );

      await ref
          .read(gamesRepositoryProvider)
          .markAsPendingBill(finalSession, customerId: customerId, customerName: customerName);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Bill marked as pending for ' + customerName + '.'),
            backgroundColor: Colors.orange,
          ),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to mark as pending: ' + e.toString()),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _showPendingBillCustomerSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (context) => SizedBox(
        height: MediaQuery.of(context).size.height * 0.7,
        child: PendingBillCustomerSheet(
          onCustomerSelected: (id, name) {
            Navigator.of(context).pop();
            _markAsPending(id, name);
          },
        ),
      ),
    );
  }
'''

content = content.replace('Future<void> _confirmPayment() async {', mark_as_pending_code + '\n  Future<void> _confirmPayment() async {')

start_idx = content.find('// ── Confirm Button ──')
end_idx = content.find('const Gap(32),', start_idx)

if start_idx != -1 and end_idx != -1:
    old_button_section = content[start_idx:end_idx]
    
    # We replace the outer SizedBox of Confirm Button with a Column
    new_button_section = re.sub(
        r'SizedBox\(\s*width: double\.infinity,\s*child: FilledButton\(',
        '''Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(''',
        old_button_section
    )
    
    new_button_section = re.sub(
        r'\)\,\s*\)\,\s*$',
        '''),
                  ),
                  const Gap(12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton(
                      onPressed: _isProcessing ? null : _showPendingBillCustomerSheet,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 18),
                        side: const BorderSide(color: Colors.orange),
                        foregroundColor: Colors.orange,
                      ),
                      child: Text(
                        'Mark as Pending Bill',
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
''',
        new_button_section
    )
    
    content = content.replace(old_button_section, new_button_section)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(content)

print('Phase 3 complete')
