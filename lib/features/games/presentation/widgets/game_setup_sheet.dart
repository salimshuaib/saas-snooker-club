import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:snooker_club/features/games/domain/config/pricing_config.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';
import 'package:snooker_club/features/credit/presentation/widgets/player_search_field.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:snooker_club/core/widgets/inputs/app_text_field.dart';
import 'package:flutter/services.dart';
import 'package:snooker_club/features/games/utils/game_validation_utils.dart';


extension GameModeExtension on GameMode {
  String get displayName => this == GameMode.team ? 'Team' : 'Solo';
}

class GameSetupSheet extends ConsumerStatefulWidget {
  final TableModel table;
  final String employeeId;

  const GameSetupSheet({
    super.key,
    required this.table,
    required this.employeeId,
  });

  @override
  ConsumerState<GameSetupSheet> createState() => _GameSetupSheetState();
}

class _GameSetupSheetState extends ConsumerState<GameSetupSheet> {
  // Selections
  late TableType _tableType;
  GameType _gameType = GameType.standard;
  int? _targetPoints;
  GameMode _mode = GameMode.team;
  
  // Standard configs
  BillingType _billingType = BillingType.perMinute;

  int _totalFrames = 1;
  
  // Custom Pricing
  bool _isCustomPrice = false;
  int? _controllerCount;
  int? _coinQuantity = 1;
  final TextEditingController _customPriceController = TextEditingController();

  // Players
  final List<PlayerSelection?> _teamASelections = [null];
  final List<PlayerSelection?> _teamBSelections = [null];

  bool _isLoading = false;

