import 'package:snooker_club/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/routes/route_names.dart';

import 'package:intl/intl.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/quick_sales/providers/quick_sales_providers.dart';
import 'package:snooker_club/features/quick_sales/domain/models/quick_sale_models.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/presentation/widgets/admin_passcode_dialog.dart';
import 'package:snooker_club/features/floors/providers/floor_providers.dart';
import 'package:snooker_club/features/floors/domain/models/floor_model.dart';

class QuickSalesScreen extends ConsumerStatefulWidget {
  const QuickSalesScreen({super.key});

  @override
  ConsumerState<QuickSalesScreen> createState() => _QuickSalesScreenState();
}

class _QuickSalesScreenState extends ConsumerState<QuickSalesScreen> {
  bool _isSelectionMode = false;
  final Set<String> _selectedSaleIds = {};
  String? _selectedFloorId;

  @override
  void initState() {
    super.initState();
    _selectedFloorId = ref.read(selectedFloorIdProvider);
  }

  void _enterSelectionMode(QuickSale sale) {
    setState(() {
      _isSelectionMode = true;
      _selectedSaleIds.add(sale.id);
    });
  }

  void _toggleSelection(String saleId) {
    setState(() {
      if (_selectedSaleIds.contains(saleId)) {
        _selectedSaleIds.remove(saleId);
        if (_selectedSaleIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedSaleIds.add(saleId);
      }
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedSaleIds.clear();
    });
  }

  Future<void> _onDeleteSelected(List<QuickSale> allSales) async {
    if (_selectedSaleIds.isEmpty) return;
    final passcodeVerified = await AdminPasscodeDialog.verify(
      context,
      ref,
      actionLabel: 'Delete',
      isDestructive: true,
    );
    if (passcodeVerified != true || !mounted) return;

    final selectedCount = _selectedSaleIds.length;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Text(
          'Delete $selectedCount selected sale${selectedCount > 1 ? 's' : ''}?',
        ),
        content: const Text(
          'This action cannot be undone. Inventory stock will be restored and credit balances recalculated automatically.',
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

    if (confirm != true || !mounted) return;

    await Future.delayed(const Duration(milliseconds: 400));
    final salesToDelete = allSales
        .where((s) => _selectedSaleIds.contains(s.id))
        .toList();

    try {
      await ref
          .read(quickSalesRepositoryProvider)
          .deleteQuickSales(salesToDelete);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$selectedCount quick sale${selectedCount > 1 ? 's' : ''} deleted successfully.',
          ),
          backgroundColor: AppColors.success,
        ),
      );
      _exitSelectionMode();
    } catch (e) {
      if (!mounted) return;
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

  Future<void> _pickDate(BuildContext context, WidgetRef ref) async {
    final currentDate = ref.read(quickSalesDateProvider);
    final picked = await showDatePicker(
      context: context,
      initialDate: currentDate,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.dark(
              primary: AppColors.primary,
              surface: Theme.of(context).colorScheme.surface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      ref.read(quickSalesDateProvider.notifier).setDate(picked);
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
    final theme = Theme.of(context);
    final selectedDate = ref.watch(quickSalesDateProvider);
    final salesAsync = ref.watch(quickSalesProvider);

    final hasFloors = ref.watch(hasFloorsProvider);
    final floors = ref.watch(floorsProvider).value ?? [];

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              ),
              title: Text('${_selectedSaleIds.length} Selected'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete, color: AppColors.error),
                  onPressed: () => salesAsync.maybeWhen(
                    data: (sales) => _onDeleteSelected(sales),
                    orElse: () {},
                  ),
                ),
              ],
            )
          : AppBar(
              title: Text(AppLocalizations.of(context)!.quickSales),
              actions: [
                TextButton.icon(
                  onPressed: () => _pickDate(context, ref),
                  icon: const Icon(Icons.calendar_month, size: 18),
                  label: Text(
                    DateFormat('dd MMM yyyy').format(selectedDate),
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
      body: salesAsync.when(
        data: (sales) {
          final displayedSales = sales.where((sale) {
            if (_selectedFloorId != null &&
                sale.floorId != _selectedFloorId) {
              return false;
            }
            return true;
          }).toList();

          final sortedFloors = List<FloorModel>.from(floors);
          sortedFloors.sort((a, b) {
            int getRank(FloorModel f) {
              final n = f.name.toLowerCase();
              if (n.contains('first') || n.contains('floor 1') || n.contains('1st') || n == '1') return 1;
              if (n.contains('second') || n.contains('floor 2') || n.contains('2nd') || n == '2') return 2;
              if (n.contains('third') || n.contains('floor 3') || n.contains('3rd') || n == '3') return 3;
              if (n.contains('fourth') || n.contains('floor 4') || n.contains('4th') || n == '4') return 4;
              return 10 + f.order;
            }
            final rankA = getRank(a);
            final rankB = getRank(b);
            if (rankA != rankB) return rankA.compareTo(rankB);
            return a.name.compareTo(b.name);
          });

          return Column(
            children: [
              if (hasFloors && sortedFloors.length > 1)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                  child: Container(
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: theme.colorScheme.outlineVariant,
                      ),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 2,
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.layers_outlined,
                          size: 18,
                          color: theme.colorScheme.primary,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Floor:',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String?>(
                              value: (sortedFloors
                                          .any((f) => f.id == _selectedFloorId) ||
                                      _selectedFloorId == null)
                                  ? _selectedFloorId
                                  : null,
                              isExpanded: true,
                              icon: Icon(
                                Icons.keyboard_arrow_down_rounded,
                                color: theme.colorScheme.primary,
                              ),
                              borderRadius: BorderRadius.circular(12),
                              dropdownColor: theme.colorScheme.surface,
                              style: TextStyle(
                                color: theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                                fontSize: 14,
                              ),
                              items: [
                                const DropdownMenuItem<String?>(
                                  value: null,
                                  child: Text(
                                    'All Floors',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                                ...sortedFloors.map((floor) =>
                                    DropdownMenuItem<String?>(
                                      value: floor.id,
                                      child: Text(
                                        floor.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14,
                                        ),
                                      ),
                                    )),
                              ],
                              onChanged: (newFloorId) {
                                setState(() {
                                  _selectedFloorId = newFloorId;
                                });
                              },
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              Expanded(
                child: displayedSales.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.point_of_sale_outlined,
                              size: 64,
                              color:
                                  theme.colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.4,
                              ),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No quick sales found.',
                              style: theme.textTheme.titleMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Tap + New Sale below to get started',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ],
                        ),
                      )
                    : ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: displayedSales.length,
                        itemBuilder: (context, index) {
                          final sale = displayedSales[index];
                          final paymentColor =
                              _getPaymentColor(sale.paymentMethod);
                          final isSelected =
                              _selectedSaleIds.contains(sale.id);

                          return GestureDetector(
                            onLongPress: () {
                              if (!_isSelectionMode) {
                                _enterSelectionMode(sale);
                              } else {
                                _toggleSelection(sale.id);
                              }
                            },
                            onTap: () {
                              if (_isSelectionMode) {
                                _toggleSelection(sale.id);
                              } else {
                                context.push(
                                  '${RouteNames.quickSales}/details',
                                  extra: sale,
                                );
                              }
                            },
                            child: Card(
                              margin: const EdgeInsets.only(bottom: 12),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(
                                  color: isSelected
                                      ? AppColors.primary
                                      : theme.colorScheme.outlineVariant,
                                  width: isSelected ? 2.0 : 1.0,
                                ),
                              ),
                              color: isSelected
                                  ? AppColors.primary.withValues(alpha: 0.15)
                                  : theme.colorScheme.surface,
                              child: Padding(
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        if (_isSelectionMode) ...[
                                          Icon(
                                            isSelected
                                                ? Icons.check_circle
                                                : Icons.radio_button_unchecked,
                                            color: isSelected
                                                ? AppColors.primary
                                                : theme.colorScheme
                                                    .onSurfaceVariant
                                                    .withValues(alpha: 0.5),
                                            size: 22,
                                          ),
                                          const SizedBox(width: 12),
                                        ],
                                        Expanded(
                                          child: Text(
                                            sale.customerName?.isNotEmpty ==
                                                    true
                                                ? sale.customerName!
                                                : 'Walk-in Customer',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme.textTheme.titleMedium
                                                ?.copyWith(
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 12),
                                        Text(
                                          '₹${sale.totalAmount.toStringAsFixed(0)}',
                                          style: theme.textTheme.titleMedium
                                              ?.copyWith(
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.primary,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      children: [
                                        Container(
                                          padding:
                                              const EdgeInsets.symmetric(
                                            horizontal: 10,
                                            vertical: 4,
                                          ),
                                          decoration: BoxDecoration(
                                            color: paymentColor
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: Text(
                                            sale.paymentMethod.name
                                                .toUpperCase(),
                                            style: TextStyle(
                                              color: paymentColor,
                                              fontSize: 11,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                        if (sale.floorName != null) ...[
                                          const SizedBox(width: 8),
                                          Container(
                                            padding:
                                                const EdgeInsets.symmetric(
                                              horizontal: 8,
                                              vertical: 4,
                                            ),
                                            decoration: BoxDecoration(
                                              color: theme.colorScheme
                                                  .secondaryContainer
                                                  .withValues(alpha: 0.5),
                                              borderRadius:
                                                  BorderRadius.circular(8),
                                            ),
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Icon(
                                                  Icons.layers_outlined,
                                                  size: 11,
                                                  color: theme.colorScheme
                                                      .onSecondaryContainer,
                                                ),
                                                const SizedBox(width: 4),
                                                Text(
                                                  sale.floorName!,
                                                  style: TextStyle(
                                                    color: theme.colorScheme
                                                        .onSecondaryContainer,
                                                    fontSize: 10,
                                                    fontWeight:
                                                        FontWeight.w600,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        ],
                                        const SizedBox(width: 10),
                                        Expanded(
                                          child: Text(
                                            sale.items
                                                .map((i) => i.productName)
                                                .join(', '),
                                            style: theme
                                                .textTheme.bodyMedium
                                                ?.copyWith(
                                              color: theme.colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 12),
                                    Divider(
                                      height: 1,
                                      color: theme
                                          .colorScheme.outlineVariant
                                          .withValues(
                                        alpha: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 10),
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            'Processed by: ${sale.employeeName}',
                                            maxLines: 1,
                                            overflow: TextOverflow.ellipsis,
                                            style: theme
                                                .textTheme.labelSmall
                                                ?.copyWith(
                                              color: theme.colorScheme
                                                  .onSurfaceVariant,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          DateFormat('hh:mm a')
                                              .format(sale.date),
                                          style: theme
                                              .textTheme.labelSmall
                                              ?.copyWith(
                                            color: theme.colorScheme
                                                .onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        },
                      ),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Error: $err')),
      ),
      floatingActionButton: _isSelectionMode
          ? null
          : FloatingActionButton.extended(
              onPressed: () {
                context.push('${RouteNames.quickSales}/new');
              },
              icon: const Icon(Icons.add),
              label: const Text(
                'New Sale',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
            ),
    );
  }
}
