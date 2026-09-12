import 'package:flutter/material.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:gap/gap.dart';

import 'package:snooker_club/features/settings/domain/models/settings_models.dart';

import 'package:snooker_club/features/games/domain/models/game_models.dart';

import 'package:snooker_club/features/games/providers/games_providers.dart';



class PricingEditSheet extends ConsumerStatefulWidget {

  final PricingSettings initialSettings;



  const PricingEditSheet({super.key, required this.initialSettings});



  @override

  ConsumerState<PricingEditSheet> createState() => _PricingEditSheetState();

}



class _PricingEditSheetState extends ConsumerState<PricingEditSheet> {

  final _formKey = GlobalKey<FormState>();



  bool _isSaving = false;



  final Map<String, Map<String, TextEditingController>> _controllers = {};

  final Map<String, Map<String, bool>> _toggles = {};
  final Map<String, bool> _minBillToggles = {};
  final Map<String, TextEditingController> _minBillControllers = {};
  final Map<String, bool> _customPriceToggles = {};



  @override

  void dispose() {
    for (final controller in _minBillControllers.values) {
      controller.dispose();
    }

    for (final tableMap in _controllers.values) {

      for (final controller in tableMap.values) {

        controller.dispose();

      }

    }

    super.dispose();

  }



  void _initControllersForTable(TableModel table, PricingSettings fallback) {

    if (_controllers.containsKey(table.id)) return;



    _minBillToggles[table.id] = table.isMinimumBillEnabled;
    _customPriceToggles[table.id] = table.allowCustomPrice;
    _minBillControllers[table.id] = TextEditingController(text: table.minimumBillAmount.toStringAsFixed(table.minimumBillAmount.truncateToDouble() == table.minimumBillAmount ? 0 : 2));
    _controllers[table.id] = {};

    _toggles[table.id] = {};



    final options = _getOptionsForTableType(table.type);

    for (final opt in options) {

      final key = opt['key']!;

      final existingOption = table.billingOptions?[key];

      

      bool isEnabled = existingOption?.enabled ?? false;

      if (table.billingOptions == null) {

        isEnabled = _isDefaultEnabled(table.type, key);

      }

      

      final double price = existingOption?.price ?? _getDefaultPrice(fallback, table.type, key);

      

      _toggles[table.id]![key] = isEnabled;

      _controllers[table.id]![key] = TextEditingController(text: price.toStringAsFixed(2));
      
      if (table.type == TableType.ps5 || table.type == TableType.ps4) {
        final double extraCharge = existingOption?.extraCharge ?? 
          (key == 'halfHour' ? fallback.extraControllerFeeHalfHour : fallback.extraControllerFeeOneHour);
        _controllers[table.id]!['${key}_extra'] = TextEditingController(text: extraCharge.toStringAsFixed(2));
      }

    }

  }



  bool _isDefaultEnabled(TableType type, String key) {

    switch (type) {

      case TableType.snooker:

        return ['perMinute', 'halfHour', 'oneHour'].contains(key);

      case TableType.indianPool:

      case TableType.americanPool:

        return ['perFrame', 'perMinute', 'halfHour', 'oneHour'].contains(key);

      case TableType.ps5:

      case TableType.pc:

      case TableType.carrom:

      case TableType.foosball:

      case TableType.chess:
      case TableType.ps4:
      case TableType.tableTennis:
      case TableType.steeringWheel:
      case TableType.simulator:
      case TableType.iceHockey:

        return ['halfHour', 'oneHour'].contains(key);

      case TableType.arcade:
        return ['perCoin'].contains(key);

    }

  }



