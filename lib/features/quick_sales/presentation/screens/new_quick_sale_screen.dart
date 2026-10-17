import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_club/core/routes/route_names.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/theme/app_shadows.dart';
import 'package:snooker_club/core/utils/debouncer.dart';
import 'package:snooker_club/core/widgets/inputs/app_text_field.dart';
import 'package:snooker_club/core/widgets/inputs/app_dropdown.dart';
import 'package:snooker_club/features/inventory/providers/inventory_providers.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/quick_sales/domain/models/quick_sale_models.dart';
import 'package:snooker_club/features/quick_sales/providers/quick_sales_providers.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';

class NewQuickSaleScreen extends ConsumerStatefulWidget {
  const NewQuickSaleScreen({super.key});

  @override
  ConsumerState<NewQuickSaleScreen> createState() => _NewQuickSaleScreenState();
}

class _NewQuickSaleScreenState extends ConsumerState<NewQuickSaleScreen> {
  final _customerNameController = TextEditingController();
  final _searchController = TextEditingController();
  final Debouncer _debouncer = Debouncer(milliseconds: 300);
  PaymentMethod _paymentMethod = PaymentMethod.cash;
  final Map<String, int> _cart = {}; // productId -> quantity
  bool _isProcessing = false;
  String _searchQuery = '';
  String _selectedCategory = 'All';

