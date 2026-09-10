import 'package:snooker_club/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/constants/firebase_constants.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/widgets/inputs/app_text_field.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/presentation/widgets/admin_passcode_dialog.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';

class BillDetailsScreen extends ConsumerStatefulWidget {
  final GameSession session;

  const BillDetailsScreen({super.key, required this.session});

  @override
  ConsumerState<BillDetailsScreen> createState() => _BillDetailsScreenState();
}

class _BillDetailsScreenState extends ConsumerState<BillDetailsScreen> {
  GameSession get session => widget.session;


  String _formatDuration(int seconds) {
    final h = (seconds ~/ 3600).toString().padLeft(2, '0');
    final m = ((seconds % 3600) ~/ 60).toString().padLeft(2, '0');
    final s = (seconds % 60).toString().padLeft(2, '0');
    return seconds >= 3600 ? '$h:$m:$s' : '$m:$s';
  }

  IconData _paymentIcon(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return Icons.payments;
      case PaymentMethod.upi:
        return Icons.qr_code_scanner;
      case PaymentMethod.credit:
        return Icons.credit_score;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubId = ref.watch(clubIdProvider);
    if (clubId == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));
    
    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection(FirebaseConstants.clubsCollection)
          .doc(clubId)
          .collection(FirebaseConstants.gamesCollection)
          .doc(widget.session.id)
          .snapshots(),
      builder: (context, snapshot) {
        final session = (snapshot.hasData && snapshot.data!.data() != null)
            ? GameSession.fromMap(snapshot.data!.data() as Map<String, dynamic>)
            : widget.session;
        final theme = Theme.of(context);
        final dtFmt = DateFormat('d MMM yyyy, hh:mm a');

        // Group orders by player
        final Map<String, List<GameOrder>> playerOrders = {};
        for (final order in session.orders) {
          final key = order.playerName ?? 'Shared';
          playerOrders.putIfAbsent(key, () => []).add(order);
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Bill Details'),
            centerTitle: false,
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Bill Details',
                onSelected: (value) {
                  if (value == 'names') {
                    _showEditNamesModal(context, session);
                  } else if (value == 'payment') {
                    _showEditPaymentModal(context, session);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'names',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 20),
                        Gap(12),
                        Text('Edit Player Names'),
                      ],
                    ),
                  ),
                  const PopupMenuItem(
                    value: 'payment',
                    child: Row(
                      children: [
                        Icon(Icons.payment_outlined, size: 20),
                        Gap(12),
                        Text('Edit Payment Method'),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
          body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── General Information ──
            Text('General Information', style: theme.textTheme.titleMedium),
            const Gap(8),
            _SectionCard(
              children: [
                _InfoRow(label: 'Table Name', value: session.tableName),
                _InfoRow(label: 'Table Type', value: session.tableType.displayName),
                  _InfoRow(label: 'Game Type', value: session.gameType.displayName),
                _InfoRow(label: 'Match Type', value: session.matchType.displayName),
                _InfoRow(label: 'Billing Type', value: session.billingType.displayName),
                _InfoRow(label: 'Game Date', value: session.date),
                _InfoRow(label: 'Start Time', value: dtFmt.format(session.startTime)),
                if (session.endTime != null)
                  _InfoRow(label: 'End Time', value: dtFmt.format(session.endTime!)),
                _InfoRow(label: 'Total Duration', value: _formatDuration(session.activeSeconds)),
                if (session.billingType == BillingType.perFrame)
                  _InfoRow(
                      label: 'Frames Played',
                      value: '${session.framesPlayed > 0 ? session.framesPlayed : session.totalFrames}'),
              ],
            ),
            const Gap(24),

            // ── Players ──
            Text('Players', style: theme.textTheme.titleMedium),
            const Gap(8),
            _SectionCard(
              children: [
                if (session.mode == GameMode.team) ...[
                  _InfoRow(label: 'Team A', value: session.teamA.join(', ')),
                  _InfoRow(label: 'Team B', value: session.teamB.join(', ')),
                ] else
                  _InfoRow(label: 'Players', value: session.allPlayers.join(', ')),
              ],
            ),
            const Gap(24),

            // ── Match Results & Round History ──
            if (session.rounds.isNotEmpty) ...[
              Text('Round History', style: theme.textTheme.titleMedium),
              const Gap(8),
              _SectionCard(
                children: session.rounds.map((r) => Padding(
                  padding: const EdgeInsets.only(bottom: 8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          r.winner == 'Friendly'
                              ? 'Frame ${r.roundNumber} · ${(r.durationSeconds ?? 0) ~/ 60} mins${(r.overtimeMinutes ?? 0) > 0 ? " (+${r.overtimeMinutes}m OT)" : ""}'
                              : 'Round ${r.roundNumber} · Winner: ${r.winner == 'Team A' ? session.teamA.join(' & ') : r.winner == 'Team B' ? session.teamB.join(' & ') : (r.winner ?? "N/A")}${r.loser != null ? " · Loser: ${r.loser == 'Team A' ? session.teamA.join(' & ') : r.loser == 'Team B' ? session.teamB.join(' & ') : r.loser}" : ""}${(r.overtimeMinutes ?? 0) > 0 ? " (+${r.overtimeMinutes}m OT)" : ""}',
                          style: theme.textTheme.bodyMedium,
                        ),
                      ),
                      Text('₹${(r.roundCost + (r.overtimeCharge ?? 0.0)).toStringAsFixed(2)}', style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600)),
                    ],
                  ),
                )).toList(),
              ),
              const Gap(24),
            ] else ...[
              Text('Match Results', style: theme.textTheme.titleMedium),
              const Gap(8),
              _SectionCard(
                children: [
                  if (session.matchType == MatchType.loserPays) ...[
                    _InfoRow(label: 'Winner', value: session.winnerDisplayName ?? 'N/A'),
                    _InfoRow(
                      label: 'Loser',
                      value: _getLoser(session),
                    ),
                    _InfoRow(
                      label: 'Paid By',
                      value: _getLoser(session), // Loser pays
                    ),
                  ] else ...[
                    // Friendly match
                    _InfoRow(label: 'Paid By', value: 'Shared / Multiple'),
                  ],
                ],
              ),
              const Gap(24),
            ],

            // ── Ordered Items ──
            if (session.orders.isNotEmpty) ...[
              Text('Ordered Items', style: theme.textTheme.titleMedium),
              const Gap(8),
              _SectionCard(
                children: playerOrders.entries.map((entry) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          entry.key,
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                        ),
                        const Gap(4),
                        ...entry.value.map((o) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 2.0),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${o.quantity}x ${o.productName}',
                                    style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                                  ),
                                  Text(
                                    '₹${o.total.toStringAsFixed(0)}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ],
                              ),
                            )),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const Gap(24),
            ],

            // ── Billing Summary ──
            Text('Billing Summary', style: theme.textTheme.titleMedium),
            const Gap(8),
            _SectionCard(
              children: [
                if (session.billingType == BillingType.perFrame) ...[
                  _InfoRow(
                    label: 'Frame Charges',
                    value: '₹${(session.baseGameCharge ?? session.gameCharge ?? 0).toStringAsFixed(2)}',
                  ),
                  if (session.baseGameCharge != null)
                    const _InfoRow(
                      label: 'Grace Period',
                      value: '20 Mins / Frame',
                    ),
                ] else ...[
                  _InfoRow(
                    label: 'Package Charge',
                    value: '₹${(session.baseGameCharge ?? session.gameCharge ?? 0).toStringAsFixed(2)}',
                  ),
                ],
                if ((session.overtimeMinutes ?? 0) > 0) ...[
                  _InfoRow(
                    label: 'Overtime (${session.overtimeMinutes} mins)',
                    value: '₹${(session.overtimeCharge ?? 0).toStringAsFixed(2)}',
                  ),
                ],
                if (session.overtimeMinutes != null && session.overtimeMinutes! > 0) ...[
                  const Divider(height: 16),
                  _InfoRow(
                    label: 'Total Game Charge',
                    value: '₹${(session.gameCharge ?? 0).toStringAsFixed(2)}',
                  ),
                ],
                if ((session.ordersTotal ?? 0) > 0)
                  _InfoRow(
                    label: 'Orders Total',
                    value: '₹${session.ordersTotal!.toStringAsFixed(2)}',
                  ),
                const Divider(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Grand Total',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                    ),
                    Text(
                      '₹${(session.grandTotal ?? 0).toStringAsFixed(2)}',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                if (session.finalAmount != null) ...[
                  const Gap(8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Final Billed',
                        style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      Text(
                        '₹${session.finalAmount!.toStringAsFixed(2)}',
                        style: theme.textTheme.titleLarge?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
            const Gap(24),

            // ── Payment Information ──
            Text('Payment Information', style: theme.textTheme.titleMedium),
            const Gap(8),
            if (session.playerPaymentSplits != null && session.playerPaymentSplits!.isNotEmpty) ...[
              _SectionCard(
                children: session.playerPaymentSplits!.entries.map((entry) {
                  final player = entry.key;
                  final splits = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(player, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700)),
                        const Gap(4),
                        ...splits.entries.map((splitEntry) {
                          final method = splitEntry.key;
                          final amount = splitEntry.value;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Row(
                                  children: [
                                    Icon(_paymentIcon(method), size: 14, color: theme.colorScheme.onSurfaceVariant),
                                    const Gap(4),
                                    Text(method.displayName, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                                    if (method == PaymentMethod.credit) ...[
                                      const Gap(6),
                                      Text('(${session.paymentStatus ?? 'Outstanding'})', 
                                        style: theme.textTheme.labelSmall?.copyWith(
                                          color: session.paymentStatus == 'Paid' ? AppColors.success 
                                            : (session.paymentStatus == 'Partially Paid' ? AppColors.warning : AppColors.creditStatus),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                                Text(
                                  '₹${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}',
                                  style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600, color: AppColors.primary),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ] else ...[
              _SectionCard(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Payment Method',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      if (session.paymentMethod != null)
                        Row(
                          children: [
                            Icon(_paymentIcon(session.paymentMethod!), size: 16, color: theme.colorScheme.onSurface),
                            const Gap(4),
                            Text(
                              session.paymentMethod!.displayName,
                              style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ],
                        )
                      else
                        const Text('N/A'),
                    ],
                  ),
                  const Gap(12),
                  _InfoRow(
                    label: 'Payment Status',
                    value: session.paymentStatus ?? (session.paymentMethod == PaymentMethod.credit ? 'Outstanding' : 'Paid'),
                    valueColor: session.paymentStatus == 'Paid' ? AppColors.success 
                        : (session.paymentStatus == 'Partially Paid' ? AppColors.warning 
                        : (session.paymentMethod == PaymentMethod.credit ? AppColors.creditStatus : AppColors.success)),
                  ),
                  if (session.paymentMethod == PaymentMethod.credit && session.paymentStatus != 'Paid') ...[
                    _InfoRow(
                      label: 'Paid Amount',
                      value: '₹${(session.paidAmount ?? 0.0).toStringAsFixed(2)}',
                      valueColor: AppColors.success,
                    ),
                    _InfoRow(
                      label: 'Remaining',
                      value: '₹${(session.remainingAmount ?? (session.finalAmount ?? session.grandTotal ?? 0.0)).toStringAsFixed(2)}',
                      valueColor: AppColors.creditStatus,
                    ),
                  ],
                  if (session.endTime != null)
                    _InfoRow(label: 'Payment Date', value: dtFmt.format(session.endTime!)),
                ],
              ),
            ],
            const Gap(24),
            if (session.auditLogs.isNotEmpty) ...[
              Text('Audit History', style: theme.textTheme.titleMedium),
              const Gap(8),
              _SectionCard(
                children: session.auditLogs.map((log) => Padding(
                  padding: const EdgeInsets.only(bottom: 12.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(log.field, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold)),
                          Text(dtFmt.format(log.timestamp), style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                        ],
                      ),
                      const Gap(4),
                      Text('Changed from "${log.previousValue}" to "${log.newValue}" by ${log.editedBy}',
                        style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                )).toList(),
              ),
            ],
            const Gap(32),
          ],
        ),
      ),
    );
    });
  }

  String _getLoser(GameSession session) {
    return session.loserDisplayName ?? 'N/A';
  }

  Future<void> _showEditNamesModal(BuildContext context, GameSession session) async {
    final verified = await AdminPasscodeDialog.verify(
      context,
      ref,
      title: 'Admin Authorization',
      subtitle: 'Enter administrator passcode to edit player names.',
    );
    if (verified != true || !context.mounted) return;

    final teamAControllers = session.teamA.map((name) => TextEditingController(text: name)).toList();
    final teamBControllers = session.teamB.map((name) => TextEditingController(text: name)).toList();
    final payerController = TextEditingController(text: session.paidBy ?? '');

    final result = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Player Names'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (session.mode == GameMode.team) const Text('Team A', style: TextStyle(fontWeight: FontWeight.bold)),
              for (int i = 0; i < teamAControllers.length; i++) ...[
                const Gap(8),
                AppTextField(
                  label: session.mode == GameMode.team ? 'Player ${i + 1}' : 'Player Name',
                  controller: teamAControllers[i],
                ),
              ],
              if (teamBControllers.isNotEmpty) ...[
                const Gap(16),
                if (session.mode == GameMode.team) const Text('Team B', style: TextStyle(fontWeight: FontWeight.bold)),
                for (int i = 0; i < teamBControllers.length; i++) ...[
                  const Gap(8),
                  AppTextField(
                    label: 'Player ${i + 1}',
                    controller: teamBControllers[i],
                  ),
                ],
              ],
              if (session.paidBy != null) ...[
                const Gap(16),
                const Text('Payer Name (Credit / Bill)', style: TextStyle(fontWeight: FontWeight.bold)),
                const Gap(8),
                AppTextField(
                  label: 'Paid By',
                  controller: payerController,
                ),
              ],
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );

    if (result == true && context.mounted) {
      final newTeamA = teamAControllers.map((c) => c.text.trim()).toList();
      final newTeamB = teamBControllers.map((c) => c.text.trim()).toList();
      final newPaidBy = session.paidBy != null ? payerController.text.trim() : null;

      try {
        await ref.read(gamesRepositoryProvider).updateGameNames(
          session: session,
          newTeamA: newTeamA,
          newTeamB: newTeamB,
          newPaidBy: newPaidBy,
          employeeName: 'Admin',
        );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Player names updated and synced.'), backgroundColor: AppColors.success),
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

    for (final c in teamAControllers) {
      c.dispose();
    }
    for (final c in teamBControllers) {
      c.dispose();
    }
    payerController.dispose();
  }

  Future<void> _showEditPaymentModal(BuildContext context, GameSession session) async {
    final verified = await AdminPasscodeDialog.verify(
      context,
      ref,
      title: 'Admin Authorization',
      subtitle: 'Enter administrator passcode to edit payment method.',
    );
    if (verified != true || !context.mounted) return;

    final isSplit = session.playerPaymentSplits != null && session.playerPaymentSplits!.isNotEmpty;

    if (isSplit) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Editing individual player payment methods is currently unsupported for split payments.')),
      );
      return;
    } else {
      PaymentMethod selectedMethod = session.paymentMethod ?? PaymentMethod.cash;
      final payerController = TextEditingController(text: session.paidBy ?? '');

      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Edit Payment Method'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<PaymentMethod>(
                  value: selectedMethod,
                  decoration: const InputDecoration(labelText: 'Payment Method', border: OutlineInputBorder()),
                  items: PaymentMethod.values.map((m) => DropdownMenuItem(value: m, child: Text(m.displayName))).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => selectedMethod = val);
                  },
                ),
                if (selectedMethod == PaymentMethod.credit) ...[
                  const Gap(16),
                  AppTextField(
                    label: 'Customer Name (for Credit Account)',
                    controller: payerController,
                  ),
                ],
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: Text(AppLocalizations.of(context)!.cancel)),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                style: ElevatedButton.styleFrom(backgroundColor: AppColors.primary, foregroundColor: Colors.white),
                child: const Text('Save Changes'),
              ),
            ],
          ),
        ),
      );

      if (result == true && context.mounted) {
        try {
          await ref.read(gamesRepositoryProvider).updateGamePaymentMethods(
            session: session,
            newPaymentMethod: selectedMethod,
            newPaidBy: selectedMethod == PaymentMethod.credit ? payerController.text.trim() : null,
            employeeName: 'Admin',
          );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Payment method updated & credit accounts adjusted.'), backgroundColor: AppColors.success),
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
      payerController.dispose();
    }
  }
}


class _SectionCard extends StatelessWidget {
  final List<Widget> children;

  const _SectionCard({required this.children});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: children,
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const Gap(12),
          Expanded(
            flex: 3,
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: valueColor ?? theme.colorScheme.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
