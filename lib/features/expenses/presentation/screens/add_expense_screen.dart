import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
// unused repo import
import 'package:snooker_club/features/expenses/domain/models/expense_models.dart';
import 'package:snooker_club/features/expenses/providers/expense_providers.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
// unused settings models
import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:snooker_club/features/floors/providers/floor_providers.dart';

class AddExpenseScreen extends ConsumerStatefulWidget {
  final Expense? expenseToEdit;

  const AddExpenseScreen({super.key, this.expenseToEdit});

  @override
  ConsumerState<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends ConsumerState<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _titleController;
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;

  late String _selectedCategory;
  late PaymentMethod _selectedPaymentMethod;
  late DateTime _selectedDate;
  String? _selectedFloorId;
  String? _selectedFloorName;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.expenseToEdit;
    _titleController = TextEditingController(text: edit?.title ?? '');
    _amountController = TextEditingController(
      text: edit != null ? edit.amount.toStringAsFixed(0) : '',
    );
    _descriptionController = TextEditingController(text: edit?.description ?? '');
    _selectedCategory = edit?.category ?? 'Maintenance & Repairs';
    _selectedPaymentMethod = edit?.paymentMethod ?? PaymentMethod.cash;
    _selectedDate = edit?.date ?? DateTime.now();
    _selectedFloorId = edit?.floorId ?? ref.read(selectedFloorIdProvider);
    _selectedFloorName = edit?.floorName;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _pickDateTime() async {
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 1)),
    );
    if (pickedDate == null || !mounted) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.fromDateTime(_selectedDate),
    );
    if (pickedTime == null || !mounted) return;

    setState(() {
      _selectedDate = DateTime(
        pickedDate.year,
        pickedDate.month,
        pickedDate.day,
        pickedTime.hour,
        pickedTime.minute,
      );
    });
  }

  Future<void> _showAddCustomCategoryDialog() async {
    final textCtrl = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Custom Category'),
        content: TextField(
          controller: textCtrl,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Category Name',
            hintText: 'e.g. Cafe Groceries, Marketing',
          ),
          textCapitalization: TextCapitalization.words,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final val = textCtrl.text.trim();
              if (val.isNotEmpty) {
                Navigator.pop(ctx, val);
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );

    if (result != null && result.isNotEmpty && mounted) {
      final settings = ref.read(appSettingsProvider);
      final currentCustom = List<String>.from(settings.expense.customCategories);
      if (!currentCustom.contains(result)) {
        currentCustom.add(result);
        await ref
            .read(appSettingsProvider.notifier)
            .updateExpenseSettings(settings.expense.copyWith(customCategories: currentCustom));
      }
      setState(() {
        _selectedCategory = result;
      });
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    final title = _titleController.text.trim();
    final amount = double.tryParse(_amountController.text.trim()) ?? 0.0;
    final description = _descriptionController.text.trim();

    // Check mandatory reason for "Other"
    if (_selectedCategory.toLowerCase() == 'other' && description.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a description / reason for "Other" expense'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final repo = ref.read(expenseRepositoryProvider);
      final isEdit = widget.expenseToEdit != null;

      if (isEdit) {
        final floors = ref.read(floorsProvider).value ?? [];
        String? floorName = _selectedFloorName;
        if (_selectedFloorId != null && (floorName == null || floorName.isEmpty)) {
          final match = floors.where((f) => f.id == _selectedFloorId);
          floorName = match.isNotEmpty ? match.first.name : null;
        }

        final updated = widget.expenseToEdit!.copyWith(
          title: title,
          category: _selectedCategory,
          amount: amount,
          paymentMethod: _selectedPaymentMethod,
          paymentStatus: _selectedPaymentMethod == PaymentMethod.credit ? 'credit' : 'paid',
          date: _selectedDate,
          description: description.isNotEmpty ? description : null,
          floorId: _selectedFloorId,
          floorName: floorName,
        );
        await repo.updateExpense(updated);
      } else {
        final floors = ref.read(floorsProvider).value ?? [];
        String? floorName = _selectedFloorName;
        if (_selectedFloorId != null && (floorName == null || floorName.isEmpty)) {
          final match = floors.where((f) => f.id == _selectedFloorId);
          floorName = match.isNotEmpty ? match.first.name : null;
        }

        final newExpense = Expense(
          id: '',
          title: title,
          category: _selectedCategory,
          amount: amount,
          paymentMethod: _selectedPaymentMethod,
          paymentStatus: _selectedPaymentMethod == PaymentMethod.credit ? 'credit' : 'paid',
          date: _selectedDate,
          description: description.isNotEmpty ? description : null,
          floorId: _selectedFloorId,
          floorName: floorName,
        );
        await repo.createExpense(newExpense);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit ? 'Expense updated successfully' : 'Expense recorded successfully'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving expense: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEdit = widget.expenseToEdit != null;
    final categories = ref.watch(expenseCategoriesProvider);
    final hasFloors = ref.watch(hasFloorsProvider);
    final floors = ref.watch(floorsProvider).value ?? [];
    final dtFmt = DateFormat('EEE, d MMM yyyy • hh:mm a');

    // Ensure selectedCategory is in categories list
    if (!categories.contains(_selectedCategory) && categories.isNotEmpty) {
      _selectedCategory = categories.first;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Expense' : 'Record Expense'),
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // Title / Purpose
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Expense Title *',
                  hintText: 'e.g. Plumber repair, Cue sticks, Electricity bill',
                  prefixIcon: Icon(Icons.receipt_outlined),
                  border: OutlineInputBorder(),
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter a title or item name';
                  }
                  return null;
                },
              ),
              const Gap(16),

              // Amount
              TextFormField(
                controller: _amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  labelText: 'Amount (₹) *',
                  hintText: '0.00',
                  prefixIcon: Icon(Icons.currency_rupee),
                  border: OutlineInputBorder(),
                ),
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Please enter the expense amount';
                  }
                  final n = double.tryParse(val.trim());
                  if (n == null || n <= 0) {
                    return 'Please enter a valid positive amount';
                  }
                  return null;
                },
              ),
              const Gap(16),

              // Category dropdown + Add Custom button
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: const InputDecoration(
                        labelText: 'Category *',
                        prefixIcon: Icon(Icons.category_outlined),
                        border: OutlineInputBorder(),
                      ),
                      items: categories.map((cat) {
                        return DropdownMenuItem(
                          value: cat,
                          child: Text(cat),
                        );
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) {
                          setState(() => _selectedCategory = val);
                        }
                      },
                    ),
                  ),
                  const Gap(8),
                  IconButton.filledTonal(
                    tooltip: 'Add Custom Category',
                    icon: const Icon(Icons.add),
                    onPressed: _showAddCustomCategoryDialog,
                  ),
                ],
              ),
              if (hasFloors && floors.length > 1) ...[
                const Gap(16),
                DropdownButtonFormField<String?>(
                  initialValue: _selectedFloorId,
                  decoration: const InputDecoration(
                    labelText: 'Floor (Optional)',
                    prefixIcon: Icon(Icons.layers_outlined),
                    border: OutlineInputBorder(),
                    helperText: 'Select a floor or leave as General / All Floors',
                  ),
                  items: [
                    const DropdownMenuItem<String?>(
                      value: null,
                      child: Text('General / All Floors'),
                    ),
                    ...floors.map((f) => DropdownMenuItem<String?>(
                      value: f.id,
                      child: Text(f.name),
                    )),
                  ],
                  onChanged: (val) {
                    setState(() {
                      _selectedFloorId = val;
                      if (val != null) {
                        final match = floors.where((f) => f.id == val);
                        _selectedFloorName = match.isNotEmpty ? match.first.name : null;
                      } else {
                        _selectedFloorName = null;
                      }
                    });
                  },
                ),
              ],
              const Gap(20),

              // Payment Method Selection
              Text(
                'Payment Method *',
                style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Gap(8),
              Row(
                children: [
                  _buildPaymentMethodOption(
                    method: PaymentMethod.cash,
                    label: 'Cash',
                    subtitle: 'From register',
                    icon: Icons.money,
                    color: AppColors.primary,
                  ),
                  const Gap(10),
                  _buildPaymentMethodOption(
                    method: PaymentMethod.upi,
                    label: 'UPI',
                    subtitle: 'Online / Bank',
                    icon: Icons.qr_code_2,
                    color: AppColors.secondary,
                  ),
                  const Gap(10),
                  _buildPaymentMethodOption(
                    method: PaymentMethod.credit,
                    label: 'Credit',
                    subtitle: 'Pay later (vendor)',
                    icon: Icons.credit_card,
                    color: AppColors.warning,
                  ),
                ],
              ),
              const Gap(20),

              // Date & Time Picker Card
              ListTile(
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: BorderSide(color: theme.colorScheme.outlineVariant),
                ),
                leading: const Icon(Icons.calendar_today_outlined),
                title: const Text('Expense Date & Time'),
                subtitle: Text(dtFmt.format(_selectedDate)),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDateTime,
              ),
              const Gap(16),

              // Description / Reason
              TextFormField(
                controller: _descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: _selectedCategory.toLowerCase() == 'other'
                      ? 'Reason / Description * (Required for Other)'
                      : 'Description / Notes (Optional)',
                  hintText: 'Add vendor name, invoice reference, or any additional context',
                  alignLabelWithHint: true,
                  border: const OutlineInputBorder(),
                ),
              ),
              const Gap(32),

              // Save CTA Button
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isSaving ? null : _save,
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: _selectedPaymentMethod == PaymentMethod.credit
                        ? AppColors.warning
                        : AppColors.primary,
                  ),
                  child: _isSaving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          isEdit
                              ? 'Update Expense'
                              : (_selectedPaymentMethod == PaymentMethod.credit
                                  ? 'Record Business Credit Expense'
                                  : 'Save Expense'),
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPaymentMethodOption({
    required PaymentMethod method,
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    final isSelected = _selectedPaymentMethod == method;
    return Expanded(
      child: InkWell(
        onTap: () => setState(() => _selectedPaymentMethod = method),
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.15) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : Theme.of(context).colorScheme.outlineVariant,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Theme.of(context).colorScheme.onSurfaceVariant),
              const Gap(6),
              Text(
                label,
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  color: isSelected ? color : Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const Gap(2),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 10,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