  double _getDefaultPrice(PricingSettings p, TableType type, String key) {

    switch (type) {

      case TableType.snooker:

        if (key == 'perMinute') return p.snookerPerMinute;

        if (key == 'halfHour') return p.snookerHalfHour;

        if (key == 'oneHour') return p.snookerOneHour;

        if (key == 'racePerMinute') return p.snookerRacePerMinute;

        if (key == 'rummyPerMinute') return p.snookerRummyPerMinute;

        break;

      case TableType.indianPool:

        if (key == 'perFrame') return p.indianPoolPerFrame;

        if (key == 'perMinute') return p.indianPoolPerMinute;

        if (key == 'halfHour') return p.indianPoolHalfHour;

        if (key == 'oneHour') return p.indianPoolOneHour;

        if (key == 'racePerMinute') return p.indianPoolRacePerMinute;

        break;

      case TableType.americanPool:

        if (key == 'perFrame') return p.americanPoolPerFrame;

        if (key == 'perMinute') return p.americanPoolPerMinute;

        if (key == 'halfHour') return p.americanPoolHalfHour;

        if (key == 'oneHour') return p.americanPoolOneHour;

        if (key == 'racePerMinute') return p.americanPoolRacePerMinute;

        break;

      case TableType.ps5:

        if (key == 'halfHour') return p.ps5HalfHour;

        if (key == 'oneHour') return p.ps5OneHour;

        break;

      case TableType.pc:

        if (key == 'halfHour') return p.pcHalfHour;

        if (key == 'oneHour') return p.pcOneHour;

        break;

      case TableType.carrom:

        if (key == 'halfHour') return p.carromHalfHour;

        if (key == 'oneHour') return p.carromOneHour;

        break;

      case TableType.foosball:

        if (key == 'halfHour') return p.foosballHalfHour;

        if (key == 'oneHour') return p.foosballOneHour;

        break;

      case TableType.chess:

        if (key == 'halfHour') return p.chessHalfHour;

        if (key == 'oneHour') return p.chessOneHour;

        break;

      case TableType.ps4:
        if (key == 'halfHour') return p.ps4HalfHour;
        if (key == 'oneHour') return p.ps4OneHour;
        break;

      case TableType.simulator:
        if (key == 'halfHour') return p.simulatorHalfHour;
        if (key == 'oneHour') return p.simulatorOneHour;
        break;

      case TableType.iceHockey:
        if (key == 'halfHour') return p.iceHockeyHalfHour;
        if (key == 'oneHour') return p.iceHockeyOneHour;
        break;

      case TableType.arcade:
        if (key == 'perCoin') return p.arcadeCoinPrice;
        break;

      case TableType.tableTennis:
      case TableType.steeringWheel:
        if (key == 'halfHour') return p.chessHalfHour;
        if (key == 'oneHour') return p.chessOneHour;
        break;

    }

    return 0.0;

  }



  List<Map<String, String>> _getOptionsForTableType(TableType type) {

    switch (type) {

      case TableType.snooker:

        return [

          {'key': 'perMinute', 'label': 'Per Minute'},

          {'key': 'halfHour', 'label': 'Half Hour (30m)'},

          {'key': 'oneHour', 'label': 'One Hour (1h)'},

          {'key': 'racePerMinute', 'label': 'Race / min'},

          {'key': 'rummyPerMinute', 'label': 'Rummy / min'},

        ];

      case TableType.indianPool:

      case TableType.americanPool:

        return [

          {'key': 'perFrame', 'label': 'Per Frame'},

          {'key': 'perMinute', 'label': 'Per Minute / Overtime'},

          {'key': 'halfHour', 'label': 'Half Hour (30m)'},

          {'key': 'oneHour', 'label': 'One Hour (1h)'},

          {'key': 'racePerMinute', 'label': 'Race / min'},

        ];

      case TableType.arcade:
        return [
          {'key': 'perCoin', 'label': 'Per Coin'},
        ];

      default:

        return [

          {'key': 'halfHour', 'label': 'Half Hour (30m)'},

          {'key': 'oneHour', 'label': 'One Hour (1h)'},

        ];

    }

  }



  IconData _getIconForTableType(TableType type) {

    switch (type) {

      case TableType.snooker: return Icons.circle;

      case TableType.indianPool: return Icons.lens;

      case TableType.americanPool: return Icons.album;

      case TableType.ps5: return Icons.gamepad;

      case TableType.pc: return Icons.computer;

      case TableType.carrom: return Icons.crop_square;

      case TableType.foosball: return Icons.sports_soccer;

      case TableType.chess: return Icons.extension;
      case TableType.ps4: return Icons.gamepad;
      case TableType.tableTennis: return Icons.sports_tennis;
      case TableType.steeringWheel: return Icons.directions_car;
      case TableType.arcade: return Icons.videogame_asset;
      case TableType.simulator: return Icons.drive_eta;
      case TableType.iceHockey: return Icons.ac_unit;

    }

  }