  @override
  void dispose() {
    _debouncer.dispose();
    _customerNameController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  void _addToCart(
    String productId,
    int availableStock, [
    VoidCallback? onModalUpdate,
    bool isFood = false,
    bool isAvailable = true,
  ]) {
    if (isFood && !isAvailable) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('This food item is currently unavailable'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() {
      final current = _cart[productId] ?? 0;
      if (isFood || current < availableStock) {
        _cart[productId] = current + 1;
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Not enough stock available'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    });
    onModalUpdate?.call();
  }

  void _removeFromCart(String productId, [VoidCallback? onModalUpdate]) {
    setState(() {
      final current = _cart[productId] ?? 0;
      if (current > 1) {
        _cart[productId] = current - 1;
      } else {
        _cart.remove(productId);
      }
    });
    onModalUpdate?.call();
  }

  Future<void> _processSale() async {
    if (_isProcessing) return;
    if (_cart.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Cart is empty'),
          backgroundColor: AppColors.warning,
        ),
      );
      return;
    }

    if (_paymentMethod == PaymentMethod.credit &&
        _customerNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Customer Name is required for Credit payments.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isProcessing = true);

    try {
      final itemsAsync = ref.read(inventoryItemsProvider);
      if (!itemsAsync.hasValue) throw Exception('Inventory not loaded');

      final inventoryItems = itemsAsync.value!;
      final List<GameOrder> saleItems = [];
      double totalAmount = 0;

      for (final entry in _cart.entries) {
        final product = inventoryItems.firstWhere((p) => p.id == entry.key);
        saleItems.add(
          GameOrder(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            productId: product.id,
            productName: product.name,
            category: product.category,
            quantity: entry.value,
            pricePerUnit: product.sellingPrice,
            playerName: _customerNameController.text.trim().isEmpty
                ? 'Walk-in'
                : _customerNameController.text.trim(),
          ),
        );
        totalAmount += (product.sellingPrice * entry.value);
      }

      final staff = ref.read(currentStaffProvider).value;
      final sale = QuickSale(
        id: '',
        customerName: _customerNameController.text.trim().isEmpty
            ? null
            : _customerNameController.text.trim(),
        items: saleItems,
        totalAmount: totalAmount,
        paymentMethod: _paymentMethod,
        employeeName: staff?.name ?? 'Admin',
        date: DateTime.now(),
      );

      await ref.read(quickSalesRepositoryProvider).createQuickSale(sale);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Sale completed successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error processing sale: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final inventoryAsync = ref.watch(inventoryItemsProvider);
    final customersAsync = ref.watch(allCustomersProvider);
    final customerNames =
        customersAsync.value?.map((c) => c.name).toList() ?? [];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quick Sale'),
        actions: [
          TextButton.icon(
            onPressed: () => context.push(RouteNames.quickSales),
            icon: Icon(
              Icons.history,
              size: 20,
              color: theme.colorScheme.primary,
            ),
            label: Text(
              'History',
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          if (_cart.isNotEmpty) ...[
            const SizedBox(width: 4),
            TextButton.icon(
              onPressed: () => setState(() => _cart.clear()),
              icon: const Icon(
                Icons.delete_outline,
                size: 20,
                color: AppColors.error,
              ),
              label: const Text(
                'Clear',
                style: TextStyle(
                  color: AppColors.error,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
          const SizedBox(width: 8),
        ],
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final isMobile = constraints.maxWidth < 750;

          if (isMobile) {
            return Column(
              children: [
                _buildSearchAndFilters(theme, inventoryAsync),
                Expanded(child: _buildProductsList(theme, inventoryAsync)),
                if (_cart.isNotEmpty)
                  _buildStickyCartBanner(theme, customerNames),
              ],
            );
          } else {
            return Row(
              children: [
                Expanded(
                  child: Column(
                    children: [
                      _buildSearchAndFilters(theme, inventoryAsync),
                      Expanded(
                        child: _buildProductsList(theme, inventoryAsync),
                      ),
                    ],
                  ),
                ),
                const VerticalDivider(width: 1),
                SizedBox(
                  width: 380,
                  child: _buildCartPanel(theme, customerNames),
                ),
              ],
            );
          }
        },
      ),
    );
  }

  Widget _buildSearchAndFilters(
    ThemeData theme,
    AsyncValue<List<dynamic>> inventoryAsync,
  ) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        border: Border(
          bottom: BorderSide(color: theme.colorScheme.outlineVariant),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // Fixed Search Bar
          TextField(
            controller: _searchController,
            onChanged: (val) => _debouncer.run(
              () => setState(() => _searchQuery = val.trim().toLowerCase()),
            ),
            decoration: InputDecoration(
              hintText: 'Search products by name...',
              hintStyle: TextStyle(
                color: theme.colorScheme.onSurfaceVariant,
                fontSize: 14,
              ),
              prefixIcon: Icon(
                Icons.search,
                size: 20,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, size: 18),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
              contentPadding: const EdgeInsets.symmetric(
                vertical: 10,
                horizontal: 16,
              ),
              isDense: true,
              filled: true,
              fillColor: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.4,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const Gap(12),
          // Category Chips
          inventoryAsync.maybeWhen(
            data: (items) {
              final Set<String> categories = {'All'};
              for (final i in items) {
                if (i.category.isNotEmpty) categories.add(i.category);
              }

              return SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: categories.map((cat) {
                    final isSelected = _selectedCategory == cat;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: FilterChip(
                        label: Text(cat),
                        selected: isSelected,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = cat),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : theme.colorScheme.onSurface,
                          fontWeight: isSelected
                              ? FontWeight.bold
                              : FontWeight.w500,
                          fontSize: 13,
                        ),
                        backgroundColor: theme
                            .colorScheme
                            .surfaceContainerHighest
                            .withValues(alpha: 0.5),
                        selectedColor: AppColors.primary,
                        checkmarkColor: Colors.white,
                        showCheckmark: false,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                        ),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        side: BorderSide(
                          color: isSelected
                              ? AppColors.primary
                              : theme.colorScheme.outlineVariant,
                        ),
                      ),
                    );
                  }).toList(),
                ),
              );
            },
            orElse: () => const SizedBox(height: 36),
          ),
        ],
      ),
    );
  }

  Widget _buildProductsList(
    ThemeData theme,
    AsyncValue<List<dynamic>> inventoryAsync,
  ) {
    return inventoryAsync.when(
      data: (items) {
        final activeItems = items.where((i) {
          if (!i.isActive) return false;
          if (_selectedCategory != 'All' && i.category != _selectedCategory)
            return false;
          if (_searchQuery.isNotEmpty &&
              !i.name.toLowerCase().contains(_searchQuery))
            return false;
          return true;
        }).toList();

        if (activeItems.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.inventory_2_outlined,
                  size: 48,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.5,
                  ),
                ),
                const Gap(12),
                Text(
                  'No products found',
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          );
        }

        return ListView.separated(
          padding: const EdgeInsets.all(16),
          itemCount: activeItems.length,
          separatorBuilder: (context, index) => const Gap(10),
          itemBuilder: (context, index) {
            final item = activeItems[index];
            final inCart = _cart[item.id] ?? 0;
            final isLowStock = item.currentStock <= 5;

            return InkWell(
              onTap: () => _addToCart(
                item.id,
                item.currentStock,
                null,
                item.isFood,
                item.isAvailable,
              ),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: inCart > 0
                      ? AppColors.primary.withValues(alpha: 0.08)
                      : theme.colorScheme.surface,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: inCart > 0
                        ? AppColors.primary
                        : theme.colorScheme.outlineVariant,
                    width: inCart > 0 ? 1.5 : 1,
                  ),
                ),
                child: Row(
                  children: [
                    // Product Icon
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        item.isFood
                            ? Icons.fastfood
                            : (item.category == 'Drinks'
                                ? Icons.local_drink
                                : Icons.smoking_rooms),
                        size: 22,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Gap(14),
                    // Name & Stock
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.name,
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                            ),
                          ),
                          const Gap(4),
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: (item.isFood
                                          ? (item.isAvailable
                                              ? AppColors.available
                                              : AppColors.error)
                                          : (isLowStock
                                              ? AppColors.warning
                                              : AppColors.available))
                                      .withValues(
                                        alpha: 0.15,
                                      ),
                                  borderRadius: BorderRadius.circular(6),
                                ),
                                child: Text(
                                  item.isFood
                                      ? (item.isAvailable
                                          ? 'Available'
                                          : 'Unavailable')
                                      : '${item.currentStock} in stock',
                                  style: TextStyle(
                                    color: item.isFood
                                        ? (item.isAvailable
                                            ? AppColors.available
                                            : AppColors.error)
                                        : (isLowStock
                                            ? AppColors.warning
                                            : AppColors.available),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    // Price & Action Button
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '₹${item.sellingPrice.toStringAsFixed(0)}',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: AppColors.primary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const Gap(4),
                        if (inCart > 0)
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              InkWell(
                                onTap: () => _removeFromCart(item.id),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: theme
                                        .colorScheme
                                        .surfaceContainerHighest,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Icon(
                                    Icons.remove,
                                    size: 16,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                ),
                                child: Text(
                                  '$inCart',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                              InkWell(
                                onTap: () => _addToCart(
                                  item.id,
                                  item.currentStock,
                                  null,
                                  item.isFood,
                                  item.isAvailable,
                                ),
                                borderRadius: BorderRadius.circular(14),
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: AppColors.primary,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Icon(
                                    Icons.add,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ],
                          )
                        else
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(16),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.add,
                                  size: 14,
                                  color: AppColors.primary,
                                ),
                                const Gap(2),
                                Text(
                                  'Add',
                                  style: TextStyle(
                                    color: AppColors.primary,
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
      loading: () => ListView.separated(
        padding: const EdgeInsets.all(16),
        itemCount: 6,
        separatorBuilder: (_, __) => const Gap(10),
        itemBuilder: (_, __) => Container(
          height: 72,
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.3,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
        ),
      ),
      error: (err, stack) => Center(child: Text('Error: $err')),
    );
  }

  Widget _buildStickyCartBanner(ThemeData theme, List<String> customerNames) {
    double total = 0;
    int totalItems = 0;
    final items = ref.read(inventoryItemsProvider).value ?? [];
    for (final entry in _cart.entries) {
      final index = items.indexWhere((p) => p.id == entry.key);
      if (index != -1) {
        total += items[index].sellingPrice * entry.value;
        totalItems += entry.value;
      }
    }

    return Container(
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.centerLeft,
          end: Alignment.centerRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppShadows.medium,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            showModalBottomSheet(
              useRootNavigator: true,
              context: context,
              isScrollControlled: true,
              backgroundColor: theme.colorScheme.surface,
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
              ),
              builder: (sheetContext) => StatefulBuilder(
                builder: (stfContext, setModalState) {
                  final bottomInset = MediaQuery.of(sheetContext).viewInsets.bottom;
                  return Padding(
                    padding: EdgeInsets.only(bottom: bottomInset),
                    child: Container(
                      constraints: BoxConstraints(
                        maxHeight: MediaQuery.of(sheetContext).size.height * 0.9 - bottomInset,
                      ),
                    child: _buildCartPanel(
                      theme,
                      customerNames,
                      isModal: true,
                      onModalUpdate: () => setModalState(() {}),
                      sheetContext: sheetContext,
                    ),
                  ),
                );
                },
              ),
            );
          },
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$totalItems Items',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const Gap(14),
                    Text(
                      '₹${total.toStringAsFixed(0)}',
                      style: theme.textTheme.titleLarge?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    Text(
                      'View Cart',
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const Gap(4),
                    const Icon(
                      Icons.arrow_forward,
                      color: Colors.white,
                      size: 20,
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCartPanel(
    ThemeData theme,
    List<String> customerNames, {
    bool isModal = false,
    VoidCallback? onModalUpdate,
    BuildContext? sheetContext,
  }) {
    double total = 0;
    if (_cart.isNotEmpty) {
      final items = ref.read(inventoryItemsProvider).value ?? [];
      for (final entry in _cart.entries) {
        final index = items.indexWhere((p) => p.id == entry.key);
        if (index != -1) {
          total += items[index].sellingPrice * entry.value;
        }
      }
    }

    return Container(
      color: theme.colorScheme.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (isModal) ...[
            Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: theme.colorScheme.outlineVariant,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Cart & Checkout',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(sheetContext ?? context),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
          ],
          Flexible(
            child: _cart.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shopping_cart_outlined,
                          size: 56,
                          color: theme.colorScheme.onSurfaceVariant.withValues(
                            alpha: 0.4,
                          ),
                        ),
                        const Gap(12),
                        Text(
                          'Cart is empty',
                          style: theme.textTheme.titleMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const Gap(4),
                        Text(
                          'Select items from the list to begin',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    shrinkWrap: true,
                    padding: const EdgeInsets.all(16),
                    itemCount: _cart.length,
                    itemBuilder: (context, index) {
                      final productId = _cart.keys.elementAt(index);
                      final quantity = _cart[productId]!;

                      final items =
                          ref.read(inventoryItemsProvider).value ?? [];
                      final pIndex = items.indexWhere((p) => p.id == productId);
                      if (pIndex == -1) return const SizedBox();
                      final product = items[pIndex];

                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.35),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant,
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    product.name,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 14,
                                    ),
                                  ),
                                  const Gap(2),
                                  Text(
                                    '₹${product.sellingPrice.toStringAsFixed(0)} each',
                                    style: TextStyle(
                                      color: theme.colorScheme.onSurfaceVariant,
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                InkWell(
                                  onTap: () =>
                                      _removeFromCart(productId, onModalUpdate),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.error.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.remove,
                                      size: 18,
                                      color: AppColors.error,
                                    ),
                                  ),
                                ),
                                Container(
                                  constraints: const BoxConstraints(
                                    minWidth: 36,
                                  ),
                                  alignment: Alignment.center,
                                  child: Text(
                                    '$quantity',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 15,
                                    ),
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _addToCart(
                                    productId,
                                    product.currentStock,
                                    onModalUpdate,
                                    product.isFood,
                                    product.isAvailable,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  child: Container(
                                    padding: const EdgeInsets.all(6),
                                    decoration: BoxDecoration(
                                      color: AppColors.primary.withValues(
                                        alpha: 0.1,
                                      ),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(
                                      Icons.add,
                                      size: 18,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),

          // Checkout Section
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.6,
              ),
              border: Border(
                top: BorderSide(color: theme.colorScheme.outlineVariant),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              mainAxisSize: MainAxisSize.min,
              children: [
                Autocomplete<String>(
                  optionsBuilder: (TextEditingValue textEditingValue) {
                    if (textEditingValue.text.isEmpty) {
                      return customerNames;
                    }
                    return customerNames.where((String option) {
                      return option.toLowerCase().contains(
                        textEditingValue.text.toLowerCase(),
                      );
                    });
                  },
                  onSelected: (String selection) {
                    _customerNameController.text = selection;
                    onModalUpdate?.call();
                  },
                  fieldViewBuilder:
                      (context, controller, focusNode, onFieldSubmitted) {
                        controller.addListener(() {
                          if (_customerNameController.text != controller.text) {
                            _customerNameController.text = controller.text;
                            onModalUpdate?.call();
                          }
                        });

                        if (controller.text.isEmpty &&
                            _customerNameController.text.isNotEmpty) {
                          controller.text = _customerNameController.text;
                        }

                        return AppTextField(
                          label: _paymentMethod == PaymentMethod.credit
                              ? 'Customer Name (Required for Credit)'
                              : 'Customer Name (Optional)',
                          controller: controller,
                          focusNode: focusNode,
                          hint: 'Walk-in',
                        );
                      },
                ),
                const Gap(12),
                AppDropdown(
                  label: 'Payment Method',
                  value: _paymentMethod.name,
                  items: PaymentMethod.values
                      .map(
                        (e) => DropdownMenuItem(
                          value: e.name,
                          child: Text(e.name.toUpperCase()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    if (val != null) {
                      setState(() {
                        _paymentMethod = PaymentMethod.values.firstWhere(
                          (e) => e.name == val,
                        );
                      });
                      onModalUpdate?.call();
                    }
                  },
                ),
                const Gap(20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Total Amount',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '₹${total.toStringAsFixed(0)}',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        color: AppColors.primary,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
                const Gap(16),
                FilledButton(
                  onPressed: _isProcessing || _cart.isEmpty
                      ? null
                      : () {
                          if (isModal) Navigator.pop(context);
                          _processSale();
                        },
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Complete Sale',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
