import os

filepath = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_call = "_showCreditNameDialog(player, autoConfirm: true);"
new_call = "_showCreditNameDialog(player, autoConfirm: false, setMethod: true);"
text = text.replace(old_call, new_call)

old_def = "void _showCreditNameDialog(String defaultName, {bool autoConfirm = false}) {"
new_def = "void _showCreditNameDialog(String defaultName, {bool autoConfirm = false, bool setMethod = false}) {"
text = text.replace(old_def, new_def)

old_logic = """                setState(() {
                  _PlayerProfileName = nameCtrl.text.trim();
                  if (autoConfirm) {
                    _paymentMethod = PaymentMethod.credit;
                    _playerPaymentSplits[defaultName] = {
                      PaymentMethod.credit: _roundedTotal,
                    };
                  }
                });"""

new_logic = """                setState(() {
                  _PlayerProfileName = nameCtrl.text.trim();
                  if (autoConfirm || setMethod) {
                    _paymentMethod = PaymentMethod.credit;
                    _playerPaymentSplits[defaultName] = {
                      PaymentMethod.credit: _roundedTotal,
                    };
                  }
                });"""

text = text.replace(old_logic, new_logic)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