  @override
  void dispose() {
    _customPriceController.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _tableType = widget.table.type;
    
    final initialValidGameTypes = GameType.values.where((type) {
      if (_tableType.isOtherGame) return type == GameType.standard;
      if (type == GameType.rummy && _tableType != TableType.snooker) return false;
      return TablePricingConfig.supportedBillingTypes(widget.table, type).isNotEmpty;
    }).toList();
    
    if (initialValidGameTypes.isNotEmpty && !initialValidGameTypes.contains(_gameType)) {
      _gameType = initialValidGameTypes.first;
    }
    
    final validBilling = TablePricingConfig.supportedBillingTypes(widget.table, _gameType);
    _billingType = validBilling.isNotEmpty ? validBilling.first : BillingType.perMinute;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.9,
      ),
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
      ),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Game Form', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                    Text(widget.table.name, style: theme.textTheme.bodyMedium?.copyWith(color: AppColors.primary, fontWeight: FontWeight.w600)),
                  ],
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                )
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Game Type Selection
                if (!_tableType.isOtherGame) ...[
                  Text('Game Type', style: theme.textTheme.labelMedium),
                  const Gap(8),
                  DropdownButtonFormField<GameType>(
                    isExpanded: true,
                    value: _gameType,
                    decoration: InputDecoration(
                      isDense: true,
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    items: GameType.values
                        .where((type) {
                          if (_tableType.isOtherGame) return type == GameType.standard;
                          if (type == GameType.rummy && _tableType != TableType.snooker) {
                            return false;
                          }
                          return TablePricingConfig.supportedBillingTypes(widget.table, type).isNotEmpty;
                        })
                        .map(
                          (type) => DropdownMenuItem(
                            value: type,
                            child: Text(
                              type.displayName,
                              style: const TextStyle(fontWeight: FontWeight.w600),
                            ),
                          ),
                        )
                        .toList(),
                    onChanged: (val) {
                      if (val != null) {
                        setState(() {
                          _gameType = val;
                          final validBillingTypes = TablePricingConfig.supportedBillingTypes(widget.table, _gameType);
                          if (validBillingTypes.isNotEmpty && !validBillingTypes.contains(_billingType)) {
                            _billingType = validBillingTypes.first;
                          }
                          // Reset player counts to minimums
                          if (val != GameType.standard && _teamASelections.length < 2) {
                            _teamASelections.clear();
                            _teamASelections.addAll([null, null]);
                          }
                        });
                      }
                    },
                  ),
                ],
                

                
                const Gap(24),

                // STANDARD CONFIG
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (_gameType == GameType.standard) ...[
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Billing Type', style: theme.textTheme.labelMedium),
                            const Gap(8),
                            DropdownButtonFormField<BillingType>(
                              isExpanded: true,
                              value: _billingType,
                              decoration: InputDecoration(
                                isDense: true,
                                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              ),
                              items: (TablePricingConfig.supportedBillingTypes(widget.table, _gameType).isEmpty
                                        ? [_billingType] // Safe fallback to avoid UI crash
                                        : TablePricingConfig.supportedBillingTypes(widget.table, _gameType))
                                  .map((t) => DropdownMenuItem(
                                value: t,
                                child: Text(t.displayName),
                              )).toList(),
                              onChanged: (v) => setState(() => _billingType = v!),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),

                if (!_tableType.isOtherGame && _gameType == GameType.standard && _billingType == BillingType.perMinute) ...[
                  const Gap(24),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Set Custom Price', style: theme.textTheme.labelMedium),
                      Switch(
                        value: _isCustomPrice,
                        onChanged: (val) {
                          setState(() {
                            _isCustomPrice = val;
                          });
                        },
                      ),
                    ],
                  ),
                  if (_isCustomPrice) ...[
                    const Gap(8),
                    AppTextField(
                      controller: _customPriceController,
                      hint: 'Custom price per minute',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    ),
                  ],
                ],

                if (!_tableType.isOtherGame && _gameType == GameType.standard && _billingType == BillingType.perFrame) ...[
                    const Gap(24),
                    Text('Total Frames', style: theme.textTheme.labelMedium),
                    const Gap(8),
                    AppTextField(
                      hint: 'e.g. 1',
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      onChanged: (val) => _totalFrames = int.tryParse(val) ?? 1,
                    ),
                  ],
                
                const Gap(24),
                // PLAY MODE CONFIG
                Text('Play Mode', style: theme.textTheme.labelMedium),
                const Gap(8),
                Row(
                  children: GameMode.values.map((mode) {
                    final isSelected = _mode == mode;
                    return Expanded(
                      child: InkWell(
                        onTap: () {
                          setState(() {
                            _mode = mode;
                          });
                        },
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 12),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.primary : Colors.transparent,
                            border: Border.all(
                              color: isSelected ? AppColors.primary : theme.colorScheme.outlineVariant,
                            ),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Center(
                            child: Text(
                              mode.displayName,
                              style: TextStyle(
                                color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
                const Gap(24),



                if (_mode == GameMode.solo) ...[
                  _buildTeamSection('Players', _teamASelections, 10, theme),
                ] else ...[
                  _buildTeamSection('Team A', _teamASelections, 5, theme),
                  const Gap(24),
                  _buildTeamSection('Team B', _teamBSelections, 5, theme),
                ],
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _startGame,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 0,
                ),
                child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Text('Start Game', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTeamSection(String title, List<PlayerSelection?> selections, int maxPlayers, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
        const Gap(8),
        ...List.generate(selections.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child:                   PlayerSearchField(
                    hint: 'Select or create player',
                    onSelected: (selection) {
                      setState(() {
                        selections[index] = selection;
                      });
                    },
                  ),
                ),
                if (selections.length > 2)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                    onPressed: () {
                      setState(() {
                        selections.removeAt(index);
                      });
                    },
                  ),
              ],
            ),
          );
        }),
        if (selections.length < maxPlayers)
          TextButton.icon(
            onPressed: () {
              setState(() {
                selections.add(null);
              });
            },
            icon: const Icon(Icons.add),
            label: const Text('Add Player'),
          ),
      ],
    );
  }

  Future<void> _startGame() async {
    // â”€â”€â”€ VALIDATIONS â”€â”€â”€
    
    // 1. Frame validation
    if (!_tableType.isOtherGame && _gameType == GameType.standard && _billingType == BillingType.perFrame) {
      if (_totalFrames <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Frame count must be a valid number greater than 0.')),
        );
        return;
      }
    }

    // 2. Duplicate Players Check
    final duplicateError = GameValidationUtils.validateDuplicatePlayersWithinGame(
      _teamASelections, 
      _mode == GameMode.team ? _teamBSelections : []
    );
    
    if (duplicateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(duplicateError)));
      return;
    }

    // 3. Active Elsewhere Check
    final activeElsewhereError = await GameValidationUtils.checkPlayerActiveElsewhere(
      [..._teamASelections, if (_mode == GameMode.team) ..._teamBSelections], 
      ref, 
      widget.table.id
    );

    if (activeElsewhereError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(activeElsewhereError)));
      return;
    }

    setState(() => _isLoading = true);

    try {
      final teamAPlayers = _teamASelections
          .where((p) => p != null && p.name.trim().isNotEmpty)
          .map((p) => p!)
          .toList();

      final teamBPlayers = _mode == GameMode.team
          ? _teamBSelections
              .where((p) => p != null && p.name.trim().isNotEmpty)
              .map((p) => p!)
              .toList()
          : <PlayerSelection>[];

      final combinedSelections = [...teamAPlayers, ...teamBPlayers];
      
      final actualBillingType = _gameType == GameType.standard ? _billingType : BillingType.perMinute;
      
      if (combinedSelections.isEmpty) {
        if (mounted) {
           ScaffoldMessenger.of(context).showSnackBar(
             const SnackBar(content: Text('At least one player must be selected to start a game.'), backgroundColor: AppColors.error),
           );
           setState(() => _isLoading = false);
        }
        return;
      }

      final allProfiles = ref.read(allCustomersProvider).value ?? [];
      final Map<String, String> resolvedIdentities = {};
      final List<String> finalPlayerIds = [];
      final List<PlayerProfile> newProfilesToCreate = [];

      for (final p in combinedSelections) {
        if (p.id != null) {
          resolvedIdentities[p.name] = p.id!;
          finalPlayerIds.add(p.id!);
        } else {
          final existingMatch = allProfiles.where((e) => e.name.toLowerCase() == p.name.trim().toLowerCase()).firstOrNull;
          if (existingMatch != null) {
            final bool? useExisting = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Duplicate Player Found'),
                content: Text('An existing player named "${existingMatch.name}" was found. Do you want to use the existing player profile or create a separate new one?'),
                actions: [
                  TextButton(
                    onPressed: () => Navigator.pop(ctx, false),
                    child: const Text('Create New Anyway'),
                  ),
                  FilledButton(
                    onPressed: () => Navigator.pop(ctx, true),
                    child: const Text('Use Existing'),
                  ),
                ],
              ),
            );
            
            if (useExisting == null) {
              setState(() => _isLoading = false);
              return;
            }
            
            if (useExisting) {
              resolvedIdentities[p.name] = existingMatch.id;
              finalPlayerIds.add(existingMatch.id);
            } else {
              final newId = FirebaseFirestore.instance.collection('credits').doc().id;
              resolvedIdentities[p.name] = newId;
              finalPlayerIds.add(newId);
              
              newProfilesToCreate.add(PlayerProfile(
                id: newId,
                name: p.name.trim(),
                outstandingAmount: 0.0,
                totalPendingTransactions: 0,
                lastTransactionDate: DateTime.now(),
              ));
            }
          } else {
            final newId = FirebaseFirestore.instance.collection('credits').doc().id;
            resolvedIdentities[p.name] = newId;
            finalPlayerIds.add(newId);
            
            newProfilesToCreate.add(PlayerProfile(
              id: newId,
              name: p.name.trim(),
              outstandingAmount: 0.0,
              totalPendingTransactions: 0,
              lastTransactionDate: DateTime.now(),
            ));
          }
        }
      }

      final teamAIds = teamAPlayers.map((p) => p.name).toList();
      final teamBIds = teamBPlayers.map((p) => p.name).toList();

      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final appSettings = ref.read(appSettingsProvider);
      
      final double? resolvedPrice = (_isCustomPrice && !_tableType.isOtherGame) 
        ? double.tryParse(_customPriceController.text)
        : TablePricingConfig.getPrice(widget.table, _gameType, actualBillingType, appSettings.pricing);
        
      final double? resolvedExtraCharge = TablePricingConfig.getExtraCharge(widget.table, _gameType, actualBillingType, appSettings.pricing);

      final gameSession = GameSession(
        date: dateStr,
        id: FirebaseFirestore.instance.collection('games').doc().id,
        tableId: widget.table.id,
        tableName: widget.table.name,
        tableType: widget.table.type,
        gameType: _gameType,
        mode: _mode,
        startTime: DateTime.now(),
        status: TableStatus.running,
        targetPoints: _targetPoints,
        billingType: actualBillingType,
        matchType: MatchType.friendly,
        totalFrames: (_gameType == GameType.standard && actualBillingType == BillingType.perFrame && !_tableType.isOtherGame) ? _totalFrames : 1,
        framesPlayed: 0,
        teamA: teamAIds,
        teamB: teamBIds,
        playerIds: finalPlayerIds,
        playerIdentities: resolvedIdentities,
        orders: const [],
        pauseTimes: const [],
        resumeTimes: const [],
        customPrice: resolvedPrice,
        customExtraCharge: resolvedExtraCharge,
        coinQuantity: _coinQuantity,
        pricingSnapshot: appSettings.pricing,
        gameSettingsSnapshot: appSettings.game,
      );

      final creditRepo = ref.read(creditRepositoryProvider);
      final gamesRepo = ref.read(gamesRepositoryProvider);

      if (mounted) {
        Navigator.pop(context);
      }

      // Defer state-modifying writes to avoid Riverpod TickerMode exceptions during pop animation
      Future.delayed(const Duration(milliseconds: 400), () async {
        try {
          for (final profile in newProfilesToCreate) {
            await creditRepo.savePlayerProfile(profile);
          }
          await gamesRepo.startGame(gameSession);
        } catch (e) {
          debugPrint('Failed to start game in background: $e');
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting game: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
