import os

filepath = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_logic = """    if (!_isMultiPayer) {
      if (!isSplit) {
        final creditPayer =
            (_paymentMethod == PaymentMethod.credit &&
                _PlayerProfileName != null)
            ? _PlayerProfileName!
            : singlePayer;

        // BUG 2 & 3 FIX: If the single payer was a default player and was renamed for credit,
        // we must rename them in teamA/teamB so they show up in Khata Game History correctly.
        if (singlePayer.toLowerCase().startsWith('default') && creditPayer != singlePayer) {
          if (finalTeamA.contains(singlePayer)) {
            finalTeamA[finalTeamA.indexOf(singlePayer)] = creditPayer;
          }
          if (finalTeamB.contains(singlePayer)) {
            finalTeamB[finalTeamB.indexOf(singlePayer)] = creditPayer;
          }
          if (finalPlayerIdentities != null && finalPlayerIdentities.containsKey(singlePayer)) {
             final oldId = finalPlayerIdentities.remove(singlePayer);
             if (finalPlayerIds != null && oldId != null) {
                finalPlayerIds.remove(oldId);
             }
          }
        }

        _playerPaymentSplits.clear();
        _playerPaymentSplits[creditPayer] = {_paymentMethod: _roundedTotal};

        _customLiabilities.clear();
        _customLiabilities[creditPayer] = _roundedTotal;
      }
    }"""

new_logic = """    if (!_isMultiPayer) {
      // Regardless of split or single method, if it was a default player and they renamed it,
      // apply the rename across all tracking objects to prevent ghost Khata accounts.
      final hasRenamedDefault = singlePayer.toLowerCase().startsWith('default') && 
                                _PlayerProfileName != null && 
                                _PlayerProfileName!.isNotEmpty && 
                                _PlayerProfileName != singlePayer;
                                
      if (hasRenamedDefault) {
        final creditPayer = _PlayerProfileName!;
        
        // 1. Rename in Team A/B
        if (finalTeamA.contains(singlePayer)) {
          finalTeamA[finalTeamA.indexOf(singlePayer)] = creditPayer;
        }
        if (finalTeamB.contains(singlePayer)) {
          finalTeamB[finalTeamB.indexOf(singlePayer)] = creditPayer;
        }
        if (finalPlayerIdentities != null && finalPlayerIdentities.containsKey(singlePayer)) {
           final oldId = finalPlayerIdentities.remove(singlePayer);
           if (finalPlayerIds != null && oldId != null) {
              finalPlayerIds.remove(oldId);
           }
        }
        
        // 2. Rename in Splits/Liabilities if they were populated under the old default name
        if (isSplit && _playerPaymentSplits.containsKey(singlePayer)) {
          final existingSplit = _playerPaymentSplits.remove(singlePayer);
          if (existingSplit != null) {
            _playerPaymentSplits[creditPayer] = existingSplit;
          }
        }
        if (isSplit && _customLiabilities.containsKey(singlePayer)) {
          final existingLiab = _customLiabilities.remove(singlePayer);
          if (existingLiab != null) {
            _customLiabilities[creditPayer] = existingLiab;
          }
        }
      }

      if (!isSplit) {
        final creditPayer = hasRenamedDefault ? _PlayerProfileName! : singlePayer;
        _playerPaymentSplits.clear();
        _playerPaymentSplits[creditPayer] = {_paymentMethod: _roundedTotal};

        _customLiabilities.clear();
        _customLiabilities[creditPayer] = _roundedTotal;
      }
    }"""

text = text.replace(old_logic, new_logic)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
