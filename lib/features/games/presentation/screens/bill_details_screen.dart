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
import 'package:snooker_club/features/games/presentation/widgets/edit_bill_sheet.dart';
import 'package:snooker_club/features/games/presentation/widgets/audit_log_sheet.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';

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
    if (clubId == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

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
                  if (value == 'full_edit') {
                    _showFullEditModal(context, session);
                  } else if (value == 'names') {
                    _showEditNamesModal(context, session);
                  } else if (value == 'payment') {
                    _showEditPaymentModal(context, session);
                  }
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'full_edit',
                    child: Row(
                      children: [
                        Icon(Icons.edit_document, size: 20),
                        Gap(12),
                        Text('Edit Full Bill'),
                      ],
                    ),
                  ),
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
                  if (session.isCancelled) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        border: Border.all(color: AppColors.error),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        children: [
                          const Icon(Icons.cancel_outlined, color: AppColors.error, size: 32),
                          const Gap(8),
                          Text(
                            'THIS GAME WAS CANCELLED',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: AppColors.error,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            'The inventory was restored and no charges were billed.',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: AppColors.error,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    ),
                    const Gap(24),
                  ],
                // ── General Information ──
                _ExpandableSection(
                  title: 'General Information',
                  child: _SectionCard(
                    children: [
                      _InfoRow(label: 'Table Name', value: session.tableName),
                      _InfoRow(
                        label: 'Game Type',
                        value: session.billingType.displayName,
                      ),
                      _InfoRow(
                        label: 'Start Time',
                        value: dtFmt.format(session.startTime),
                      ),
                      if (session.endTime != null)
                        _InfoRow(
                          label: 'End Time',
                          value: dtFmt.format(session.endTime!),
                        ),
                      _InfoRow(
                        label: 'Total Duration',
                        value: _formatDuration(session.activeSeconds),
                      ),
                      if (session.billingType == BillingType.perFrame)
                        _InfoRow(
                          label: 'Frames Played',
                          value:
                              '${session.framesPlayed > 0 ? session.framesPlayed : session.totalFrames}',
                        ),
                      if (session.createdByName != null)
                        _InfoRow(label: 'Started by', value: session.createdByName!),
                      if (session.endedByName != null)
                        _InfoRow(label: 'Ended by', value: session.endedByName!),
                      if (session.processedByName != null)
                        _InfoRow(label: 'Processed by', value: session.processedByName!),
                      if (session.cancelledByName != null)
                        _InfoRow(label: 'Cancelled by', value: session.cancelledByName!),
                    ],
                  ),
                ),
                const Gap(24),

                // ── Players ──
                Text('Players', style: theme.textTheme.titleMedium),
                const Gap(8),
                _SectionCard(
                  children: [
                    if (false) ...[
                      _InfoRow(
                        label: 'Team A',
                        value: session.players.join(', '),
                      ),
                      _InfoRow(
                        label: 'Team B',
                        value: const <String>[].join(', '),
                      ),
                    ] else
                      _InfoRow(
                        label: 'Players',
                        value: session.players.join(', '),
                      ),
                  ],
                ),
                const Gap(24),

                // ── Match Results & Round History ──
                if (session.rounds.isNotEmpty) ...[
                  Text('Round History', style: theme.textTheme.titleMedium),
                  const Gap(8),
                  _SectionCard(
                    children: session.rounds
                        .map(
                          (r) => Padding(
                            padding: const EdgeInsets.only(bottom: 8.0),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    r.winner == 'Friendly'
                                        ? 'Frame ${r.roundNumber} · ${(r.durationSeconds ?? 0) ~/ 60} mins${(r.overtimeMinutes ?? 0) > 0 ? " (+${r.overtimeMinutes}m OT)" : ""}'
                                        : 'Round ${r.roundNumber} · Winner: ${r.winner == 'Team A'
                                              ? session.players.join(' & ')
                                              : r.winner == 'Team B'
                                              ? const <String>[].join(' & ')
                                              : (r.winner ?? "N/A")}${r.loser != null ? " · Loser: ${r.loser == 'Team A'
                                                    ? session.players.join(' & ')
                                                    : r.loser == 'Team B'
                                                    ? const <String>[].join(' & ')
                                                    : r.loser}" : ""}${(r.overtimeMinutes ?? 0) > 0 ? " (+${r.overtimeMinutes}m OT)" : ""}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                                Text(
                                  '₹${(r.roundCost + (r.overtimeCharge ?? 0.0)).toStringAsFixed(2)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                        .toList(),
                  ),
                  const Gap(24),
                ],

                // ── Additional Games ──
                if (session.manualGameCharges.isNotEmpty) ...[
                  Text('Additional Games', style: theme.textTheme.titleMedium),
                  const Gap(8),
                  _SectionCard(
                    children: [
                      ...session.manualGameCharges.grouped().map(
                        (group) {
                          final g = group.charge;
                          return Padding(
                            padding: const EdgeInsets.symmetric(vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(
                                  child: Text(
                                    '${group.quantity}x ${g.tableName} - ${g.gameType.displayName}',
                                    style: theme.textTheme.bodyMedium,
                                  ),
                                ),
                                Text(
                                  '\u20B9${group.totalAmount.toStringAsFixed(0)}',
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }
                      ),
                    ],
                  ),
                  const Gap(16),
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
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Gap(4),
                            ...entry.value.map(
                              (o) => Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2.0,
                                ),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text(
                                      '${o.quantity}x ${o.productName}',
                                      style: theme.textTheme.bodyMedium
                                          ?.copyWith(
                                            color: theme
                                                .colorScheme
                                                .onSurfaceVariant,
                                          ),
                                    ),
                                    Text(
                                      '₹${o.total.toStringAsFixed(0)}',
                                      style: theme.textTheme.bodyMedium,
                                    ),
                                  ],
                                ),
                              ),
                            ),
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
                        value:
                            '₹${(session.baseGameCharge ?? session.gameCharge ?? 0).toStringAsFixed(2)}',
                      ),
                      if (session.baseGameCharge != null)
                        _InfoRow(
                          label: 'Grace Period',
                          value: session.tableType == TableType.indianPool
                              ? '${ref.read(appSettingsProvider).game.indianPoolGracePeriodMinutes} Mins / Frame'
                              : session.tableType == TableType.americanPool
                              ? '${ref.read(appSettingsProvider).game.americanPoolGracePeriodMinutes} Mins / Frame'
                              : 'Not Applicable',
                        ),
                    ] else ...[
                      _InfoRow(
                        label: 'Package Charge',
                        value:
                            '₹${(session.baseGameCharge ?? session.gameCharge ?? 0).toStringAsFixed(2)}',
                      ),
                    ],
                    if ((session.overtimeMinutes ?? 0) > 0) ...[
                      _InfoRow(
                        label: 'Overtime (${session.overtimeMinutes} mins)',
                        value:
                            '₹${(session.overtimeCharge ?? 0).toStringAsFixed(2)}',
                      ),
                    ],
                    if (session.overtimeMinutes != null &&
                        session.overtimeMinutes! > 0) ...[
                      const Divider(height: 16),
                      _InfoRow(
                        label: 'Total Game Charge',
                        value:
                            '₹${(session.gameCharge ?? 0).toStringAsFixed(2)}',
                      ),
                    ],
                    if (session.manualGameCharges.isNotEmpty)
                      _InfoRow(
                        label: 'Additional Games',
                        value: '₹${session.manualGameCharges.fold<double>(0, (s, g) => s + g.calculatedAmount).toStringAsFixed(2)}',
                      ),
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
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
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
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                            ),
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
                if (session.playerPaymentSplits != null &&
                    session.playerPaymentSplits!.isNotEmpty) ...[
                  _SectionCard(
                    children: session.playerPaymentSplits!.entries.map((entry) {
                      final player = entry.key;
                      final splits = entry.value;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              player,
                              style: theme.textTheme.titleSmall?.copyWith(
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const Gap(4),
                            ...splits.entries.map((splitEntry) {
                              final method = splitEntry.key;
                              final amount = splitEntry.value;
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 4.0),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        Icon(
                                          _paymentIcon(method),
                                          size: 14,
                                          color: theme
                                              .colorScheme
                                              .onSurfaceVariant,
                                        ),
                                        const Gap(4),
                                        Text(
                                          method.displayName,
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                                color: theme
                                                    .colorScheme
                                                    .onSurfaceVariant,
                                              ),
                                        ),
                                        if (method == PaymentMethod.credit) ...[
                                          const Gap(6),
                                          Text(
                                            '(${session.paymentStatus ?? 'Outstanding'})',
                                            style: theme.textTheme.labelSmall
                                                ?.copyWith(
                                                  color:
                                                      session.paymentStatus ==
                                                          'Paid'
                                                      ? AppColors.success
                                                      : (session.paymentStatus ==
                                                                'Partially Paid'
                                                            ? AppColors.warning
                                                            : AppColors
                                                                  .creditStatus),
                                                  fontWeight: FontWeight.w600,
                                                ),
                                          ),
                                        ],
                                      ],
                                    ),
                                    Text(
                                      '₹${amount.toStringAsFixed(amount.truncateToDouble() == amount ? 0 : 2)}',
                                      style: theme.textTheme.titleSmall
                                          ?.copyWith(
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.primary,
                                          ),
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
                                Icon(
                                  _paymentIcon(session.paymentMethod!),
                                  size: 16,
                                  color: theme.colorScheme.onSurface,
                                ),
                                const Gap(4),
                                Text(
                                  session.paymentMethod!.displayName,
                                  style: theme.textTheme.bodyMedium?.copyWith(
                                    fontWeight: FontWeight.w600,
                                  ),
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
                        value:
                            session.paymentStatus ??
                            (session.paymentMethod == PaymentMethod.credit
                                ? 'Outstanding'
                                : 'Paid'),
                        valueColor: session.paymentStatus == 'Paid'
                            ? AppColors.success
                            : (session.paymentStatus == 'Partially Paid'
                                  ? AppColors.warning
                                  : (session.paymentMethod ==
                                            PaymentMethod.credit
                                        ? AppColors.creditStatus
                                        : AppColors.success)),
                      ),
                      if (session.paymentMethod == PaymentMethod.credit &&
                          session.paymentStatus != 'Paid') ...[
                        _InfoRow(
                          label: 'Paid Amount',
                          value:
                              '₹${(session.paidAmount ?? 0.0).toStringAsFixed(2)}',
                          valueColor: AppColors.success,
                        ),
                        _InfoRow(
                          label: 'Remaining',
                          value:
                              '₹${(session.remainingAmount ?? (session.finalAmount ?? session.grandTotal ?? 0.0)).toStringAsFixed(2)}',
                          valueColor: AppColors.creditStatus,
                        ),
                      ],
                      if (session.endTime != null)
                        _InfoRow(
                          label: 'Payment Date',
                          value: dtFmt.format(session.endTime!),
                        ),
                    ],
                  ),
                ],
                const Gap(24),
                if (session.auditLogs.isNotEmpty) ...[
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: () => showAuditLogSheet(context, session),
                      icon: const Icon(Icons.history),
                      label: const Text('View Audit Log'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                      ),
                    ),
                  ),
                ],
                const Gap(32),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _showFullEditModal(
    BuildContext context,
    GameSession session,
  ) async {
    final verified = await AdminPasscodeDialog.verify(
      context,
      ref,
      title: 'Admin Authorization',
      subtitle: 'Enter administrator passcode to edit full bill details.',
    );
    if (verified != true || !context.mounted) return;

    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditBillSheet(session: session),
        fullscreenDialog: true,
      ),
    );
  }

  Future<void> _showEditNamesModal(
    BuildContext context,
    GameSession session,
  ) async {
    final verified = await AdminPasscodeDialog.verify(
      context,
      ref,
      title: 'Admin Authorization',
      subtitle: 'Enter administrator passcode to edit player names.',
    );
      if (verified != true || !context.mounted) return;

    final staff = ref.read(currentStaffProvider).value;
    final employeeName = staff?.name ?? 'Admin';

    final playerControllers = session.players
        .map((name) => TextEditingController(text: name))
        .toList();
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
              for (int i = 0; i < playerControllers.length; i++) ...[
                if (i > 0) const Gap(8),
                AppTextField(
                  label: playerControllers.length > 1
                      ? 'Player ${i + 1}'
                      : 'Player Name',
                  controller: playerControllers[i],
                ),
              ],
              if (session.paidBy != null) ...[
                const Gap(16),
                const Text(
                  'Payer Name (Credit / Bill)',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const Gap(8),
                AppTextField(label: 'Paid By', controller: payerController),
              ],
            ],
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
    );

    if (result == true && context.mounted) {
      final newPlayers = playerControllers.map((c) => c.text.trim()).toList();
      final newPaidBy = session.paidBy != null
          ? payerController.text.trim()
          : null;

      try {
        await ref
            .read(gamesRepositoryProvider)
            .updateGameNames(
              session: session,
              newPlayers: newPlayers,
              newPaidBy: newPaidBy,
              employeeName: employeeName,
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Player names updated and synced.'),
              backgroundColor: AppColors.success,
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: AppColors.error,
            ),
          );
        }
      }
    }

    for (final c in playerControllers) {
      c.dispose();
    }
    payerController.dispose();
  }

  Future<void> _showEditPaymentModal(
    BuildContext context,
    GameSession session,
  ) async {
    final verified = await AdminPasscodeDialog.verify(
      context,
      ref,
      title: 'Admin Authorization',
      subtitle: 'Enter administrator passcode to edit payment method.',
    );
    if (verified != true || !context.mounted) return;

    final staff = ref.read(currentStaffProvider).value;
    final employeeName = staff?.name ?? 'Admin';

    final isSplit =
        session.playerPaymentSplits != null &&
        session.playerPaymentSplits!.isNotEmpty;

    if (isSplit) {
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
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Edit Split Payments'),
            content: SizedBox(
              width: double.maxFinite,
              child: ListView(
                shrinkWrap: true,
                children: updatedMethods.entries.map((entry) {
                  final playerName = entry.key;
                  final currentMethod = entry.value;
                  final amount =
                      session.playerPaymentSplits![playerName]!.values.first;

                  final isDefault = playerName.toLowerCase().startsWith(
                    'default',
                  );

                  return Padding(
                    padding: const EdgeInsets.only(bottom: 16.0),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 2,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                playerName,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                '₹${amount.toStringAsFixed(2)}',
                                style: const TextStyle(color: Colors.grey),
                              ),
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
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              border: OutlineInputBorder(),
                            ),
                            items: PaymentMethod.values
                                .where(
                                  (m) =>
                                      !(m == PaymentMethod.credit && isDefault),
                                )
                                .map(
                                  (m) => DropdownMenuItem(
                                    value: m,
                                    child: Text(m.displayName),
                                  ),
                                )
                                .toList(),
                            onChanged: (val) {
                              if (val != null)
                                setState(
                                  () => updatedMethods[playerName] = val,
                                );
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
          await ref
              .read(gamesRepositoryProvider)
              .updateGameSplitPaymentMethods(
                session: session,
                updatedMethods: updatedMethods,
                employeeName: employeeName,
              );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Split payment methods updated & credit accounts adjusted.',
                ),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
      return;
    } else {
      final hasDefaultPlayer = session.players.any(
        (p) => p.toLowerCase().startsWith('default'),
      );
      PaymentMethod selectedMethod =
          session.paymentMethod ?? PaymentMethod.cash;
      if (selectedMethod == PaymentMethod.credit && hasDefaultPlayer) {
        selectedMethod = PaymentMethod.cash;
      }
      final payerController = TextEditingController(text: session.paidBy ?? '');

      final result = await showDialog<bool>(
        context: context,
        builder: (ctx) => StatefulBuilder(
          builder: (ctx, setState) => AlertDialog(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            title: const Text('Edit Payment Method'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DropdownButtonFormField<PaymentMethod>(
                  value: selectedMethod,
                  decoration: const InputDecoration(
                    labelText: 'Payment Method',
                    border: OutlineInputBorder(),
                  ),
                  items: PaymentMethod.values
                      .where(
                        (m) =>
                            !(m == PaymentMethod.credit &&
                                session.players.any(
                                  (p) => p.toLowerCase().startsWith('default'),
                                )),
                      )
                      .map(
                        (m) => DropdownMenuItem(
                          value: m,
                          child: Text(m.displayName),
                        ),
                      )
                      .toList(),
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
            await ref
                .read(gamesRepositoryProvider)
                .updateGamePaymentMethods(
                  session: session,
                  newPaymentMethod: selectedMethod,
                  newPaidBy: selectedMethod == PaymentMethod.credit
                      ? payerController.text.trim()
                      : null,
                  employeeName: employeeName,
                );
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text(
                  'Payment method updated & credit accounts adjusted.',
                ),
                backgroundColor: AppColors.success,
              ),
            );
          }
        } catch (e) {
          if (context.mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text('Error: $e'),
                backgroundColor: AppColors.error,
              ),
            );
          }
        }
      }
      payerController.dispose();
    }
  }
}

class _ExpandableSection extends StatefulWidget {
  final String title;
  final Widget child;

  const _ExpandableSection({required this.title, required this.child});

  @override
  State<_ExpandableSection> createState() => _ExpandableSectionState();
}

class _ExpandableSectionState extends State<_ExpandableSection> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        InkWell(
          onTap: () => setState(() => _isExpanded = !_isExpanded),
          borderRadius: BorderRadius.circular(8),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(widget.title, style: theme.textTheme.titleMedium),
                Icon(
                  _isExpanded ? Icons.expand_less : Icons.expand_more,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ],
            ),
          ),
        ),
        const Gap(4),
        if (_isExpanded) widget.child,
      ],
    );
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
