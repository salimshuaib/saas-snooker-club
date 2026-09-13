import os

filepath = 'lib/features/games/presentation/screens/billing_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

# 1. Replace _finalTotal with _roundedTotal in the confirmation button text
text = text.replace("Confirm Payment (\u20B9${_finalTotal.toStringAsFixed(0)})", "Confirm Payment (\u20B9${_roundedTotal.toStringAsFixed(0)})")

# 2. Replace _finalTotal with _roundedTotal for split liability
text = text.replace("totalLiability: _finalTotal,", "totalLiability: _roundedTotal,")
text = text.replace("{_paymentMethod: _finalTotal},", "{_paymentMethod: _roundedTotal},")

# 3. Replace _finalTotal with _roundedTotal in onTap
text = text.replace("method: _finalTotal,", "method: _roundedTotal,")

# 4. Replace _finalTotal with _roundedTotal in dialog autoConfirm
text = text.replace("PaymentMethod.credit: _finalTotal,", "PaymentMethod.credit: _roundedTotal,")

# 5. Fix _confirmPayment method logic:
old_confirm = """    setState(() => _isProcessing = true);

    if (!_isMultiPayer) {
      if (!isSplit) {
        final creditPayer =
            (_paymentMethod == PaymentMethod.credit &&
                _PlayerProfileName != null)
            ? _PlayerProfileName!
            : singlePayer;

        _playerPaymentSplits.clear();
        _playerPaymentSplits[creditPayer] = {_paymentMethod: _finalTotal};

        _customLiabilities.clear();
        _customLiabilities[creditPayer] = _finalTotal;
      }
    }

    final finalEndTime = _session.isManualEntry
        ? _session.endTime!
        : DateTime.now();
    final finalDate = DateFormat('yyyy-MM-dd').format(finalEndTime);

    final finalSession = _session.copyWith(
      endTime: finalEndTime,
      status: TableStatus.available,
      playerPaymentSplits: _playerPaymentSplits,
      playerLiabilities: _customLiabilities,
      gameCharge: _gameCharge,
      baseGameCharge: _baseGameCharge,
      overtimeMinutes: _overtimeMinutes,
      overtimeCharge: _overtimeCharge,
      ordersTotal: _ordersTotal,
      grandTotal: _grandTotal,
      roundedAmount: _roundedTotal,
      finalAmount: _finalTotal,
      date: finalDate,
      paidBy:
          (_paymentMethod == PaymentMethod.credit && !_isMultiPayer && !isSplit)
          ? _PlayerProfileName
          : null,
      paymentMethod: (!isSplit) ? _paymentMethod : null,
    );"""

new_confirm = """    setState(() => _isProcessing = true);

    List<String> finalTeamA = List.from(_session.teamA);
    List<String> finalTeamB = List.from(_session.teamB);
    List<String>? finalPlayerIds = _session.playerIds != null ? List.from(_session.playerIds!) : null;
    Map<String, String>? finalPlayerIdentities = _session.playerIdentities != null ? Map.from(_session.playerIdentities!) : null;

    if (!_isMultiPayer) {
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
    }

    final finalEndTime = _session.isManualEntry
        ? _session.endTime!
        : DateTime.now();
    final finalDate = DateFormat('yyyy-MM-dd').format(finalEndTime);

    final finalSession = _session.copyWith(
      endTime: finalEndTime,
      status: TableStatus.available,
      teamA: finalTeamA,
      teamB: finalTeamB,
      playerIds: finalPlayerIds,
      playerIdentities: finalPlayerIdentities,
      playerPaymentSplits: _playerPaymentSplits,
      playerLiabilities: _customLiabilities,
      gameCharge: _gameCharge,
      baseGameCharge: _baseGameCharge,
      overtimeMinutes: _overtimeMinutes,
      overtimeCharge: _overtimeCharge,
      ordersTotal: _ordersTotal,
      grandTotal: _grandTotal,
      roundedAmount: _roundedTotal,
      finalAmount: _roundedTotal,
      date: finalDate,
      paidBy:
          (_paymentMethod == PaymentMethod.credit && !_isMultiPayer && !isSplit)
          ? _PlayerProfileName
          : null,
      paymentMethod: (!isSplit) ? _paymentMethod : null,
    );"""

text = text.replace(old_confirm, new_confirm)

with open(filepath, 'w', encoding='utf-8') as f:
    f.write(text)
