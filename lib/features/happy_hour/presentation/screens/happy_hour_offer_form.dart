import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/happy_hour/domain/models/happy_hour_offer.dart';
import 'package:snooker_club/features/happy_hour/providers/happy_hour_providers.dart';

class HappyHourOfferFormScreen extends ConsumerStatefulWidget {
  final HappyHourOffer? offer;

  const HappyHourOfferFormScreen({super.key, this.offer});

  @override
  ConsumerState<HappyHourOfferFormScreen> createState() =>
      _HappyHourOfferFormScreenState();
}

class _HappyHourOfferFormScreenState
    extends ConsumerState<HappyHourOfferFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _codeController;

  late DateTime _startDate;
  late DateTime _endDate;
  late TimeOfDay _startTime;
  late TimeOfDay _endTime;
  late bool _isActive;

  final Map<String, TextEditingController> _priceControllers = {};
  final Set<String> _selectedTableIds = {};
  bool _isSaving = false;

  bool get isEdit => widget.offer != null;

  @override
  void initState() {
    super.initState();
    final existing = widget.offer;

    _nameController = TextEditingController(text: existing?.name ?? '');
    _codeController = TextEditingController(text: existing?.code ?? '');

    _startDate = existing?.startDate ?? DateTime.now();
    _endDate = existing?.endDate ??
        DateTime.now().add(const Duration(days: 30));

    if (existing != null) {
      final sParts = existing.dailyStartTime.split(':');
      _startTime = TimeOfDay(
        hour: int.tryParse(sParts[0]) ?? 14,
        minute: int.tryParse(sParts.length > 1 ? sParts[1] : '0') ?? 0,
      );
      final eParts = existing.dailyEndTime.split(':');
      _endTime = TimeOfDay(
        hour: int.tryParse(eParts[0]) ?? 18,
        minute: int.tryParse(eParts.length > 1 ? eParts[1] : '0') ?? 0,
      );
      _isActive = existing.isActive;
      _selectedTableIds.addAll(existing.gameOffers.keys);
      for (final entry in existing.gameOffers.entries) {
        _priceControllers[entry.key] = TextEditingController(
          text: entry.value.toStringAsFixed(0),
        );
      }
    } else {
      _startTime = const TimeOfDay(hour: 14, minute: 0);
      _endTime = const TimeOfDay(hour: 18, minute: 0);
      _isActive = true;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    for (final c in _priceControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  bool get _isOvernight {
    final startMin = _startTime.hour * 60 + _startTime.minute;
    final endMin = _endTime.hour * 60 + _endTime.minute;
    return endMin < startMin;
  }

  String _formatTimeOfDay(TimeOfDay tod) {
    final hour = tod.hour.toString().padLeft(2, '0');
    final minute = tod.minute.toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  Future<void> _pickStartDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate,
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() {
        _startDate = picked;
        if (_endDate.isBefore(_startDate)) {
          _endDate = _startDate;
        }
      });
    }
  }

  Future<void> _pickEndDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _endDate.isBefore(_startDate) ? _startDate : _endDate,
      firstDate: _startDate,
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      setState(() => _endDate = picked);
    }
  }

  Future<void> _pickStartTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime,
    );
    if (picked != null) {
      setState(() => _startTime = picked);
    }
  }

  Future<void> _pickEndTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _endTime,
    );
    if (picked != null) {
      setState(() => _endTime = picked);
    }
  }

  TextEditingController _getPriceController(String tableId, double defaultPrice) {
    if (!_priceControllers.containsKey(tableId)) {
      _priceControllers[tableId] = TextEditingController(
        text: defaultPrice > 0 ? defaultPrice.toStringAsFixed(0) : '99',
      );
    }
    return _priceControllers[tableId]!;
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedTableIds.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select at least one game or table for this offer.'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    final Map<String, double> gameOffers = {};
    for (final tableId in _selectedTableIds) {
      final ctrl = _priceControllers[tableId];
      final price = double.tryParse(ctrl?.text.trim() ?? '');
      if (price == null || price <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter a valid promotional price for all selected tables.'),
            backgroundColor: AppColors.error,
          ),
        );
        return;
      }
      gameOffers[tableId] = price;
    }

    setState(() => _isSaving = true);

    try {
      final repo = ref.read(happyHourRepositoryProvider);
      final startTimeStr = _formatTimeOfDay(_startTime);
      final endTimeStr = _formatTimeOfDay(_endTime);

      final offer = HappyHourOffer(
        id: widget.offer?.id ?? '',
        name: _nameController.text.trim(),
        code: _codeController.text.trim().toUpperCase(),
        isActive: _isActive,
        startDate: _startDate,
        endDate: _endDate,
        dailyStartTime: startTimeStr,
        dailyEndTime: endTimeStr,
        isOvernightSchedule: _isOvernight,
        gameOffers: gameOffers,
        createdAt: widget.offer?.createdAt ?? DateTime.now(),
        createdByUserId: widget.offer?.createdByUserId ?? '',
        createdByName: widget.offer?.createdByName ?? '',
      );

      if (isEdit) {
        await repo.updateOffer(offer);
      } else {
        await repo.createOffer(offer);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(isEdit
                ? 'Offer "${offer.name}" updated successfully!'
                : 'Offer "${offer.name}" created successfully!'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context, true);
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
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tables = ref.watch(resolvedTablesProvider);
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: Text(isEdit ? 'Edit Happy Hour Offer' : 'Create Happy Hour Offer'),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            // Basic Details Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Offer Details',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(16),
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Offer Name *',
                        hintText: 'e.g. Afternoon Special, Weekend Rush',
                        prefixIcon: Icon(Icons.label_outline),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter offer name';
                        }
                        return null;
                      },
                    ),
                    const Gap(16),
                    TextFormField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Offer Code *',
                        hintText: 'e.g. WKND50, AFTN99',
                        prefixIcon: Icon(Icons.qr_code),
                      ),
                      validator: (val) {
                        if (val == null || val.trim().isEmpty) {
                          return 'Please enter a unique offer code';
                        }
                        final clean = val.trim();
                        if (!RegExp(r'^[A-Za-z0-9\-_]+$').hasMatch(clean)) {
                          return 'Code must be letters, numbers, or dashes';
                        }
                        return null;
                      },
                    ),
                    const Gap(16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Status: ${_isActive ? "Active" : "Inactive"}',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        Switch(
                          value: _isActive,
                          onChanged: (val) => setState(() => _isActive = val),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const Gap(16),

            // Date & Time Schedule Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Schedule & Timing',
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickStartDate,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Start Date',
                                prefixIcon: Icon(Icons.calendar_today, size: 18),
                              ),
                              child: Text(dateFormat.format(_startDate)),
                            ),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: InkWell(
                            onTap: _pickEndDate,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'End Date',
                                prefixIcon: Icon(Icons.event, size: 18),
                              ),
                              child: Text(dateFormat.format(_endDate)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: _pickStartTime,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Daily Start Time',
                                prefixIcon: Icon(Icons.access_time, size: 18),
                              ),
                              child: Text(_startTime.format(context)),
                            ),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: InkWell(
                            onTap: _pickEndTime,
                            borderRadius: BorderRadius.circular(12),
                            child: InputDecorator(
                              decoration: const InputDecoration(
                                labelText: 'Daily End Time',
                                prefixIcon: Icon(Icons.timer_off_outlined, size: 18),
                              ),
                              child: Text(_endTime.format(context)),
                            ),
                          ),
                        ),
                      ],
                    ),
                    if (_isOvernight) ...[
                      const Gap(12),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                        ),
                        child: Row(
                          children: [
                            const Icon(Icons.nightlight_round, color: Colors.amber, size: 18),
                            const Gap(8),
                            Expanded(
                              child: Text(
                                'Overnight schedule: active from ${_startTime.format(context)} until ${_endTime.format(context)} next morning.',
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: Colors.amber,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const Gap(16),

            // Game / Table Promotional Pricing Card
            Card(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Applicable Games & Tables',
                          style: theme.textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          '${_selectedTableIds.length} of ${tables.length} selected',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ],
                    ),
                    const Gap(8),
                    Text(
                      'Select which tables are included and set their fixed promotional price.',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Divider(height: 24),
                    if (tables.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 16),
                        child: Center(
                          child: Text('No tables found. Please add tables in settings first.'),
                        ),
                      )
                    else
                      ...tables.map((table) {
                        final isSelected = _selectedTableIds.contains(table.id);
                        final defaultPrice = table.billingOptions?['halfHour']?.price ??
                            table.billingOptions?['oneHour']?.price ??
                            100.0;
                        final ctrl = _getPriceController(table.id, defaultPrice);

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: isSelected
                                ? theme.colorScheme.primaryContainer.withValues(alpha: 0.2)
                                : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.outlineVariant,
                            ),
                          ),
                          child: Row(
                            children: [
                              Checkbox(
                                value: isSelected,
                                onChanged: (val) {
                                  setState(() {
                                    if (val == true) {
                                      _selectedTableIds.add(table.id);
                                    } else {
                                      _selectedTableIds.remove(table.id);
                                    }
                                  });
                                },
                              ),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      table.name,
                                      style: theme.textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    Text(
                                      table.type.displayName,
                                      style: theme.textTheme.bodySmall?.copyWith(
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isSelected) ...[
                                const Gap(12),
                                SizedBox(
                                  width: 120,
                                  child: TextFormField(
                                    controller: ctrl,
                                    keyboardType: TextInputType.number,
                                    decoration: const InputDecoration(
                                      prefixText: '₹',
                                      labelText: 'Promo Price',
                                      contentPadding: EdgeInsets.symmetric(
                                        horizontal: 8,
                                        vertical: 8,
                                      ),
                                    ),
                                    validator: (val) {
                                      if (!isSelected) return null;
                                      if (val == null || val.trim().isEmpty) {
                                        return 'Required';
                                      }
                                      final numVal = double.tryParse(val.trim());
                                      if (numVal == null || numVal <= 0) {
                                        return '> 0';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                              ],
                            ],
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            const Gap(24),

            // Submit Button
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _isSaving ? null : _save,
                icon: _isSaving
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.check_circle_outline),
                label: Text(
                  _isSaving
                      ? 'Saving...'
                      : (isEdit ? 'Update Offer' : 'Create Offer'),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const Gap(32),
          ],
        ),
      ),
    );
  }
}
