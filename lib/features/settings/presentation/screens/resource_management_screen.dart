import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/widgets/modals/app_modal.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/floors/providers/floor_providers.dart';
import 'package:snooker_club/features/floors/presentation/widgets/floor_selector_sheet.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:snooker_club/features/settings/domain/models/settings_models.dart';

class ResourceManagementScreen extends ConsumerStatefulWidget {
  const ResourceManagementScreen({super.key});
  @override
  ConsumerState<ResourceManagementScreen> createState() =>
      _ResourceManagementScreenState();
}

class _ResourceManagementScreenState
    extends ConsumerState<ResourceManagementScreen> {
  void _showResourceSheet(String? defaultFloorId, [TableModel? table]) {
    AppModal.showBottomSheet(
      context: context,
      isScrollControlled: true,
      maxWidth: 600,
      builder: (context) => _ResourceSheet(
        tableToEdit: table,
        defaultFloorId: defaultFloorId,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tables = ref.watch(floorFilteredTablesProvider);
    final selectedFloor = ref.watch(selectedFloorProvider);
    final isFloorsEnabled = ref.watch(hasFloorsProvider);
    final floors = ref.watch(floorsProvider).value ?? [];
    final hasMultipleFloors = isFloorsEnabled && floors.length > 1;
    final theme = Theme.of(context);

    String headerTitle = 'Manage Games & Tables';
    if (hasMultipleFloors && selectedFloor != null) {
      headerTitle = '${selectedFloor.name} Tables';
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(headerTitle),
        actions: [
          if (hasMultipleFloors)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: GestureDetector(
                onTap: () {
                  AppModal.showBottomSheet(
                    context: context,
                    builder: (_) => const FloorSelectorSheet(),
                  );
                },
                child: Row(
                  children: [
                    Text(
                      selectedFloor?.name ?? 'All Floors',
                      style: TextStyle(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.arrow_drop_down),
                  ],
                ),
              ),
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showResourceSheet(selectedFloor?.id),
        icon: const Icon(Icons.add),
        label: const Text('Add Game'),
      ),
      body: Builder(
        builder: (context) {
          if (tables.isEmpty) {
            return const Center(child: Text('No resources found.'));
          }
          final grouped = <TableType, List<TableModel>>{};
          for (final t in tables) {
            grouped.putIfAbsent(t.type, () => []).add(t);
          }
          final sortedKeys = grouped.keys.toList()
            ..sort((a, b) => a.index.compareTo(b.index));

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: ListView(
                padding: const EdgeInsets.all(16).copyWith(bottom: 100),
                children: [
                  for (int i = 0; i < sortedKeys.length; i++) ...[
                    Padding(
                      padding: EdgeInsets.only(
                        left: 4,
                        bottom: 12,
                        top: i > 0 ? 24 : 0,
                      ),
                      child: Text(
                        sortedKeys[i] == TableType.other
                            ? 'Other Games'
                            : sortedKeys[i].displayName,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: theme.colorScheme.primary,
                        ),
                      ),
                    ),
                    ...grouped[sortedKeys[i]]!.map(
                      (table) => Card(
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor:
                                theme.colorScheme.primary.withValues(alpha: 0.12),
                            child: Icon(
                              table.type.icon,
                              color: theme.colorScheme.primary,
                              size: 20,
                            ),
                          ),
                          title: Text(
                            table.name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text(
                            table.customGameName?.isNotEmpty == true
                                ? '${table.type.displayName} • ${table.customGameName}'
                                : table.type.displayName,
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              IconButton(
                                icon:
                                    const Icon(Icons.edit, color: Colors.blue),
                                onPressed: () =>
                                    _showResourceSheet(selectedFloor?.id, table),
                              ),
                              IconButton(
                                icon:
                                    const Icon(Icons.delete, color: Colors.red),
                                onPressed: () async {
                                  final confirm = await showDialog<bool>(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Delete Resource'),
                                      content: Text(
                                        'Are you sure you want to delete ${table.name}?',
                                      ),
                                      actions: [
                                        TextButton(
                                          onPressed: () =>
                                              Navigator.pop(context, false),
                                          child: const Text('Cancel'),
                                        ),
                                        FilledButton(
                                          style: FilledButton.styleFrom(
                                            backgroundColor: Colors.red,
                                          ),
                                          onPressed: () =>
                                              Navigator.pop(context, true),
                                          child: const Text('Delete'),
                                        ),
                                      ],
                                    ),
                                  );
                                  if (confirm == true && context.mounted) {
                                    await ref
                                        .read(gamesRepositoryProvider)
                                        .deleteTable(table.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _ResourceSheet extends ConsumerStatefulWidget {
  final TableModel? tableToEdit;
  final String? defaultFloorId;
  const _ResourceSheet({this.tableToEdit, this.defaultFloorId});

  @override
  ConsumerState<_ResourceSheet> createState() => _ResourceSheetState();
}

class _ResourceSheetState extends ConsumerState<_ResourceSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _gameNameController;
  late TextEditingController _oneHourPriceController;
  late TextEditingController _halfHourPriceController;
  late TextEditingController _perMinutePriceController;
  late TextEditingController _overtimePriceController;
  late TextEditingController _perFramePriceController;
  late TextEditingController _perCoinPriceController;
  late TextEditingController _extraOneHourController;
  late TextEditingController _extraHalfHourController;
  late TextEditingController _minimumBillController;

  late TableType _type;
  String? _selectedFloorId;
  bool _oneHourEnabled = true;
  bool _halfHourEnabled = true;
  bool _perMinuteEnabled = true;
  bool _overtimeEnabled = true;
  bool _perFrameEnabled = true;
  bool _perCoinEnabled = true;
  bool _isMinimumBillEnabled = false;
  bool _allowCustomPrice = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final edit = widget.tableToEdit;
    _nameController = TextEditingController(text: edit?.name ?? '');
    _gameNameController =
        TextEditingController(text: edit?.customGameName ?? '');
    _type = edit?.type ?? TableType.snooker;
    _selectedFloorId = edit?.floorId ?? widget.defaultFloorId;
    _allowCustomPrice = edit?.allowCustomPrice ?? true;
    _isMinimumBillEnabled = edit?.isMinimumBillEnabled ?? false;

    // Pricing rates
    final fallback = ref.read(appSettingsProvider).pricing;
    final existingOptions = edit?.billingOptions;

    _oneHourEnabled = existingOptions?['oneHour']?.enabled ?? true;
    _halfHourEnabled = existingOptions?['halfHour']?.enabled ?? true;
    _perMinuteEnabled = existingOptions?['perMinute']?.enabled ?? true;
    _overtimeEnabled = existingOptions?['overtime']?.enabled ?? true;
    _perFrameEnabled = existingOptions?['perFrame']?.enabled ?? true;
    _perCoinEnabled = existingOptions?['perCoin']?.enabled ?? true;

    final oneHourPrice = existingOptions?['oneHour']?.price ??
        _getDefaultOneHourPrice(fallback, _type);
    final halfHourPrice = existingOptions?['halfHour']?.price ??
        _getDefaultHalfHourPrice(fallback, _type);
    final perMinutePrice = existingOptions?['perMinute']?.price ??
        _getDefaultPerMinutePrice(fallback, _type);
    final overtimePrice = existingOptions?['overtime']?.price ??
        existingOptions?['perMinute']?.price ??
        _getDefaultPerMinutePrice(fallback, _type);
    final perFramePrice = existingOptions?['perFrame']?.price ??
        (_type == TableType.indianPool
            ? fallback.indianPoolPerFrame
            : fallback.americanPoolPerFrame);
    final perCoinPrice =
        existingOptions?['perCoin']?.price ?? fallback.arcadeCoinPrice;

    final extraOneHour = existingOptions?['oneHour']?.extraCharge ??
        fallback.extraControllerFeeOneHour;
    final extraHalfHour = existingOptions?['halfHour']?.extraCharge ??
        fallback.extraControllerFeeHalfHour;

    final minBill = (edit?.minimumBillAmount ?? 0.0) > 0
        ? edit!.minimumBillAmount
        : 50.0;

    _oneHourPriceController =
        TextEditingController(text: oneHourPrice.toStringAsFixed(0));
    _halfHourPriceController =
        TextEditingController(text: halfHourPrice.toStringAsFixed(0));
    _perMinutePriceController =
        TextEditingController(text: perMinutePrice.toStringAsFixed(2));
    _overtimePriceController =
        TextEditingController(text: overtimePrice.toStringAsFixed(2));
    _perFramePriceController =
        TextEditingController(text: perFramePrice.toStringAsFixed(0));
    _perCoinPriceController =
        TextEditingController(text: perCoinPrice.toStringAsFixed(0));
    _extraOneHourController =
        TextEditingController(text: extraOneHour.toStringAsFixed(0));
    _extraHalfHourController =
        TextEditingController(text: extraHalfHour.toStringAsFixed(0));
    _minimumBillController =
        TextEditingController(text: minBill.toStringAsFixed(0));
  }

  double _getDefaultOneHourPrice(PricingSettings fallback, TableType type) {
    switch (type) {
      case TableType.snooker: return fallback.snookerOneHour;
      case TableType.indianPool: return fallback.indianPoolOneHour;
      case TableType.americanPool: return fallback.americanPoolOneHour;
      case TableType.ps5: return fallback.ps5OneHour;
      case TableType.ps4: return fallback.ps4OneHour;
      case TableType.pc: return fallback.pcOneHour;
      case TableType.carrom: return fallback.carromOneHour;
      case TableType.foosball: return fallback.foosballOneHour;
      case TableType.chess: return fallback.chessOneHour;
      case TableType.tableTennis: return fallback.chessOneHour;
      case TableType.steeringWheel: return fallback.chessOneHour;
      case TableType.simulator: return fallback.simulatorOneHour;
      case TableType.iceHockey: return fallback.iceHockeyOneHour;
      case TableType.other: return fallback.otherOneHour;
      case TableType.arcade: return 0.0;
    }
  }

  double _getDefaultHalfHourPrice(PricingSettings fallback, TableType type) {
    switch (type) {
      case TableType.snooker: return fallback.snookerHalfHour;
      case TableType.indianPool: return fallback.indianPoolHalfHour;
      case TableType.americanPool: return fallback.americanPoolHalfHour;
      case TableType.ps5: return fallback.ps5HalfHour;
      case TableType.ps4: return fallback.ps4HalfHour;
      case TableType.pc: return fallback.pcHalfHour;
      case TableType.carrom: return fallback.carromHalfHour;
      case TableType.foosball: return fallback.foosballHalfHour;
      case TableType.chess: return fallback.chessHalfHour;
      case TableType.tableTennis: return fallback.chessHalfHour;
      case TableType.steeringWheel: return fallback.chessHalfHour;
      case TableType.simulator: return fallback.simulatorHalfHour;
      case TableType.iceHockey: return fallback.iceHockeyHalfHour;
      case TableType.other: return fallback.otherHalfHour;
      case TableType.arcade: return 0.0;
    }
  }

  double _getDefaultPerMinutePrice(PricingSettings fallback, TableType type) {
    switch (type) {
      case TableType.snooker: return fallback.snookerPerMinute;
      case TableType.indianPool: return fallback.indianPoolPerMinute;
      case TableType.americanPool: return fallback.americanPoolPerMinute;
      case TableType.ps5: return fallback.ps5OneHour / 60.0;
      case TableType.ps4: return fallback.ps4OneHour / 60.0;
      case TableType.pc: return fallback.pcOneHour / 60.0;
      case TableType.carrom: return fallback.carromOneHour / 60.0;
      case TableType.foosball: return fallback.foosballOneHour / 60.0;
      case TableType.chess: return fallback.chessOneHour / 60.0;
      case TableType.tableTennis: return fallback.chessOneHour / 60.0;
      case TableType.steeringWheel: return fallback.chessOneHour / 60.0;
      case TableType.simulator: return fallback.simulatorOneHour / 60.0;
      case TableType.iceHockey: return fallback.iceHockeyOneHour / 60.0;
      case TableType.other: return fallback.otherPerMinute;
      case TableType.arcade: return 0.0;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _gameNameController.dispose();
    _oneHourPriceController.dispose();
    _halfHourPriceController.dispose();
    _perMinutePriceController.dispose();
    _overtimePriceController.dispose();
    _perFramePriceController.dispose();
    _perCoinPriceController.dispose();
    _extraOneHourController.dispose();
    _extraHalfHourController.dispose();
    _minimumBillController.dispose();
    super.dispose();
  }

  void _openCategoryPicker() {
    AppModal.showBottomSheet(
      context: context,
      isScrollControlled: true,
      maxWidth: 550,
      builder: (ctx) => _CategoryPickerSheet(
        selectedType: _type,
        onSelected: (newType) {
          setState(() {
            _type = newType;
            if (_type == TableType.other) {
              if (_gameNameController.text.isEmpty &&
                  _nameController.text.isNotEmpty) {
                _gameNameController.text = _nameController.text;
              }
            }
            if (widget.tableToEdit == null) {
              final fallback = ref.read(appSettingsProvider).pricing;
              _oneHourPriceController.text =
                  _getDefaultOneHourPrice(fallback, _type).toStringAsFixed(0);
              _halfHourPriceController.text =
                  _getDefaultHalfHourPrice(fallback, _type).toStringAsFixed(0);
              _perMinutePriceController.text =
                  _getDefaultPerMinutePrice(fallback, _type).toStringAsFixed(2);
              _overtimePriceController.text =
                  _getDefaultPerMinutePrice(fallback, _type).toStringAsFixed(2);
              if (_type == TableType.indianPool) {
                _perFramePriceController.text =
                    fallback.indianPoolPerFrame.toStringAsFixed(0);
              } else if (_type == TableType.americanPool) {
                _perFramePriceController.text =
                    fallback.americanPoolPerFrame.toStringAsFixed(0);
              } else if (_type == TableType.arcade) {
                _perCoinPriceController.text =
                    fallback.arcadeCoinPrice.toStringAsFixed(0);
              }
            }
          });
        },
      ),
    );
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final tableName = _nameController.text.trim();
    if (tableName.isEmpty) return;

    final customGameName =
        _type == TableType.other ? _gameNameController.text.trim() : null;
    if (_type == TableType.other &&
        (customGameName == null || customGameName.isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please enter a game name for this other game.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);
    try {
      final billingOptions = <String, TableBillingOption>{};

      if (_type == TableType.arcade) {
        billingOptions['perCoin'] = TableBillingOption(
          enabled: _perCoinEnabled,
          price: double.tryParse(_perCoinPriceController.text.trim()) ?? 20.0,
        );
      } else {
        if (_type == TableType.indianPool || _type == TableType.americanPool) {
          billingOptions['perFrame'] = TableBillingOption(
            enabled: _perFrameEnabled,
            price: double.tryParse(_perFramePriceController.text.trim()) ?? 50.0,
          );
        }
        billingOptions['oneHour'] = TableBillingOption(
          enabled: _oneHourEnabled,
          price: double.tryParse(_oneHourPriceController.text.trim()) ?? 200.0,
          extraCharge: (_type == TableType.ps5 || _type == TableType.ps4)
              ? double.tryParse(_extraOneHourController.text.trim())
              : null,
        );
        billingOptions['halfHour'] = TableBillingOption(
          enabled: _halfHourEnabled,
          price: double.tryParse(_halfHourPriceController.text.trim()) ?? 100.0,
          extraCharge: (_type == TableType.ps5 || _type == TableType.ps4)
              ? double.tryParse(_extraHalfHourController.text.trim())
              : null,
        );
        billingOptions['perMinute'] = TableBillingOption(
          enabled: _perMinuteEnabled,
          price: double.tryParse(_perMinutePriceController.text.trim()) ?? 3.50,
        );
        billingOptions['overtime'] = TableBillingOption(
          enabled: _overtimeEnabled,
          price: double.tryParse(_overtimePriceController.text.trim()) ??
              double.tryParse(_perMinutePriceController.text.trim()) ??
              3.50,
        );
      }

      final double minBillAmount = _isMinimumBillEnabled
          ? (double.tryParse(_minimumBillController.text.trim()) ?? 0.0)
          : 0.0;

      if (widget.tableToEdit == null) {
        final newTable = TableModel(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          name: tableName,
          type: _type,
          customGameName: customGameName,
          order: DateTime.now().millisecondsSinceEpoch,
          floorId: _selectedFloorId,
          billingOptions: billingOptions,
          allowCustomPrice: _allowCustomPrice,
          isMinimumBillEnabled: _isMinimumBillEnabled,
          minimumBillAmount: minBillAmount,
        );
        await ref.read(gamesRepositoryProvider).addTable(newTable);
      } else {
        final updatedTable = widget.tableToEdit!.copyWith(
          name: tableName,
          type: _type,
          customGameName: customGameName,
          floorId: _selectedFloorId,
          billingOptions: billingOptions,
          allowCustomPrice: _allowCustomPrice,
          isMinimumBillEnabled: _isMinimumBillEnabled,
          minimumBillAmount: minBillAmount,
        );
        await ref.read(gamesRepositoryProvider).updateTable(updatedTable);
      }
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              widget.tableToEdit == null
                  ? 'Game added successfully'
                  : 'Game updated successfully',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final floors = ref.watch(floorsProvider).value ?? [];

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.tableToEdit == null ? 'Add Game / Table' : 'Edit Game / Table',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      widget.tableToEdit == null
                          ? 'Configure table details, category, and pricing'
                          : 'Update settings and pricing rates',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Form content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category Selector Tile
                    Text(
                      'Game Category',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(8),
                    InkWell(
                      onTap: _openCategoryPicker,
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.4),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: theme.colorScheme.outlineVariant
                                .withValues(alpha: 0.6),
                          ),
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(
                                _type.icon,
                                color: theme.colorScheme.primary,
                                size: 24,
                              ),
                            ),
                            const Gap(14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Text(
                                        _type.displayName,
                                        style: theme.textTheme.titleMedium
                                            ?.copyWith(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (_type == TableType.other) ...[
                                        const Gap(8),
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                            horizontal: 6,
                                            vertical: 2,
                                          ),
                                          decoration: BoxDecoration(
                                            color: Colors.purple
                                                .withValues(alpha: 0.15),
                                            borderRadius:
                                                BorderRadius.circular(6),
                                          ),
                                          child: const Text(
                                            'Custom',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.purpleAccent,
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                  const Gap(2),
                                  Text(
                                    _type == TableType.other
                                        ? 'Custom game with 1h, 30m, custom price & overtime'
                                        : _type.categoryGroup,
                                    style: theme.textTheme.bodySmall?.copyWith(
                                      color:
                                          theme.colorScheme.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 6,
                              ),
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    'Change',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.bold,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(width: 2),
                                  Icon(
                                    Icons.chevron_right,
                                    size: 16,
                                    color: theme.colorScheme.primary,
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const Gap(20),

                    // Custom Game Name field (if TableType.other)
                    if (_type == TableType.other) ...[
                      Text(
                        'Game Name *',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(8),
                      TextFormField(
                        controller: _gameNameController,
                        decoration: InputDecoration(
                          hintText: 'e.g. Air Hockey, PlayStation VR, Darts',
                          prefixIcon: const Icon(Icons.sports),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                        ),
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Please enter a game name';
                          }
                          return null;
                        },
                        onChanged: (val) {
                          if (_nameController.text.isEmpty ||
                              _nameController.text.startsWith(val.substring(0, val.length > 3 ? 3 : val.length))) {
                            _nameController.text = '$val 1';
                          }
                        },
                      ),
                      const Gap(20),
                    ],

                    // Table / Unit Name field
                    Text(
                      _type == TableType.other
                          ? 'Table / Unit Name *'
                          : 'Name (e.g. ${_type.displayName} 1) *',
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(8),
                    TextFormField(
                      controller: _nameController,
                      decoration: InputDecoration(
                        hintText: _type == TableType.other
                            ? 'e.g. Air Hockey 1, VR Set 1'
                            : 'e.g. ${_type.displayName} 1',
                        prefixIcon: const Icon(Icons.tag),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                      ),
                      validator: (v) {
                        if (v == null || v.trim().isEmpty) {
                          return 'Please enter a table / unit name';
                        }
                        return null;
                      },
                    ),
                    const Gap(20),

                    // Floor Selector (if floors exist)
                    if (floors.isNotEmpty) ...[
                      Text(
                        'Floor Assignment',
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(8),
                      DropdownButtonFormField<String?>(
                        initialValue: _selectedFloorId,
                        decoration: InputDecoration(
                          prefixIcon: const Icon(Icons.layers_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          filled: true,
                          fillColor: theme.colorScheme.surfaceContainerHighest
                              .withValues(alpha: 0.3),
                        ),
                        items: [
                          const DropdownMenuItem<String?>(
                            value: null,
                            child: Text('All Floors / Unassigned'),
                          ),
                          ...floors.map(
                            (f) => DropdownMenuItem<String?>(
                              value: f.id,
                              child: Text(f.name),
                            ),
                          ),
                        ],
                        onChanged: (val) =>
                            setState(() => _selectedFloorId = val),
                      ),
                      const Gap(24),
                    ],

                    // Pricing & Billing Options Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.payments_outlined,
                                color: theme.colorScheme.primary,
                                size: 22,
                              ),
                              const Gap(8),
                              Text(
                                'Pricing & Rates',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Gap(4),
                          Text(
                            _type == TableType.arcade
                                ? 'Configure token/coin price and session rules'
                                : 'Configure supported rates (1 hour, half hour, per frame/minute, extra controllers)',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Gap(16),

                          // Arcade Game: Per Coin
                          if (_type == TableType.arcade) ...[
                            Row(
                              children: [
                                Switch(
                                  value: _perCoinEnabled,
                                  onChanged: (v) =>
                                      setState(() => _perCoinEnabled = v),
                                ),
                                const Gap(8),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Price Per Coin / Token',
                                        style: TextStyle(
                                          fontWeight: _perCoinEnabled
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: _perCoinEnabled
                                              ? null
                                              : theme.disabledColor,
                                        ),
                                      ),
                                      Text(
                                        'Amount charged per arcade token',
                                        style:
                                            theme.textTheme.bodySmall?.copyWith(
                                          fontSize: 11,
                                          color:
                                              theme.colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _perCoinPriceController,
                                    enabled: _perCoinEnabled,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      prefixText: '₹ ',
                                      isDense: true,
                                      contentPadding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 10,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ] else ...[
                            // Cue Sports (Indian Pool & American Pool): Per Frame
                            if (_type == TableType.indianPool ||
                                _type == TableType.americanPool) ...[
                              Row(
                                children: [
                                  Switch(
                                    value: _perFrameEnabled,
                                    onChanged: (v) =>
                                        setState(() => _perFrameEnabled = v),
                                  ),
                                  const Gap(8),
                                  Expanded(
                                    flex: 3,
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          'Per Frame',
                                          style: TextStyle(
                                            fontWeight: _perFrameEnabled
                                                ? FontWeight.bold
                                                : FontWeight.normal,
                                            color: _perFrameEnabled
                                                ? null
                                                : theme.disabledColor,
                                          ),
                                        ),
                                        Text(
                                          'Fixed charge per completed frame/rack',
                                          style: theme.textTheme.bodySmall
                                              ?.copyWith(
                                            fontSize: 11,
                                            color: theme
                                                .colorScheme.onSurfaceVariant,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _perFramePriceController,
                                      enabled: _perFrameEnabled,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: InputDecoration(
                                        prefixText: '₹ ',
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 10,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const Gap(12),
                            ],

                            // 1 Hour Rate
                            Row(
                              children: [
                                Switch(
                                  value: _oneHourEnabled,
                                  onChanged: (v) =>
                                      setState(() => _oneHourEnabled = v),
                                ),
                                const Gap(8),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'One Hour (60m)',
                                    style: TextStyle(
                                      fontWeight: _oneHourEnabled
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: _oneHourEnabled
                                          ? null
                                          : theme.disabledColor,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _oneHourPriceController,
                                    enabled: _oneHourEnabled,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      prefixText: '₹ ',
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 10,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_type == TableType.ps5 ||
                                _type == TableType.ps4) ...[
                              const Gap(6),
                              Row(
                                children: [
                                  const Gap(56),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Extra Controller (1h)',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _extraOneHourController,
                                      enabled: _oneHourEnabled,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: InputDecoration(
                                        prefixText: '+ ₹ ',
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const Gap(12),

                            // Half Hour Rate
                            Row(
                              children: [
                                Switch(
                                  value: _halfHourEnabled,
                                  onChanged: (v) =>
                                      setState(() => _halfHourEnabled = v),
                                ),
                                const Gap(8),
                                Expanded(
                                  flex: 3,
                                  child: Text(
                                    'Half Hour (30m)',
                                    style: TextStyle(
                                      fontWeight: _halfHourEnabled
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: _halfHourEnabled
                                          ? null
                                          : theme.disabledColor,
                                    ),
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _halfHourPriceController,
                                    enabled: _halfHourEnabled,
                                    keyboardType: TextInputType.number,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                    ],
                                    decoration: InputDecoration(
                                      prefixText: '₹ ',
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 10,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            if (_type == TableType.ps5 ||
                                _type == TableType.ps4) ...[
                              const Gap(6),
                              Row(
                                children: [
                                  const Gap(56),
                                  Expanded(
                                    flex: 3,
                                    child: Text(
                                      'Extra Controller (30m)',
                                      style:
                                          theme.textTheme.bodySmall?.copyWith(
                                        color:
                                            theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 2,
                                    child: TextFormField(
                                      controller: _extraHalfHourController,
                                      enabled: _halfHourEnabled,
                                      keyboardType: TextInputType.number,
                                      inputFormatters: [
                                        FilteringTextInputFormatter.digitsOnly,
                                      ],
                                      decoration: InputDecoration(
                                        prefixText: '+ ₹ ',
                                        isDense: true,
                                        contentPadding:
                                            const EdgeInsets.symmetric(
                                          horizontal: 10,
                                          vertical: 8,
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius:
                                              BorderRadius.circular(10),
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const Gap(12),

                            // Per Minute Rate
                            Row(
                              children: [
                                Switch(
                                  value: _perMinuteEnabled,
                                  onChanged: (v) =>
                                      setState(() => _perMinuteEnabled = v),
                                ),
                                const Gap(8),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Per Minute',
                                        style: TextStyle(
                                          fontWeight: _perMinuteEnabled
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: _perMinuteEnabled
                                              ? null
                                              : theme.disabledColor,
                                        ),
                                      ),
                                      Text(
                                        'Allow starting games in per-minute mode',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          fontSize: 11,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _perMinutePriceController,
                                    enabled: _perMinuteEnabled,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: InputDecoration(
                                      prefixText: '₹ ',
                                      suffixText: '/m',
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 10,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const Gap(12),

                            // Overtime Rate
                            Row(
                              children: [
                                Switch(
                                  value: _overtimeEnabled,
                                  onChanged: (v) =>
                                      setState(() => _overtimeEnabled = v),
                                ),
                                const Gap(8),
                                Expanded(
                                  flex: 3,
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        'Overtime Rate',
                                        style: TextStyle(
                                          fontWeight: _overtimeEnabled
                                              ? FontWeight.bold
                                              : FontWeight.normal,
                                          color: _overtimeEnabled
                                              ? null
                                              : theme.disabledColor,
                                        ),
                                      ),
                                      Text(
                                        'Charged per minute if session exceeds time limit',
                                        style: theme.textTheme.bodySmall
                                            ?.copyWith(
                                          fontSize: 11,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                Expanded(
                                  flex: 2,
                                  child: TextFormField(
                                    controller: _overtimePriceController,
                                    enabled: _overtimeEnabled,
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    decoration: InputDecoration(
                                      prefixText: '₹ ',
                                      suffixText: '/m',
                                      isDense: true,
                                      contentPadding:
                                          const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 10,
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const Gap(16),
                          const Divider(),
                          const Gap(8),

                          // Allow Custom Price & Minutes
                          SwitchListTile(
                            contentPadding: EdgeInsets.zero,
                            title: const Text(
                              'Allow Custom Price & Minutes',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                            subtitle: Text(
                              'Cashier can set a custom price or duration when starting this game',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            value: _allowCustomPrice,
                            onChanged: (v) =>
                                setState(() => _allowCustomPrice = v),
                          ),
                        ],
                      ),
                    ),
                    const Gap(16),

                    // Minimum Bill Threshold Card
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: theme.colorScheme.outlineVariant
                              .withValues(alpha: 0.5),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(
                                Icons.rule,
                                color: theme.colorScheme.primary,
                                size: 22,
                              ),
                              const Gap(8),
                              Text(
                                'Minimum Bill Policy',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          const Gap(4),
                          Text(
                            'Enforce a minimum checkout charge regardless of time played',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Gap(12),
                          Row(
                            children: [
                              Switch(
                                value: _isMinimumBillEnabled,
                                onChanged: (v) =>
                                    setState(() => _isMinimumBillEnabled = v),
                              ),
                              const Gap(8),
                              Expanded(
                                flex: 3,
                                child: Text(
                                  'Enable Minimum Bill',
                                  style: TextStyle(
                                    fontWeight: _isMinimumBillEnabled
                                        ? FontWeight.bold
                                        : FontWeight.normal,
                                    color: _isMinimumBillEnabled
                                        ? null
                                        : theme.disabledColor,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: _minimumBillController,
                                  enabled: _isMinimumBillEnabled,
                                  keyboardType: TextInputType.number,
                                  inputFormatters: [
                                    FilteringTextInputFormatter.digitsOnly,
                                  ],
                                  decoration: InputDecoration(
                                    prefixText: '₹ ',
                                    isDense: true,
                                    contentPadding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 10,
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const Gap(28),

                    // Actions
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton(
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _isLoading ? null : () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          flex: 2,
                          child: FilledButton(
                            style: FilledButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            onPressed: _isLoading ? null : _save,
                            child: _isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      color: Colors.white,
                                    ),
                                  )
                                : Text(
                                    widget.tableToEdit == null
                                        ? 'Add Game'
                                        : 'Save Changes',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CategoryPickerSheet extends StatefulWidget {
  final TableType selectedType;
  final ValueChanged<TableType> onSelected;

  const _CategoryPickerSheet({
    required this.selectedType,
    required this.onSelected,
  });

  @override
  State<_CategoryPickerSheet> createState() => _CategoryPickerSheetState();
}

class _CategoryPickerSheetState extends State<_CategoryPickerSheet> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedGroup = 'All';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final query = _searchController.text.trim().toLowerCase();

    final groups = [
      'All',
      'Cue Sports',
      'Consoles & PC',
      'Indoor & Tabletop',
      'Custom & Other',
    ];

    final filtered = TableType.values.where((t) {
      if (_selectedGroup != 'All' && t.categoryGroup != _selectedGroup) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchesName = t.displayName.toLowerCase().contains(query);
        final matchesGroup = t.categoryGroup.toLowerCase().contains(query);
        return matchesName || matchesGroup;
      }
      return true;
    }).toList();

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            margin: const EdgeInsets.only(top: 12, bottom: 8),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Title
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Choose Category',
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Select the sport or game type',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          // Search box
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search games, cue sports, consoles...',
                prefixIcon: const Icon(Icons.search, size: 20),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () => setState(() => _searchController.clear()),
                      )
                    : null,
                filled: true,
                fillColor: theme.colorScheme.surfaceContainerHighest
                    .withValues(alpha: 0.5),
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
              ),
              onChanged: (_) => setState(() {}),
            ),
          ),
          // Filter chips
          SizedBox(
            height: 44,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 20),
              itemCount: groups.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, idx) {
                final g = groups[idx];
                final isSelected = _selectedGroup == g;
                return ChoiceChip(
                  label: Text(g),
                  selected: isSelected,
                  onSelected: (selected) {
                    if (selected) setState(() => _selectedGroup = g);
                  },
                );
              },
            ),
          ),
          const SizedBox(height: 12),
          const Divider(height: 1),
          // Categories list
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'No categories match your search',
                        style: TextStyle(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  )
                : ListView.builder(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final item = filtered[index];
                      final isSelected = item == widget.selectedType;
                      return Card(
                        elevation: 0,
                        color: isSelected
                            ? theme.colorScheme.primary.withValues(alpha: 0.12)
                            : theme.colorScheme.surfaceContainerHighest
                                .withValues(alpha: 0.35),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                          side: BorderSide(
                            color: isSelected
                                ? theme.colorScheme.primary
                                : Colors.transparent,
                            width: 1.5,
                          ),
                        ),
                        margin: const EdgeInsets.symmetric(vertical: 4),
                        child: ListTile(
                          onTap: () {
                            widget.onSelected(item);
                            Navigator.pop(context);
                          },
                          leading: Container(
                            width: 42,
                            height: 42,
                            decoration: BoxDecoration(
                              color: isSelected
                                  ? theme.colorScheme.primary
                                  : theme.colorScheme.primary
                                      .withValues(alpha: 0.15),
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              item.icon,
                              color: isSelected
                                  ? theme.colorScheme.onPrimary
                                  : theme.colorScheme.primary,
                              size: 22,
                            ),
                          ),
                          title: Row(
                            children: [
                              Text(
                                item.displayName,
                                style: TextStyle(
                                  fontWeight: isSelected
                                      ? FontWeight.bold
                                      : FontWeight.w600,
                                ),
                              ),
                              if (item == TableType.other) ...[
                                const SizedBox(width: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 6,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.purple.withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Custom Game',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.purpleAccent,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                              ],
                            ],
                          ),
                          subtitle: Text(
                            item == TableType.other
                                ? 'Set any game name, 1h, 30m, custom price & overtime'
                                : item.categoryGroup,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          trailing: isSelected
                              ? Icon(
                                  Icons.check_circle,
                                  color: theme.colorScheme.primary,
                                )
                              : const Icon(Icons.chevron_right, size: 20),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