  Color _getColorForTableType(TableType type) {

    switch (type) {

      case TableType.snooker: return Colors.red;

      case TableType.indianPool: return Colors.amber;

      case TableType.americanPool: return Colors.blue;

      case TableType.ps5: return Colors.deepPurple;

      case TableType.pc: return Colors.cyan;

      case TableType.carrom: return Colors.brown;

      case TableType.foosball: return Colors.green;

      case TableType.chess: return Colors.grey;
      case TableType.ps4: return Colors.blueAccent;
      case TableType.tableTennis: return Colors.orange;
      case TableType.steeringWheel: return Colors.indigo;
      case TableType.arcade: return Colors.pink;
      case TableType.simulator: return Colors.teal;
      case TableType.iceHockey: return Colors.lightBlue;

    }

  }



  String? _validatePrice(String? value) {

    if (value == null || value.trim().isEmpty) return 'Required';

    final parsed = double.tryParse(value.trim());

    if (parsed == null || parsed < 0) return 'Invalid amount';

    return null;

  }



  Future<void> _onSave() async {

    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);

    try {

      final tables = ref.read(resolvedTablesProvider);

      final repo = ref.read(gamesRepositoryProvider);



      for (final table in tables) {

        final tableToggles = _toggles[table.id];

        final tableControllers = _controllers[table.id];

        if (tableToggles == null || tableControllers == null) continue;



        Map<String, TableBillingOption> newBillingOptions = {};

        

        for (final key in tableToggles.keys) {

          final isEnabled = tableToggles[key] ?? false;

          final priceStr = tableControllers[key]?.text.trim() ?? '0';

          final price = double.tryParse(priceStr) ?? 0.0;

          

          double? extraCharge;
          if (table.type == TableType.ps5 || table.type == TableType.ps4) {
            final extraStr = tableControllers['${key}_extra']?.text.trim() ?? '0';
            extraCharge = double.tryParse(extraStr) ?? 0.0;
          }
          
          newBillingOptions[key] = TableBillingOption(

            enabled: isEnabled,

            price: price,
            
            extraCharge: extraCharge,

          );

        }

        

        final updatedTable = table.copyWith(
          billingOptions: newBillingOptions,
          isMinimumBillEnabled: _minBillToggles[table.id] ?? false,
          allowCustomPrice: _customPriceToggles[table.id] ?? false,
          minimumBillAmount: double.tryParse(_minBillControllers[table.id]?.text.trim() ?? '0') ?? 0.0,
        );

        await repo.updateTable(updatedTable);

      }

      

      if (mounted) {

        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(

          const SnackBar(content: Text('Table pricing updated successfully.')),

        );

      }

    } catch (e) {

      if (mounted) {

        ScaffoldMessenger.of(context).showSnackBar(

          SnackBar(

            content: Text('Error saving pricing: $e'),

            backgroundColor: Theme.of(context).colorScheme.error,

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



    for (var table in tables) {

      _initControllersForTable(table, widget.initialSettings);

    }



    return DefaultTabController(
      length: 2,
      child: Container(

      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),

      padding: EdgeInsets.only(

        left: 20,

        right: 20,

        top: 20,

        bottom: MediaQuery.of(context).viewInsets.bottom + 20,

      ),

      child: Form(

        key: _formKey,

        child: Column(

          children: [

            Row(

              mainAxisAlignment: MainAxisAlignment.spaceBetween,

              children: [

                Text(

                  'Configure Table Pricing',

                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),

                ),

                IconButton(

                  icon: const Icon(Icons.close),

                  onPressed: () => Navigator.of(context).pop(),

                ),

              ],

            ),

            TabBar(
              labelColor: theme.colorScheme.primary,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              indicatorColor: theme.colorScheme.primary,
              tabs: const [
                Tab(text: 'Table Games'),
                Tab(text: 'Other Games'),
              ],
            ),

            const Gap(12),

            Expanded(
              child: Builder(
                builder: (context) {
                  final tableGames = tables.where((t) => [TableType.snooker, TableType.indianPool, TableType.americanPool].contains(t.type)).toList();
                  final otherGames = tables.where((t) => ![TableType.snooker, TableType.indianPool, TableType.americanPool].contains(t.type)).toList();
                  
                  return TabBarView(
                    children: [
                      ListView.builder(
                        itemCount: tableGames.length,
                        itemBuilder: (context, index) => _buildTablePricingCard(tableGames[index], theme),
                      ),
                      ListView.builder(
                        itemCount: otherGames.length,
                        itemBuilder: (context, index) => _buildTablePricingCard(otherGames[index], theme),
                      ),
                    ],
                  );
                }
              ),
            ),

            const Gap(16),

            SizedBox(

              width: double.infinity,

              child: ElevatedButton(

                style: ElevatedButton.styleFrom(

                  padding: const EdgeInsets.symmetric(vertical: 16),

                  backgroundColor: theme.colorScheme.primary,

                  foregroundColor: theme.colorScheme.onPrimary,

                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

                ),

                onPressed: _isSaving ? null : _onSave,

                child: _isSaving

                    ? const SizedBox(

                        height: 20,

                        width: 20,

                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),

                      )

                    : const Text('Save Pricing Rates', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),

              ),

            ),

          ],

        ),

      ),

    ));

  }



