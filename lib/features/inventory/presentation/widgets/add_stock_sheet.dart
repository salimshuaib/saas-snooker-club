import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/widgets/inputs/app_text_field.dart';
import 'package:snooker_club/core/widgets/inputs/app_dropdown.dart';
import 'package:snooker_club/features/inventory/domain/models/inventory_models.dart';
import 'package:snooker_club/features/inventory/providers/inventory_providers.dart';
import 'package:snooker_club/features/floors/providers/floor_providers.dart';

class AddStockSheet extends ConsumerStatefulWidget {
  final InventoryItem item;

  const AddStockSheet({super.key, required this.item});

  @override
  ConsumerState<AddStockSheet> createState() => _AddStockSheetState();
}

class _AddStockSheetState extends ConsumerState<AddStockSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _quantityController;
  late TextEditingController _purchasePriceController;
  late TextEditingController _notesController;
  bool _isProcessing = false;
  String? _selectedFloorId;
  String? _selectedFloorName;

  @override
  void initState() {
    super.initState();
    _quantityController = TextEditingController();
    _purchasePriceController = TextEditingController(
      text: widget.item.purchasePrice > 0
          ? widget.item.purchasePrice.toStringAsFixed(0)
          : '',
    );
    _notesController = TextEditingController();
    _selectedFloorId = widget.item.floorId;
    _selectedFloorName = widget.item.floorName;

    if (_selectedFloorId == null) {
      final activeFloor = ref.read(selectedFloorProvider);
      if (activeFloor != null) {
        _selectedFloorId = activeFloor.id;
        _selectedFloorName = activeFloor.name;
      }
    }
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _purchasePriceController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final repo = ref.read(inventoryRepositoryProvider);
      await repo.addStock(
        item: widget.item,
        quantityAdded: int.parse(_quantityController.text),
        purchasePrice: double.parse(_purchasePriceController.text),
        employeeName: 'Admin', // Static for now until auth is fully linked
        notes: _notesController.text.trim().isEmpty
            ? null
            : _notesController.text.trim(),
        targetFloorId: _selectedFloorId,
        targetFloorName: _selectedFloorName,
      );

      if (mounted) {
        final messenger = ScaffoldMessenger.of(context);
        Navigator.pop(context);
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Stock added successfully'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
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
    final hasFloors = ref.watch(hasFloorsProvider);
    final floors = ref.watch(floorsProvider).value ?? [];

    if (_selectedFloorId != null &&
        _selectedFloorName == null &&
        floors.isNotEmpty) {
      final matched = floors.where((f) => f.id == _selectedFloorId);
      if (matched.isNotEmpty) {
        _selectedFloorName = matched.first.name;
      }
    }

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
                'Add Stock',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Gap(4),
              Row(
                children: [
                  Text(
                    widget.item.name,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (widget.item.floorName != null) ...[
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        widget.item.floorName!,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
              const Gap(20),

              if (hasFloors && floors.length > 1) ...[
                AppDropdown<String?>(
                  label: 'Floor / Location',
                  value: floors.any((f) => f.id == _selectedFloorId)
                      ? _selectedFloorId
                      : null,
                  items: [
                    const DropdownMenuItem(
                      value: null,
                      child: Row(
                        children: [
                          Icon(Icons.domain, size: 16),
                          SizedBox(width: 8),
                          Text('All Floors / General'),
                        ],
                      ),
                    ),
                    ...floors.map((f) => DropdownMenuItem(
                          value: f.id,
                          child: Row(
                            children: [
                              const Icon(Icons.layers_outlined, size: 16),
                              const SizedBox(width: 8),
                              Text(f.name),
                            ],
                          ),
                        )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedFloorId = val;
                      if (val == null) {
                        _selectedFloorName = null;
                      } else {
                        final matched = floors.where((f) => f.id == val);
                        _selectedFloorName =
                            matched.isNotEmpty ? matched.first.name : null;
                      }
                    });
                  },
                ),
                const Gap(16),
              ],

              AppTextField(
                label: 'Quantity Added',
                controller: _quantityController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final val = int.tryParse(v);
                  if (val == null || val <= 0) return 'Must be > 0';
                  return null;
                },
              ),
              const Gap(16),

              AppTextField(
                label: 'Purchase Price (₹) per unit',
                controller: _purchasePriceController,
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Required';
                  final val = double.tryParse(v);
                  if (val == null || val < 0) return 'Invalid';
                  return null;
                },
              ),
              const Gap(16),

              AppTextField(
                label: 'Notes (Optional)',
                controller: _notesController,
              ),
              const Gap(24),

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
                      : const Text('Confirm Stock Addition'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
