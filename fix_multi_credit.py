import os

filepath = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Add _renamedPlayers to state
text = text.replace(
    "String? _PlayerProfileName;",
    "String? _PlayerProfileName;\n  final Map<String, String> _renamedPlayers = {};"
)

# 2. Update _showCreditNameDialog to support multiplayer
old_dialog = """  void _showCreditNameDialog(String defaultName, {bool autoConfirm = false, bool setMethod = false}) {
    final initialText = _PlayerProfileName != null && !_PlayerProfileName!.toLowerCase().startsWith('default') 
        ? _PlayerProfileName! 
        : (defaultName.toLowerCase().startsWith('default') ? '' : defaultName);
        
    final nameCtrl = TextEditingController(text: initialText);"""

new_dialog = """  void _showCreditNameDialog(String defaultName, {bool autoConfirm = false, bool setMethod = false}) {
    String initialText = '';
    if (!_isMultiPayer) {
      initialText = _PlayerProfileName != null && !_PlayerProfileName!.toLowerCase().startsWith('default') 
          ? _PlayerProfileName! 
          : (defaultName.toLowerCase().startsWith('default') ? '' : defaultName);
    } else {
      final renamed = _renamedPlayers[defaultName];
      initialText = renamed != null && !renamed.toLowerCase().startsWith('default') 
          ? renamed 
          : (defaultName.toLowerCase().startsWith('default') ? '' : defaultName);
    }
        
    final nameCtrl = TextEditingController(text: initialText);"""
text = text.replace(old_dialog, new_dialog)

old_logic = """              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  _PlayerProfileName = nameCtrl.text.trim();
                  if (autoConfirm || setMethod) {
                    _paymentMethod = PaymentMethod.credit;
                    _playerPaymentSplits[defaultName] = {
                      PaymentMethod.credit: _roundedTotal,
                    };
                  }
                });"""
new_logic = """              if (nameCtrl.text.trim().isNotEmpty) {
                setState(() {
                  if (!_isMultiPayer) {
                    _PlayerProfileName = nameCtrl.text.trim();
                  } else {
                    _renamedPlayers[defaultName] = nameCtrl.text.trim();
                  }
                  if (autoConfirm || setMethod) {
                    _paymentMethod = PaymentMethod.credit;
                    _playerPaymentSplits[defaultName] = {
                      PaymentMethod.credit: !_isMultiPayer ? _roundedTotal : (_customLiabilities[defaultName] ?? 0.0),
                    };
                  }
                });"""
text = text.replace(old_logic, new_logic)

# 3. Update _buildSplitLiabilityTable UI
old_table_text = """                          Text(
                            player,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),"""
new_table_text = """                          Text(
                            _renamedPlayers[player] ?? player,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
                          ),"""
text = text.replace(old_table_text, new_table_text)

old_table_on_tap = """                          child: GestureDetector(
                            onTap: () => setState(
                              () => _playerPaymentSplits[player] = {
                                method: liabilities[player] ?? 0.0,
                              },
                            ),
                            child: Container("""
new_table_on_tap = """                          child: GestureDetector(
                            onTap: () {
                              final displayName = _renamedPlayers[player] ?? player;
                              if (method == PaymentMethod.credit && displayName.toLowerCase().startsWith('default')) {
                                _showCreditNameDialog(player, autoConfirm: false, setMethod: true);
                              } else {
                                setState(() => _playerPaymentSplits[player] = {
                                  method: liabilities[player] ?? 0.0,
                                });
                              }
                            },
                            child: Container("""
text = text.replace(old_table_on_tap, new_table_on_tap)

# 4. Update _confirmPayment validation
old_val = """    if (!_isMultiPayer && _session.gameType == GameType.standard) {
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
    }"""
new_val = """    if (!_isMultiPayer && _session.gameType == GameType.standard) {
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
    } else if (_isMultiPayer) {
      for (final player in _playerPaymentSplits.keys) {
        final splits = _playerPaymentSplits[player]!;
        if (splits.containsKey(PaymentMethod.credit) && splits[PaymentMethod.credit]! > 0) {
          final displayName = _renamedPlayers[player] ?? player;
          if (displayName.toLowerCase().startsWith('default')) {
            hasDefaultCredit = true;
            break;
          }
        }
      }
    }"""
text = text.replace(old_val, new_val)

# 5. Update _confirmPayment to apply _renamedPlayers
old_rename = """    if (!_isMultiPayer) {
      // Regardless of split or single method, if it was a default player and they renamed it,"""
new_rename = """    if (_isMultiPayer) {
      for (final entry in _renamedPlayers.entries) {
        final oldName = entry.key;
        final newName = entry.value;
        if (oldName == newName) continue;
        
        if (finalTeamA.contains(oldName)) {
          finalTeamA[finalTeamA.indexOf(oldName)] = newName;
        }
        if (finalTeamB.contains(oldName)) {
          finalTeamB[finalTeamB.indexOf(oldName)] = newName;
        }
        if (finalPlayerIdentities != null && finalPlayerIdentities.containsKey(oldName)) {
           final oldId = finalPlayerIdentities.remove(oldName);
           if (finalPlayerIds != null && oldId != null) finalPlayerIds.remove(oldId);
        }
        
        if (_playerPaymentSplits.containsKey(oldName)) {
           _playerPaymentSplits[newName] = _playerPaymentSplits.remove(oldName)!;
        }
        if (_customLiabilities.containsKey(oldName)) {
           _customLiabilities[newName] = _customLiabilities.remove(oldName)!;
        }
      }
    } else {
      // Regardless of split or single method, if it was a default player and they renamed it,"""
text = text.replace(old_rename, new_rename)

# Make sure to handle the brackets for `else {` properly. The block previously ended with `    }`.
# I will just write a second replace to fix the end bracket.
# It ends with:
#         _customLiabilities.clear();
#         _customLiabilities[creditPayer] = _roundedTotal;
#       }
#     }
old_end = """      if (!isSplit) {
        final creditPayer = hasRenamedDefault ? _PlayerProfileName! : singlePayer;
        _playerPaymentSplits.clear();
        _playerPaymentSplits[creditPayer] = {_paymentMethod: _roundedTotal};

        _customLiabilities.clear();
        _customLiabilities[creditPayer] = _roundedTotal;
      }
    }"""
new_end = """      if (!isSplit) {
        final creditPayer = hasRenamedDefault ? _PlayerProfileName! : singlePayer;
        _playerPaymentSplits.clear();
        _playerPaymentSplits[creditPayer] = {_paymentMethod: _roundedTotal};

        _customLiabilities.clear();
        _customLiabilities[creditPayer] = _roundedTotal;
      }
    }"""
# Wait, I don't need to change the end bracket if I just replace the `if (!_isMultiPayer) {` line!
# The brace matches `} else {`! So it closes `} else {` instead of `if (!_isMultiPayer) {`.

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
