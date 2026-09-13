import os

filepath = 'lib/features/games/presentation/screens/bill_details_screen.dart'
with open(filepath, 'r', encoding='utf-8') as f:
    text = f.read()

old_block = """    if (isSplit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Editing individual player payment methods is currently unsupported for split payments.',
          ),
        ),
      );
      return;
    } else {"""

new_block = """    if (isSplit) {
      final Map<String, PaymentMethod> updatedMethods = {};
      session.playerPaymentSplits!.forEach((playerName, splits) {
        if (splits.isNotEmpty) {
          updatedMethods[playerName] = splits.keys.first;
        }
      });

      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Edit Split Payments'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: updatedMethods.entries.map((entry) {
                  final playerName = entry.key;
                  final currentMethod = entry.value;
                  final amount = session.playerPaymentSplits![playerName]!.values.first;
                  
                  final isDefault = playerName.toLowerCase().startsWith('default');

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(playerName, style: const TextStyle(fontWeight: FontWeight.bold)),
                              Text('\u20B9${amount.toStringAsFixed(2)}', style: const TextStyle(color: Colors.grey)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          flex: 3,
                          child: DropdownButtonFormField<PaymentMethod>(
                            value: currentMethod,
                            isExpanded: true,
                            decoration: const InputDecoration(
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(),
                            ),
                            items: PaymentMethod.values
                                .where((m) => !(m == PaymentMethod.credit && isDefault))
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m.displayName),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null) setState(() => updatedMethods[playerName] = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(AppLocalizations.of(context)!.cancel),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      );

      if (result == true && context.mounted) {
        try {
          await ref.read(gamesRepositoryProvider).updateGameSplitPaymentMethods(
                session: session,
                updatedMethods: updatedMethods,
                employeeName: 'Admin',
              );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Split payment methods updated & credit accounts adjusted.'),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
            );
          }
        }
      }
      return;
    } else {"""

if old_block in text:
    text = text.replace(old_block, new_block)
    with open(filepath, 'w', encoding='utf-8') as f:
        f.write(text)
    print("SUCCESS")
else:
    print("FAILED to find old_block")

