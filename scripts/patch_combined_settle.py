import sys
import re

path = 'lib/features/games/presentation/screens/combined_settlement_screen.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

imports = """import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/games/presentation/widgets/player_split_payment_sheet.dart';
import 'package:snooker_club/features/settings/providers/settings_provider.dart';
import 'package:snooker_club/features/games/presentation/widgets/upi_qr_dialog.dart';
"""

# Replace imports
content = re.sub(r'import.*?;\n\nclass Combined', imports + '\nclass Combined', content, flags=re.DOTALL)

# Add ref.watch for settings inside build
build_start = """  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = _totalSelectedAmount;
    final appSettings = ref.watch(settingsProvider).asData?.value;
"""
content = content.replace('  @override\n  Widget build(BuildContext context) {\n    final theme = Theme.of(context);\n    final total = _totalSelectedAmount;', build_start)

# Add the QR button
button_group = """
                  const Gap(24),
                  if (_paymentMethod == PaymentMethod.upi &&
                      appSettings != null &&
                      appSettings.business.upiId != null &&
                      appSettings.business.upiId!.isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16.0),
                      child: SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () {
                            showDialog(
                              context: context,
                              builder: (ctx) => UpiQrDialog(
                                upiId: appSettings.business.upiId!,
                                payeeName: appSettings.business.clubName,
                                amount: total,
                              ),
                            );
                          },
                          icon: const Icon(Icons.qr_code_2),
                          label: const Text('Generate QR'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                        ),
                      ),
                    ),
                  SizedBox(
"""
content = content.replace('                  const Gap(24),\n                  SizedBox(\n                    width: double.infinity,\n                    child: FilledButton(', button_group + '                    width: double.infinity,\n                    child: FilledButton(')

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched combined settlement screen')
