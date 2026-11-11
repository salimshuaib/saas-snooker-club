import 'package:snooker_club/l10n/app_localizations.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/widgets/inputs/app_text_field.dart';
import 'package:snooker_club/features/quick_sales/domain/models/quick_sale_models.dart';
import 'package:snooker_club/features/quick_sales/providers/quick_sales_providers.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/presentation/widgets/admin_passcode_dialog.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';

class QuickSaleDetailsScreen extends ConsumerStatefulWidget {
  final QuickSale sale;

  const QuickSaleDetailsScreen({super.key, required this.sale});

  @override
  ConsumerState<QuickSaleDetailsScreen> createState() =>
      _QuickSaleDetailsScreenState();
}

class _QuickSaleDetailsScreenState
    extends ConsumerState<QuickSaleDetailsScreen> {
  QuickSale get sale => widget.sale;

  Future<void> _deleteSale(
    BuildContext context,
    WidgetRef ref, [
    QuickSale? targetSale,
  ]) async {
    final s = targetSale ?? sale;
    final passcodeVerified = await AdminPasscodeDialog.verify(
      context,
      ref,
      actionLabel: 'Delete',
      isDestructive: true,
    );

    if (passcodeVerified != true || !context.mounted) return;

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete this sale?'),
        content: const Text(
          'This action cannot be undone. Inventory stock will be restored and credit balance recalculated automatically.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(
              'Cancel',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(
              'Delete Permanently',
              style: TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );

    if (confirm != true || !context.mounted) return;

    await Future.delayed(const Duration(milliseconds: 400));
    try {
      await ref.read(quickSalesRepositoryProvider).deleteQuickSales([s]);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Quick sale deleted successfully.'),
          backgroundColor: AppColors.success,
        ),
      );
      Navigator.of(context).pop();
    } catch (e) {
      if (!context.mounted) return;
      final errorMessage = e.toString().replaceFirst(
        RegExp(r'^Exception:\s*'),
        '',
      );
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: AppColors.error,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }

  Color _getPaymentColor(PaymentMethod method) {
    switch (method) {
      case PaymentMethod.cash:
        return AppColors.available;
      case PaymentMethod.upi:
        return AppColors.running;
      case PaymentMethod.credit:
        return AppColors.warning;
    }
  }

  @override
  Widget build(BuildContext context) {
    final clubId = ref.watch(clubIdProvider);
    if (clubId == null)
      return const Scaffold(body: Center(child: CircularProgressIndicator()));

    return StreamBuilder<DocumentSnapshot>(
      stream: FirebaseFirestore.instance
          .collection('clubs')
          .doc(clubId)
          .collection('quick_sales')
          .doc(widget.sale.id)
          .snapshots(),
      builder: (context, snapshot) {
        final sale = (snapshot.hasData && snapshot.data!.data() != null)
            ? QuickSale.fromMap(
                snapshot.data!.id,
                snapshot.data!.data() as Map<String, dynamic>,
              )
            : widget.sale;
        final theme = Theme.of(context);
        final dtFmt = DateFormat('d MMM yyyy, hh:mm a');
        final paymentColor = _getPaymentColor(sale.paymentMethod);

        return Scaffold(
          appBar: AppBar(
            title: const Text('Sale Details'),
            actions: [
              PopupMenuButton<String>(
                icon: const Icon(Icons.edit_outlined),
                tooltip: 'Edit Sale Details',
                onSelected: (val) {
                  if (val == 'name') _editCustomerName(context, sale);
                  if (val == 'payment') _editPaymentMethod(context, sale);
                },
                itemBuilder: (context) => [
                  const PopupMenuItem(
                    value: 'name',
                    child: Row(
                      children: [
                        Icon(Icons.person_outline, size: 20),
                        Gap(12),
                        Text('Edit Customer Name'),
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
              IconButton(
                icon: const Icon(Icons.delete_outline, color: AppColors.error),
                tooltip: 'Delete Sale',
                onPressed: () => _deleteSale(context, ref, sale),
              ),
              const SizedBox(width: 8),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Header Card ──
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: theme.colorScheme.outlineVariant),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Total Amount',
                            style: theme.textTheme.titleMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: paymentColor.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              sale.paymentMethod.name.toUpperCase(),
                              style: TextStyle(
                                color: paymentColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const Gap(8),
                      Text(
                        '₹${sale.totalAmount.toStringAsFixed(0)}',
                        style: theme.textTheme.displaySmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppColors.primary,
                        ),
                      ),
                      if (sale.paymentMethod == PaymentMethod.credit) ...[
                        const Gap(8),
                        Row(
                          children: [
                            Text(
                              sale.paymentStatus ?? 'Outstanding',
                              style: TextStyle(
                                color: sale.paymentStatus == 'Paid'
                                    ? AppColors.success
                                    : (sale.paymentStatus == 'Partially Paid'
                                          ? AppColors.warning
                                          : AppColors.creditStatus),
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                              ),
                            ),
                            if (sale.paymentStatus != 'Paid') ...[
                              const Gap(12),
                              Text(
                                'Paid: ₹${(sale.paidAmount ?? 0.0).toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: AppColors.success,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                              const Gap(8),
                              Text(
                                'Rem: ₹${(sale.remainingAmount ?? sale.totalAmount).toStringAsFixed(0)}',
                                style: TextStyle(
                                  color: AppColors.creditStatus,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 13,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ],
                      const Gap(20),
                      Divider(
                        height: 1,
                        color: theme.colorScheme.outlineVariant.withValues(
                          alpha: 0.5,
                        ),
                      ),
                      const Gap(20),
                      Row(
                        children: [
                          _StatColumn(
                            'Customer',
                            sale.customerName?.isNotEmpty == true
                                ? sale.customerName!
                                : 'Walk-in',
                          ),
                          const SizedBox(width: 12),
                          _StatColumn('Date & Time', dtFmt.format(sale.date)),
                        ],
                      ),
                      const Gap(16),
                      Row(
                        children: [
                          _StatColumn('Processed By', sale.employeeName),
                          const SizedBox(width: 12),
                          _StatColumn(
                            'Items Count',
                            '${sale.items.length} items',
                          ),
                        ],
                      ),
                      if (sale.floorName != null) ...[
                        const Gap(16),
                        Row(
                          children: [
                            _StatColumn('Floor / Location', sale.floorName!),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                const Gap(28),

                // ── Items List ──
                Text(
                  'Purchased Items',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Gap(14),
                ...sale.items.map((item) {
                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.primary.withValues(
                              alpha: 0.1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            item.category == 'Drinks'
                                ? Icons.local_drink
                                : Icons.smoking_rooms,
                            color: theme.colorScheme.primary,
                            size: 22,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.productName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const Gap(3),
                              Text(
                                '₹${item.pricePerUnit.toStringAsFixed(0)} x ${item.quantity}',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          '₹${item.total.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.w800,
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                if (sale.auditLogs.isNotEmpty) ...[
                  const Gap(24),
                  Text(
                    'Audit History (Modifications)',
                    style: theme.textTheme.titleMedium,
                  ),
                  const Gap(8),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: sale.auditLogs
                          .map(
                            (log) => Padding(
                              padding: const EdgeInsets.only(bottom: 12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        log.field,
                                        style: theme.textTheme.bodyMedium
                                            ?.copyWith(
                                              fontWeight: FontWeight.bold,
                                            ),
                                      ),
                                      Text(
                                        dtFmt.format(log.timestamp),
                                        style: theme.textTheme.labelSmall
                                            ?.copyWith(
                                              color: theme
                                                  .colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                      ),
                                    ],
                                  ),
                                  const Gap(4),
                                  Text(
                                    'Changed from "${log.previousValue}" to "${log.newValue}" by ${log.editedBy}',
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _editCustomerName(BuildContext context, QuickSale sale) async {
    final verified = await AdminPasscodeDialog.verify(
      context,
      ref,
      title: 'Admin Authorization',
      subtitle: 'Enter administrator passcode to edit customer name.',
    );
    if (verified != true || !context.mounted) return;

    final controller = TextEditingController(text: sale.customerName ?? '');
    final formKey = GlobalKey<FormState>();

    final newName = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Edit Customer Name'),
        content: Form(
          key: formKey,
          child: AppTextField(label: 'Customer Name', controller: controller),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(AppLocalizations.of(context)!.cancel),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(controller.text.trim()),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
            child: const Text('Save Changes'),
          ),
        ],
      ),
    );

    if (newName == null ||
        newName == (sale.customerName ?? '') ||
        !context.mounted)
      return;

    try {
      await ref
          .read(quickSalesRepositoryProvider)
          .updateQuickSaleCustomerName(
            sale: sale,
            newCustomerName: newName,
            employeeName: 'Admin',
          );
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Customer name updated and synced.'),
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

  Future<void> _editPaymentMethod(BuildContext context, QuickSale sale) async {
    final verified = await AdminPasscodeDialog.verify(
      context,
      ref,
      title: 'Admin Authorization',
      subtitle: 'Enter administrator passcode to edit payment method.',
    );
    if (verified != true || !context.mounted) return;

    PaymentMethod selectedMethod = sale.paymentMethod;
    final customerController = TextEditingController(
      text: sale.customerName ?? '',
    );

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
                initialValue: selectedMethod,
                decoration: const InputDecoration(
                  labelText: 'Payment Method',
                  border: OutlineInputBorder(),
                ),
                items: PaymentMethod.values
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
                  controller: customerController,
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
      await Future.delayed(const Duration(milliseconds: 400));
      try {
        await ref
            .read(quickSalesRepositoryProvider)
            .updateQuickSalePaymentMethod(
              sale: sale,
              newPaymentMethod: selectedMethod,
              newCustomerName: selectedMethod == PaymentMethod.credit
                  ? customerController.text.trim()
                  : null,
              employeeName: 'Admin',
            );
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Payment method updated & credit accounts synced.'),
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
    customerController.dispose();
  }
}

class _StatColumn extends StatelessWidget {
  final String label;
  final String value;

  const _StatColumn(this.label, this.value);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: theme.textTheme.labelSmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          const Gap(4),
          Text(
            value,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}
