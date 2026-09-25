import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/domain/config/pricing_config.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';

class ManualGamesListTab extends ConsumerWidget {
  final void Function(ManualGameCharge charge) onChargeAdded;

  const ManualGamesListTab({super.key, required this.onChargeAdded});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tables = ref.watch(resolvedTablesProvider);

    if (tables.isEmpty) {
      return const Center(child: Text('No tables configured'));
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 8),
      itemCount: tables.length,
      itemBuilder: (context, index) {
        final table = tables[index];
        return ListTile(
          title: Text(table.name),
          subtitle: Text(table.type.displayName),
          trailing: const Icon(Icons.add_circle_outline),
          onTap: () async {
            final charge = await showModalBottomSheet<ManualGameCharge>(
              context: context,
              isScrollControlled: true,
              builder: (_) => ManualGameChargeSetupSheet(table: table),
            );
            if (charge != null) {
              onChargeAdded(charge);
            }
          },
        );
      },
    );
  }
}

class ManualGameChargeSetupSheet extends ConsumerStatefulWidget {
  final TableModel table;

  const ManualGameChargeSetupSheet({super.key, required this.table});

  @override
  ConsumerState<ManualGameChargeSetupSheet> createState() => _ManualGameChargeSetupSheetState();
}

class _ManualGameChargeSetupSheetState extends ConsumerState<ManualGameChargeSetupSheet> {
  late GameType _gameType;
  late BillingType _billingType;
  late List<BillingType> _availableBillingTypes;

  int _durationMinutes = 60;
  int _frames = 1;
  int _coins = 1;
  int _controllers = 2;

  @override
  void initState() {
    super.initState();
    _gameType = GameType.standard;
    _availableBillingTypes = TablePricingConfig.supportedBillingTypes(widget.table, _gameType);
    _billingType = _availableBillingTypes.isNotEmpty ? _availableBillingTypes.first : BillingType.perMinute;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final appSettings = ref.watch(appSettingsProvider);
    final pricingConfig = appSettings.pricing;
    final gameSettings = appSettings.game;

    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Add ', style: theme.textTheme.titleLarge),
            const Gap(16),

            // Game Type
            if (widget.table.type == TableType.ps5 || widget.table.type == TableType.ps4)
              _buildDropdown<GameType>(
                label: 'Game',
                value: _gameType,
                items: GameType.values,
                onChanged: (v) {
                  setState(() {
                    _gameType = v!;
                    _availableBillingTypes = TablePricingConfig.supportedBillingTypes(widget.table, _gameType);
                    if (!_availableBillingTypes.contains(_billingType) && _availableBillingTypes.isNotEmpty) {
                      _billingType = _availableBillingTypes.first;
                    }
                  });
                },
              ),
            
            const Gap(12),
            // Billing Type
            _buildDropdown<BillingType>(
              label: 'Billing Type',
              value: _billingType,
              items: _availableBillingTypes,
              onChanged: (v) => setState(() => _billingType = v!),
            ),

            const Gap(16),

            // Conditional Inputs
            if (_billingType == BillingType.perMinute)
              _buildNumberInput('Duration (Minutes)', _durationMinutes, (v) => setState(() => _durationMinutes = v)),
            if (_billingType == BillingType.perFrame)
              _buildNumberInput('Total Frames', _frames, (v) => setState(() => _frames = v)),
            if (_billingType == BillingType.perCoin)
              _buildNumberInput('Coins', _coins, (v) => setState(() => _coins = v)),
            if (widget.table.type == TableType.ps5 || widget.table.type == TableType.ps4)
              _buildNumberInput('Controllers', _controllers, (v) => setState(() => _controllers = v)),

            const Gap(24),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: FilledButton(
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.success,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: () {
                  // Configurations are non-null
                  
                  int activeSeconds = 0;
                  if (_billingType == BillingType.perMinute) {
                    activeSeconds = _durationMinutes * 60;
                  } else if (_billingType == BillingType.halfHour) {
                    activeSeconds = 30 * 60;
                  } else if (_billingType == BillingType.oneHour) {
                    activeSeconds = 60 * 60;
                  }

                  final breakdown = TablePricingConfig.calculateCharge(
                    table: widget.table,
                    gameType: _gameType,
                    billingType: _billingType,
                    activeSeconds: activeSeconds,
                    framesPlayed: _frames,
                    pricingConfig: pricingConfig,
                    gameConfig: gameSettings,
                    coinQuantity: _coins,
                    playersCount: _controllers,
                  );

                  final charge = ManualGameCharge(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    tableId: widget.table.id,
                    tableName: widget.table.name,
                    tableType: widget.table.type,
                    gameType: _gameType,
                    billingType: _billingType,
                    durationSeconds: activeSeconds,
                    frames: _billingType == BillingType.perFrame ? _frames : null,
                    coins: _billingType == BillingType.perCoin ? _coins : null,
                    playersCount: (widget.table.type == TableType.ps5 || widget.table.type == TableType.ps4) ? _controllers : null,
                    calculatedAmount: breakdown.totalCharge,
                  );
                  Navigator.of(context).pop(charge);
                },
                child: const Text('Add Charge', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDropdown<T>({
    required String label,
    required T value,
    required List<T> items,
    required ValueChanged<T?> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const Gap(4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<T>(
              value: value,
              isExpanded: true,
              items: items.map((e) {
                String label;
                if (e is BillingType) {
                  label = e.displayName;
                } else if (e is GameType) {
                  label = e.displayName;
                } else {
                  label = (e as Enum).name;
                }
                return DropdownMenuItem(
                  value: e,
                  child: Text(label),
                );
              }).toList(),
              onChanged: onChanged,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildNumberInput(String label, int value, ValueChanged<int> onChanged) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: Theme.of(context).textTheme.labelMedium),
        const Gap(4),
        Row(
          children: [
            IconButton(
              onPressed: value > 1 ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline),
            ),
            Expanded(
              child: Text(
                value.toString(),
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            IconButton(
              onPressed: () => onChanged(value + 1),
              icon: const Icon(Icons.add_circle_outline),
            ),
          ],
        ),
      ],
    );
  }
}
