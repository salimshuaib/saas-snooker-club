import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/widgets/inputs/app_text_field.dart';
import 'package:snooker_club/core/widgets/inputs/app_dropdown.dart';
import 'package:snooker_club/features/inventory/domain/models/inventory_models.dart';
import 'package:snooker_club/features/inventory/providers/inventory_providers.dart';

class AddProductSheet extends ConsumerStatefulWidget {
  final InventoryItem? initialItem; // If provided, it's edit mode

  const AddProductSheet({super.key, this.initialItem});

  @override
  ConsumerState<AddProductSheet> createState() => _AddProductSheetState();
}

class _AddProductSheetState extends ConsumerState<AddProductSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _sellingPriceController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _initialStockController;
  String _category = 'Drinks';
  bool _isProcessing = false;

  final List<String> _categories = ['Drinks', 'Cigarettes', 'Snacks', 'Other'];

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.initialItem?.name);
    _sellingPriceController = TextEditingController(
        text: widget.initialItem?.sellingPrice.toStringAsFixed(0) ?? '');
    _purchasePriceController = TextEditingController(
        text: widget.initialItem?.purchasePrice.toStringAsFixed(0) ?? '');
    _initialStockController = TextEditingController(
        text: widget.initialItem?.currentStock.toString() ??
            InventoryItem.defaultInitialQuantity.toString());
    _category = widget.initialItem?.category ?? 'Drinks';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _sellingPriceController.dispose();
    _purchasePriceController.dispose();
    _initialStockController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final repo = ref.read(inventoryRepositoryProvider);
      final item = InventoryItem(
        id: widget.initialItem?.id ?? '',
        name: _nameController.text.trim(),
        category: _category,
        sellingPrice: double.tryParse(_sellingPriceController.text) ?? 0,
        purchasePrice: double.tryParse(_purchasePriceController.text) ?? 0,
        currentStock: widget.initialItem != null 
            ? widget.initialItem!.currentStock 
            : (int.tryParse(_initialStockController.text) ?? 0),
        totalPurchased: widget.initialItem?.totalPurchased ?? 0,
        totalSold: widget.initialItem?.totalSold ?? 0,
        isActive: widget.initialItem?.isActive ?? true,
        createdAt: widget.initialItem?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      if (widget.initialItem == null) {
        // Validation: no duplicate names in category (for Add only)
        final existingAsync = ref.read(inventoryItemsProvider);
        if (existingAsync.hasValue) {
          final isDuplicate = existingAsync.value!.any((e) =>
              e.category == _category &&
              e.name.toLowerCase() == item.name.toLowerCase());
          if (isDuplicate) {
            if (mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Product already exists in this category'),
                    backgroundColor: AppColors.error),
              );
            }
            setState(() => _isProcessing = false);
            return;
          }
        }
        await repo.addProduct(item);
      } else {
        await repo.updateProduct(item);
      }

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
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
    final isEdit = widget.initialItem != null;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEdit ? 'Edit Product' : 'Add New Product',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(24),

              AppTextField(
                label: 'Product Name',
                controller: _nameController,
                validator: (v) => v == null || v.isEmpty ? 'Required' : null,
              ),
              const Gap(16),

              AppDropdown(
                label: 'Category',
                value: _category,
                items: _categories.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _category = val);
                },
              ),
              const Gap(16),

              Row(
                children: [
                  Expanded(
                    child: AppTextField(
                      label: 'Selling Price (₹)',
                      controller: _sellingPriceController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final val = double.tryParse(v);
                        if (val == null || val < 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                  const Gap(16),
                  Expanded(
                    child: AppTextField(
                      label: 'Purchase Price (₹)',
                      controller: _purchasePriceController,
                      keyboardType: TextInputType.number,
                      validator: (v) {
                        if (v == null || v.isEmpty) return 'Required';
                        final val = double.tryParse(v);
                        if (val == null || val < 0) return 'Invalid';
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const Gap(16),

              if (!isEdit) ...[
                AppTextField(
                  label: 'Initial Quantity',
                  controller: _initialStockController,
                  keyboardType: TextInputType.number,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    final val = int.tryParse(v);
                    if (val == null || val < 0) return 'Invalid';
                    return null;
                  },
                ),
                const Gap(24),
              ],

              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isProcessing ? null : _submit,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(isEdit ? 'Save Changes' : 'Add Product'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
