import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/services/table_alarm_service.dart';
import 'package:snooker_club/core/widgets/inputs/app_text_field.dart';
import 'package:snooker_club/features/settings/domain/models/settings_models.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:snooker_club/features/games/domain/config/pricing_config.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/games/utils/game_validation_utils.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';
import 'package:snooker_club/features/credit/presentation/widgets/player_search_field.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';

class GameSetupDialog extends ConsumerStatefulWidget {
  final TableModel table;
  final String employeeId;
  const GameSetupDialog({
    super.key,
    required this.table,
    required this.employeeId,
  });

  @override
  ConsumerState<GameSetupDialog> createState() => _GameSetupDialogState();
}

class _GameSetupDialogState extends ConsumerState<GameSetupDialog> {
  late TableType _tableType;
  BillingType _billingType = BillingType.perMinute;
  bool _isCustomPrice = false;
  int? _coinQuantity = 1;
  final TextEditingController _customPriceController = TextEditingController();
  final TextEditingController _customMinutesController = TextEditingController(text: '15');
  int _customMinutes = 15;
  final List<PlayerSelection?> _playerSelections = [
    PlayerSelection(name: 'Default 1'),
  ];
  int _nextDefaultNumber = 2;
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
    final validBilling = TablePricingConfig.supportedBillingTypes(
      widget.table,
      GameType.standard,
    );
    if (widget.table.type == TableType.snooker &&
        validBilling.contains(BillingType.perMinute)) {
      _billingType = BillingType.perMinute;
    } else {
      _billingType = validBilling.isNotEmpty
          ? validBilling.first
          : BillingType.perMinute;
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      backgroundColor: theme.colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 400,
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 24, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.table.name,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Setup',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),

                  IconButton(
                    icon: Icon(Icons.close, color: theme.colorScheme.onSurface),
                    onPressed: () => Navigator.pop(context),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
            Divider(color: theme.dividerColor.withOpacity(0.1), height: 1),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildBillingTypeSelector(theme),
                    const SizedBox(height: 24),
                    _buildTeamSection('Players', _playerSelections, 10, theme),
                    const SizedBox(height: 24),
                    if (_tableType == TableType.arcade) ...[
                      Text('Coins', style: theme.textTheme.labelMedium),
                      const SizedBox(height: 8),
                      Container(
                        height: 52,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.surfaceBright,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: theme.dividerColor.withOpacity(0.1),
                          ),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Text(
                                'Number of Coins:',
                                style: theme.textTheme.bodyLarge,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(() {
                                if (_coinQuantity! > 1)
                                  _coinQuantity = _coinQuantity! - 1;
                              }),
                              icon: const Icon(Icons.remove_circle_outline),
                              color: theme.colorScheme.primary,
                            ),
                            Text(
                              '$_coinQuantity',
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            IconButton(
                              onPressed: () => setState(
                                () => _coinQuantity = _coinQuantity! + 1,
                              ),
                              icon: const Icon(Icons.add_circle_outline),
                              color: theme.colorScheme.primary,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),
                    ] else if (widget.table.allowCustomPrice)
                      _buildCustomPriceToggle(theme),
                  ],
                ),
              ),
            ),
            Divider(color: theme.dividerColor.withOpacity(0.1), height: 1),
            Padding(
              padding: const EdgeInsets.all(20),
              child: SizedBox(
                width: double.infinity,
                height: 56,
                child: FilledButton(
                  onPressed: _isLoading ? null : _startGame,
                  style: FilledButton.styleFrom(
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 24,
                          width: 24,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : Text(
                          _tableType == TableType.arcade
                              ? 'Purchase Tokens'
                              : 'Start Game',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingTypeSelector(ThemeData theme) {
    final types = TablePricingConfig.supportedBillingTypes(
      widget.table,
      GameType.standard,
    );
    if (types.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Billing Mode', style: theme.textTheme.labelMedium),
        const SizedBox(height: 8),
        DropdownButtonFormField<BillingType>(
          value: _billingType,
          items: types
              .map(
                (t) => DropdownMenuItem(value: t, child: Text(t.displayName)),
              )
              .toList(),
          onChanged: (val) {
            if (val != null) setState(() => _billingType = val);
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.dividerColor.withOpacity(0.1),
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                color: theme.dividerColor.withOpacity(0.1),
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
            filled: true,
            fillColor: theme.colorScheme.surfaceBright,
          ),
        ),
        if (_billingType == BillingType.customMinute) ...[
          const SizedBox(height: 16),
          Text('Custom Minutes', style: theme.textTheme.labelMedium),
          const SizedBox(height: 8),
          TextFormField(
            controller: _customMinutesController,
            keyboardType: TextInputType.number,
            onChanged: (val) {
              setState(() {
                _customMinutes = int.tryParse(val) ?? 15;
              });
            },
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: theme.dividerColor.withOpacity(0.1)),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              filled: true,
              fillColor: theme.colorScheme.surfaceBright,
              suffixText: 'mins',
            ),
          ),
        ],
      ],
    );
  }

  void _addPlayerRow(List<PlayerSelection?> selections, int maxPlayers) {
    if (selections.length < maxPlayers) {
      setState(() {
        selections.add(PlayerSelection(name: 'Default $_nextDefaultNumber'));
        _nextDefaultNumber++;
      });
    }
  }

  Widget _buildTeamSection(
    String title,
    List<PlayerSelection?> selections,
    int maxPlayers,
    ThemeData theme,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(title, style: theme.textTheme.labelMedium),
            if (selections.length < maxPlayers)
              TextButton.icon(
                onPressed: () => _addPlayerRow(selections, maxPlayers),
                icon: const Icon(Icons.add, size: 20),
                label: const Text('Add Player'),
                style: TextButton.styleFrom(
                  padding: EdgeInsets.zero,
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
              ),
          ],
        ),
        const SizedBox(height: 12),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: selections.length,
          separatorBuilder: (_, __) => const SizedBox(height: 12),
          itemBuilder: (context, i) {
            return Row(
              children: [
                Expanded(
                  child: PlayerSearchField(
                    initialSelection: selections[i],
                    onSelected: (sel) {
                      setState(() {
                        selections[i] = sel;
                      });
                    },
                    hint: 'Player Name',
                  ),
                ),
                if (selections.length > 1) ...[
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(
                      Icons.remove_circle_outline,
                      color: theme.colorScheme.error,
                    ),
                    onPressed: () => setState(() => selections.removeAt(i)),
                  ),
                ],
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildCustomPriceToggle(ThemeData theme) {
    if (_tableType.isOtherGame) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.dividerColor.withOpacity(0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Custom Base Price',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Override standard pricing',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                value: _isCustomPrice,
                onChanged: (val) => setState(() => _isCustomPrice = val),
                activeColor: theme.colorScheme.primary,
              ),
            ],
          ),
          if (_isCustomPrice) ...[
            const SizedBox(height: 12),
            AppTextField(
              controller: _customPriceController,
              label: 'Base Price',
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
              ],
              prefixIcon: const Icon(Icons.attach_money, size: 20),
            ),
            const SizedBox(height: 8),
          ],
        ],
      ),
    );
  }

  Future<void> _startGame() async {
    if (_isCustomPrice &&
        !_tableType.isOtherGame &&
        _customPriceController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid custom price')),
      );
      return;
    }

    final duplicateError =
        GameValidationUtils.validateDuplicatePlayersWithinGame(
          _playerSelections,
          [],
        );
    if (duplicateError != null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(duplicateError)));
      return;
    }

    final activeElsewhereError =
        await GameValidationUtils.checkPlayerActiveElsewhere(
          _playerSelections,
          ref,
          widget.table.id,
        );
    if (activeElsewhereError != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(activeElsewhereError)));
      return;
    }

    setState(() => _isLoading = true);

    bool didPop = false;
    try {
      final combinedSelections = _playerSelections
          .where((p) => p != null && p.name.trim().isNotEmpty)
          .map((p) => p!)
          .toList();

      if (combinedSelections.isEmpty) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('At least one player must be selected.'),
              backgroundColor: AppColors.error,
            ),
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
          // If name starts with "default", treat completely uniquely
          if (p.name.trim().toLowerCase().startsWith('default')) {
            final newId = FirebaseFirestore.instance
                .collection('credits')
                .doc()
                .id;
            resolvedIdentities[p.name] = newId;
            finalPlayerIds.add(newId);
            continue; // Do NOT create a PlayerProfile
          }

          final existingMatch = allProfiles
              .where((e) => e.name.toLowerCase() == p.name.trim().toLowerCase())
              .firstOrNull;
          if (existingMatch != null) {
            final bool? useExisting = await showDialog<bool>(
              context: context,
              builder: (ctx) => AlertDialog(
                title: const Text('Duplicate Player Found'),
                content: Text(
                  'An existing player named "" was found. Do you want to use the existing player profile or create a separate new one?',
                ),
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
              final newId = FirebaseFirestore.instance
                  .collection('credits')
                  .doc()
                  .id;
              resolvedIdentities[p.name] = newId;
              finalPlayerIds.add(newId);

              newProfilesToCreate.add(
                PlayerProfile(
                  id: newId,
                  name: p.name.trim(),
                  outstandingAmount: 0.0,
                  totalUnpaidTransactions: 0,
                  lastTransactionDate: DateTime.now(),
                ),
              );
            }
          } else {
            final newId = FirebaseFirestore.instance
                .collection('credits')
                .doc()
                .id;
            resolvedIdentities[p.name] = newId;
            finalPlayerIds.add(newId);

            newProfilesToCreate.add(
              PlayerProfile(
                id: newId,
                name: p.name.trim(),
                outstandingAmount: 0.0,
                totalUnpaidTransactions: 0,
                lastTransactionDate: DateTime.now(),
              ),
            );
          }
        }
      }

      final now = DateTime.now();
      final dateStr = '\-\-';

      final appSettings = ref.read(appSettingsProvider);

      final double? resolvedPrice = (_isCustomPrice && !_tableType.isOtherGame)
          ? double.tryParse(_customPriceController.text)
          : TablePricingConfig.getPrice(
              widget.table,
              GameType.standard,
              _billingType,
              appSettings.pricing,
            );

      final double? resolvedExtraCharge = TablePricingConfig.getExtraCharge(
        widget.table,
        GameType.standard,
        _billingType,
        appSettings.pricing,
      );

      DateTime? initialAlarmTime;
      if (_billingType == BillingType.halfHour) {
        initialAlarmTime = DateTime.now().add(const Duration(minutes: 30));
      } else if (_billingType == BillingType.oneHour) {
        initialAlarmTime = DateTime.now().add(const Duration(minutes: 60));
      } else if (_billingType == BillingType.customMinute && _customMinutes != null) {
        initialAlarmTime = DateTime.now().add(Duration(minutes: _customMinutes!));
      }

      GameSession gameSession = GameSession(
        date: dateStr,
        id: FirebaseFirestore.instance.collection('games').doc().id,
        tableId: widget.table.id,
        tableName: widget.table.name,
        tableType: widget.table.type,
        startTime: DateTime.now(),
        status: TableStatus.running,
        mode: GameMode.solo,
        matchType: MatchType.friendly,
        billingType: _billingType,
        totalFrames: 1,
        framesPlayed: 0,
        customMinutes: _billingType == BillingType.customMinute ? _customMinutes : null,
        teamA: combinedSelections.map((p) => p.name).toList(),
        teamB: const [],
        playerIds: finalPlayerIds,
        playerIdentities: resolvedIdentities,
        orders: const [],
        pauseTimes: const [],
        resumeTimes: const [],
        customPrice: resolvedPrice,
        customExtraCharge: resolvedExtraCharge,
        coinQuantity: _coinQuantity,
        pricingSnapshot: appSettings.pricing,
        isMinimumBillEnabled: widget.table.isMinimumBillEnabled,
        minimumBillAmount: widget.table.minimumBillAmount,
        gameSettingsSnapshot: appSettings.game,
        alarmTime: initialAlarmTime,
      );

      if (_tableType == TableType.arcade) {
        gameSession = gameSession.copyWith(
          status: TableStatus.billing,
          endTime: DateTime.now(),
        );
      }

      final creditRepo = ref.read(creditRepositoryProvider);
      final gamesRepo = ref.read(gamesRepositoryProvider);

      if (mounted) {
        Navigator.pop(context, gameSession);
        didPop = true;
      }

      Future.delayed(const Duration(milliseconds: 400), () async {
        try {
          for (final profile in newProfilesToCreate) {
            await creditRepo.savePlayerProfile(profile);
          }
          if (_tableType != TableType.arcade) {
            await gamesRepo.startGame(gameSession);
          }
        } catch (e) {
          debugPrint('Failed to start game in background: $e');
        }
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error starting game: '),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted && !didPop) setState(() => _isLoading = false);
    }
  }
}