  Widget _buildTablePricingCard(TableModel table, ThemeData theme) {

    final options = _getOptionsForTableType(table.type);

    

    return Card(

      margin: const EdgeInsets.only(bottom: 16),

      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),

      child: Padding(

        padding: const EdgeInsets.all(16),

        child: Column(

          crossAxisAlignment: CrossAxisAlignment.start,

          children: [

            Row(

              children: [

                Icon(_getIconForTableType(table.type), color: _getColorForTableType(table.type), size: 20),

                const Gap(8),

                Text(

                  table.name,

                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),

                ),

                const Spacer(),

                Text(

                  table.type.displayName,

                  style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),

                ),

              ],

            ),

            const Gap(16),
            if (table.type == TableType.snooker || table.type == TableType.indianPool || table.type == TableType.americanPool) ...[
              const Divider(),
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      flex: 3,
                      child: Row(
                        children: [
                          Switch(
                            value: _minBillToggles[table.id] ?? false,
                            onChanged: (val) {
                              setState(() {
                                _minBillToggles[table.id] = val;
                              });
                            },
                          ),
                          const Gap(8),
                          const Expanded(child: Text('Minimum Bill', style: TextStyle(fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ),
                    const Gap(12),
                    if (_minBillToggles[table.id] ?? false)
                      Expanded(
                        flex: 2,
                        child: _buildTextField('Amount', _minBillControllers[table.id]!),
                      )
                    else
                      const Expanded(flex: 2, child: SizedBox()),
                  ],
                ),
              ),
              const Divider(),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Switch(
                            value: _customPriceToggles[table.id] ?? false,
                            onChanged: (val) {
                              setState(() {
                                _customPriceToggles[table.id] = val;
                              });
                            },
                          ),
                          const Gap(8),
                          const Expanded(child: Text('Allow Custom Base Price', style: TextStyle(fontWeight: FontWeight.w500))),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(),
              const Gap(8),
            ],

            ...options.map((opt) {

              final key = opt['key']!;

              final label = opt['label']!;

              final isEnabled = _toggles[table.id]?[key] ?? false;

              final controller = _controllers[table.id]?[key];

              

              return Padding(

                padding: const EdgeInsets.only(bottom: 12),

                child: Row(

                  children: [

                    Expanded(

                      flex: 3,

                      child: Row(

                        children: [

                          Switch(

                            value: isEnabled,

                            onChanged: (val) {

                              setState(() {

                                _toggles[table.id]![key] = val;

                              });

                            },

                          ),

                          const Gap(8),

                          Expanded(child: Text(label, style: const TextStyle(fontWeight: FontWeight.w500))),

                        ],

                      ),

                    ),

                    const Gap(12),

                    if (isEnabled && controller != null && table.type != TableType.ps5 && table.type != TableType.ps4)

                      Expanded(

                        flex: 2,

                        child: _buildTextField('Price', controller),

                      )
                      
                    else if (isEnabled && controller != null && (table.type == TableType.ps5 || table.type == TableType.ps4))
                    
                      Expanded(
                        flex: 2,
                        child: Column(
                          children: [
                            _buildTextField('Base Price', controller),
                            const Gap(8),
                            _buildTextField('Extra / Controller', _controllers[table.id]!['${key}_extra']!),
                          ],
                        )
                      )

                    else

                      const Expanded(flex: 2, child: SizedBox()),

                  ],

                ),

              );

            }),

          ],

        ),

      ),

    );

  }



  Widget _buildTextField(String label, TextEditingController controller) {

    return TextFormField(

      controller: controller,

      keyboardType: const TextInputType.numberWithOptions(decimal: true),

      decoration: InputDecoration(

        labelText: label,

        border: const OutlineInputBorder(),

        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),

      ),

      validator: _validatePrice,

    );

  }

}

