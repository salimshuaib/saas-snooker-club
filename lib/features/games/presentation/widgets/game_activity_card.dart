import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/config/pricing_config.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:snooker_club/features/games/presentation/widgets/end_frame_sheet.dart';
import 'package:snooker_club/features/games/presentation/screens/billing_screen.dart';
import 'package:snooker_club/features/games/presentation/widgets/orders_sheet.dart';
import 'package:snooker_club/features/credit/presentation/widgets/player_search_field.dart';
import 'package:snooker_club/features/games/utils/game_validation_utils.dart';

class GameActivityCard extends ConsumerStatefulWidget {
  final TableModel table;
  final GameSession? activeGame;

  const GameActivityCard({
    super.key,
    required this.table,
    this.activeGame,
  });

  @override
  ConsumerState<GameActivityCard> createState() => _GameActivityCardState();
}

class _GameActivityCardState extends ConsumerState<GameActivityCard> {
  bool _isExpanded = false;
  
  // Selections
  GameType _gameType = GameType.standard;
  GameMode _mode = GameMode.team;
  BillingType _billingType = BillingType.perMinute;
  MatchType _matchType = MatchType.loserPays;
  
  bool _isCustomPrice = false;
  final TextEditingController _customPriceController = TextEditingController();

  final List<PlayerSelection?> _teamASelections = [const PlayerSelection(name: 'Default 1')];
  final List<PlayerSelection?> _teamBSelections = [const PlayerSelection(name: 'Default 2')];
  
  bool _isLoading = false;
  
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _billingType = TablePricingConfig.supportedBillingTypes(widget.table, _gameType).first;
    _startTimer();
  }
  
  @override
  void didUpdateWidget(GameActivityCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.activeGame?.status != oldWidget.activeGame?.status || 
        widget.activeGame?.startTime != oldWidget.activeGame?.startTime) {
      _startTimer();
    }
  }
  
  void _startTimer() {
    _timer?.cancel();
    if (widget.activeGame != null && widget.activeGame!.status != TableStatus.available) {
      _updateElapsed();
      if (widget.activeGame!.status == TableStatus.running) {
        _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
          if (mounted) _updateElapsed();
        });
      }
    }
  }
  
  void _updateElapsed() {
    if (widget.activeGame == null) return;
    
    // Quick approximation of elapsed time
    Duration total = DateTime.now().difference(widget.activeGame!.startTime);
    for (int i = 0; i < widget.activeGame!.pauseTimes.length; i++) {
      final pTime = widget.activeGame!.pauseTimes[i];
      final rTime = widget.activeGame!.resumeTimes.length > i 
          ? widget.activeGame!.resumeTimes[i] 
          : DateTime.now();
      total -= rTime.difference(pTime);
    }
    setState(() {
      _elapsed = total;
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _customPriceController.dispose();
    super.dispose();
  }

  void _startGame(WidgetRef ref) async {
    // 1. Duplicate Players Check
    final duplicateError = GameValidationUtils.validateDuplicatePlayersWithinGame(
      _teamASelections, 
      _mode == GameMode.team ? _teamBSelections : []
    );
    
    if (duplicateError != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(duplicateError)));
      return;
    }

    // 2. Active Elsewhere Check
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
          // Skip profile creation for placeholder 'Default' players
          if (p.name.trim().toLowerCase().startsWith('default')) {
            continue;
          }

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

      final appSettings = ref.read(appSettingsProvider);
      final gamesRepo = ref.read(gamesRepositoryProvider);
      final creditRepo = ref.read(creditRepositoryProvider);

      // Create new profiles if any
      for (final profile in newProfilesToCreate) {
        await creditRepo.savePlayerProfile(profile);
      }

      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final gameSession = GameSession(
        date: dateStr,
        id: FirebaseFirestore.instance.collection('games').doc().id,
        tableId: widget.table.id,
        tableName: widget.table.name,
        tableType: widget.table.type,
        gameType: _gameType,
        mode: _mode,
        startTime: now,
        status: TableStatus.running,
        billingType: _billingType,
        matchType: widget.table.type.isOtherGame ? MatchType.friendly : _matchType,
        totalFrames: 1,
        framesPlayed: 0,
        teamA: teamAPlayers.map((p) => p.name).toList(),
        teamB: teamBPlayers.map((p) => p.name).toList(),
        playerIds: finalPlayerIds,
        playerIdentities: resolvedIdentities,
        orders: const [],
        pauseTimes: const [],
        resumeTimes: const [],
        customPrice: (_isCustomPrice && !widget.table.type.isOtherGame) ? double.tryParse(_customPriceController.text) : null,
        pricingSnapshot: appSettings.pricing,
        gameSettingsSnapshot: appSettings.game,
      );

      await gamesRepo.startGame(gameSession);
      if (mounted) setState(() {
        _isExpanded = false;
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error starting game: $e')));
        setState(() => _isLoading = false);
      }
    }
  }

  void _pauseGame(WidgetRef ref) async {
    if (widget.activeGame == null) return;
    await ref.read(gamesRepositoryProvider).pauseGame(
      widget.activeGame!.id,
      widget.activeGame!.tableId,
      DateTime.now(),
    );
  }

  void _resumeGame(WidgetRef ref) async {
    if (widget.activeGame == null) return;
    await ref.read(gamesRepositoryProvider).resumeGame(
      widget.activeGame!.id,
      widget.activeGame!.tableId,
      DateTime.now(),
    );
  }
  
  void _cancelGame(WidgetRef ref) async {
    if (widget.activeGame == null) return;
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Cancel Game?'),
        content: const Text('This will delete the current game session.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('No')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), style: FilledButton.styleFrom(backgroundColor: AppColors.error), child: const Text('Yes, Cancel')),
        ],
      ),
    );
    if (confirm == true) {
      await ref.read(gamesRepositoryProvider).cancelGame(
        widget.activeGame!.id,
        widget.activeGame!.tableId,
        widget.activeGame!.orders,
      );
    }
  }

  void _endGame(BuildContext context) async {
    if (widget.activeGame == null) return;
    
    if (widget.activeGame!.billingType == BillingType.perFrame) {
      final shouldEndMatch = await showModalBottomSheet<bool>(
        context: context,
        isScrollControlled: true,
        builder: (_) => EndFrameSheet(session: widget.activeGame!),
      );
      if (shouldEndMatch == true) {
        if (!mounted) return;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => BillingScreen(session: widget.activeGame!),
          ),
        );
      }
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => BillingScreen(session: widget.activeGame!),
        ),
      );
    }
  }

  Future<void> _showOrdersSheet(BuildContext context) async {
    if (widget.activeGame == null) return;
    
    final updated = await showModalBottomSheet<List<GameOrder>>(
      context: context,
      isScrollControlled: true,
      builder: (_) => OrdersSheet(
        players: widget.activeGame!.allPlayers,
        currentOrders: widget.activeGame!.orders,
      ),
    );

    if (updated != null && mounted) {
      await ref.read(gameSessionControllerProvider.notifier).updateOrders(
        widget.activeGame!.id,
        updated,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isAvailable = widget.activeGame == null;
    final isRunning = widget.activeGame?.status == TableStatus.running;
    final isPaused = widget.activeGame?.status == TableStatus.paused;

    String statusText = 'Available';
    Color statusColor = AppColors.available;
    if (isRunning) {
      statusText = 'Running';
      statusColor = AppColors.running;
    }
    if (isPaused) {
      statusText = 'Paused';
      statusColor = AppColors.paused;
    }
    
    String timeText = '';
    if (!isAvailable) {
      timeText = '${_elapsed.inHours.toString().padLeft(2, '0')}:${(_elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
    }

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: statusColor.withOpacity(0.5), width: 1.5),
      ),
      elevation: 2,
      child: isAvailable
        ? Column(
            children: [
              ListTile(
                contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
                title: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(widget.table.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), overflow: TextOverflow.ellipsis),
                    ),
                    if (widget.table.type == TableType.indianPool || widget.table.type == TableType.americanPool)
                      Container(
                        height: 32,
                        margin: const EdgeInsets.only(left: 8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        padding: const EdgeInsets.all(2),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            _BillingToggleBtn(
                              label: 'Per Min',
                              isSelected: _billingType == BillingType.perMinute,
                              onTap: () => setState(() => _billingType = BillingType.perMinute),
                            ),
                            _BillingToggleBtn(
                              label: 'Per Frame',
                              isSelected: _billingType == BillingType.perFrame,
                              onTap: () => setState(() => _billingType = BillingType.perFrame),
                            ),
                          ],
                        ),
                      ),
                  ],
                ),
                subtitle: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Row(
                    children: [
                      Icon(Icons.circle, color: statusColor, size: 10),
                      const Gap(6),
                      Text(statusText, style: TextStyle(color: statusColor, fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
                trailing: IconButton(
                  icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                ),
              ),
              if (!_isExpanded)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
                  child: SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _startGame(ref),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text('Play', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ),
              if (_isExpanded)
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(),
                      const Gap(8),
                      Text('Advanced Options', style: theme.textTheme.titleSmall?.copyWith(color: AppColors.primary)),
                      const Gap(12),
                      
                      // Expandable form content
                      Text('Game Type', style: theme.textTheme.labelMedium),
                      const Gap(4),
                      DropdownButtonFormField<GameType>(
                        isDense: true,
                        value: _gameType,
                        decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                        items: GameType.values.where((t) {
                          if (widget.table.type.isOtherGame) return t == GameType.standard;
                          if (t == GameType.rummy && widget.table.type != TableType.snooker) return false;
                          return true;
                        }).map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
                        selectedItemBuilder: (context) => GameType.values.where((t) {
                          if (widget.table.type.isOtherGame) return t == GameType.standard;
                          if (t == GameType.rummy && widget.table.type != TableType.snooker) return false;
                          return true;
                        }).map((t) => Text(t.displayName)).toList(),
                        onChanged: (v) {
                          setState(() {
                            _gameType = v!;
                            final validBillingTypes = TablePricingConfig.supportedBillingTypes(widget.table, _gameType);
                            if (!validBillingTypes.contains(_billingType)) {
                              _billingType = validBillingTypes.first;
                            }
                          });
                        },
                      ),
                      
                      if (_gameType == GameType.standard) ...[
                        const Gap(12),
                        Text('Billing Type', style: theme.textTheme.labelMedium),
                        const Gap(4),
                        DropdownButtonFormField<BillingType>(
                          isDense: true,
                          value: _billingType,
                          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          items: TablePricingConfig.supportedBillingTypes(widget.table, _gameType)
                            .map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
                          selectedItemBuilder: (context) => TablePricingConfig.supportedBillingTypes(widget.table, _gameType)
                            .map((t) => Text(t.displayName)).toList(),
                          onChanged: (v) => setState(() => _billingType = v!),
                        ),
                      ],

                      if (!widget.table.type.isOtherGame) ...[
                        const Gap(12),
                        Text('Match Type', style: theme.textTheme.labelMedium),
                        const Gap(4),
                        DropdownButtonFormField<MatchType>(
                          isDense: true,
                          value: _matchType,
                          decoration: InputDecoration(border: OutlineInputBorder(borderRadius: BorderRadius.circular(8))),
                          items: MatchType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
                          selectedItemBuilder: (context) => MatchType.values.map((t) => Text(t.displayName)).toList(),
                          onChanged: (v) => setState(() => _matchType = v!),
                        ),
                      ],
                      
                      const Gap(12),
                      Text('Play Mode', style: theme.textTheme.labelMedium),
                      const Gap(4),
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
                                padding: const EdgeInsets.symmetric(vertical: 8),
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
                      
                      const Gap(12),
                      if (_mode == GameMode.solo) ...[
                        _buildTeamSection('Players', _teamASelections, 10, theme),
                      ] else ...[
                        _buildTeamSection('Team A', _teamASelections, 5, theme),
                        const Gap(16),
                        _buildTeamSection('Team B', _teamBSelections, 5, theme),
                      ],
                      
                      const Gap(16),
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: _isLoading ? null : () => _startGame(ref),
                          child: _isLoading 
                              ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                              : const Text('Start Game', style: TextStyle(fontSize: 16)),
                        ),
                      ),
                    ],
                  ),
                )
            ],
          )
        : _buildActiveState(context, theme, isRunning, isPaused),
    );
  }

  Widget _buildTeamSection(String title, List<PlayerSelection?> selections, int maxPlayers, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: theme.textTheme.labelMedium),
        const Gap(8),
        ...List.generate(selections.length, (index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Row(
              children: [
                Expanded(
                  child: PlayerSearchField(
                    hint: 'Select or create player',
                    initialSelection: selections[index],
                    onSelected: (selection) {
                      setState(() {
                        selections[index] = selection;
                      });
                    },
                  ),
                ),
                if (selections.length > 1)
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

  Widget _buildActiveState(BuildContext context, ThemeData theme, bool isRunning, bool isPaused) {
    final game = widget.activeGame!;
    
    // Header
    final titleRow = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(widget.table.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 20)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: isRunning ? AppColors.running.withValues(alpha: 0.15) : AppColors.paused.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.circle, size: 10, color: isRunning ? AppColors.running : AppColors.paused),
              const Gap(6),
              Text(
                isRunning ? 'RUNNING' : 'PAUSED',
                style: TextStyle(
                  color: isRunning ? AppColors.running : AppColors.paused,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );

    // Subtitle
    final tableTypeStr = game.tableType.displayName;
    final matchTypeStr = game.matchType.displayName;
    final billingTypeStr = game.billingType.displayName;
    
    final appSettings = ref.read(appSettingsProvider);
    final pricingConfig = game.pricingSnapshot ?? appSettings.pricing;
    
    String rateStr = '';
    if (game.billingType == BillingType.perMinute) {
      final rate = game.customPrice ?? TablePricingConfig.getPerMinutePrice(game.tableType, game.gameType, pricingConfig);
      rateStr = ' (₹${rate.toStringAsFixed(2)}/min)';
    } else if (game.billingType == BillingType.perFrame) {
      final rate = game.customPrice ?? TablePricingConfig.getPrice(TableModel(id: '', name: '', type: game.tableType), game.gameType, game.billingType, pricingConfig);
      if (rate != null) rateStr = ' (₹${rate.toStringAsFixed(2)}/frame)';
    }
    
    final subtitleRow = Text(
      '$tableTypeStr • $matchTypeStr • $billingTypeStr$rateStr',
      style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 13),
    );

    // Players badge
    final playersBadge = Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(Icons.people, size: 20, color: theme.colorScheme.primary),
          const Gap(12),
          Expanded(
            child: Text(
              _formatPlayers(game),
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
            ),
          ),
        ],
      ),
    );

    // Timer & Live Bill row
    String timeText = '';
    if (_elapsed.inHours > 0) {
      timeText = '${_elapsed.inHours.toString().padLeft(2, '0')}:${(_elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
    } else {
      timeText = '${(_elapsed.inMinutes % 60).toString().padLeft(2, '0')}:${(_elapsed.inSeconds % 60).toString().padLeft(2, '0')}';
    }
    
    final timerAndBill = Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Row(
          children: [
            Icon(Icons.timer_outlined, color: theme.colorScheme.primary, size: 22),
            const Gap(8),
            Text(
              timeText,
              style: TextStyle(
                color: theme.colorScheme.primary,
                fontWeight: FontWeight.bold,
                fontSize: 20,
                fontFamily: 'Courier',
              ),
            ),
          ],
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              'CURRENT LIVE BILL',
              style: TextStyle(color: theme.colorScheme.onSurfaceVariant, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 0.5),
            ),
            const Gap(2),
            Text(
              '₹${_calculateLiveBill(ref).toStringAsFixed(2)}',
              style: const TextStyle(color: AppColors.success, fontWeight: FontWeight.bold, fontSize: 24),
            ),
          ],
        ),
      ],
    );

    // Action buttons
    final actionButtons = Column(
      children: [
        Row(
          children: [
            if (isRunning)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _pauseGame(ref),
                  icon: const Icon(Icons.pause),
                  label: const Text('Pause'),
                ),
              ),
            if (isPaused)
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () => _resumeGame(ref),
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Resume'),
                ),
              ),
            const Gap(8),
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _showOrdersSheet(context),
                icon: const Icon(Icons.add_shopping_cart),
                label: const Text('Orders'),
              ),
            ),
          ],
        ),
        const Gap(8),
        Row(
          children: [
            Expanded(
              child: OutlinedButton.icon(
                onPressed: () => _cancelGame(ref),
                icon: const Icon(Icons.cancel),
                label: const Text('Cancel'),
                style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
              ),
            ),
            const Gap(8),
            Expanded(
              child: FilledButton.icon(
                onPressed: () => _endGame(context),
                icon: const Icon(Icons.stop),
                label: const Text('End Game', style: TextStyle(fontSize: 16)),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.error,
                  foregroundColor: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ],
    );

    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          titleRow,
          const Gap(4),
          subtitleRow,
          const Gap(16),
          playersBadge,
          const Gap(16),
          Divider(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5), height: 1),
          const Gap(16),
          timerAndBill,
          const Gap(20),
          actionButtons,
        ],
      ),
    );
  }

  String _formatPlayers(GameSession game) {
    if (game.mode == GameMode.solo) {
      return game.teamA.join(' vs ');
    } else {
      final a = game.teamA.isEmpty ? 'Team A' : game.teamA.join(', ');
      final b = game.teamB.isEmpty ? 'Team B' : game.teamB.join(', ');
      return '$a vs $b';
    }
  }

  double _calculateLiveBill(WidgetRef ref) {
    if (widget.activeGame == null) return 0.0;
    
    final appSettings = ref.read(appSettingsProvider);
    
    final breakdown = TablePricingConfig.calculateCharge(
      tableType: widget.activeGame!.tableType,
      gameType: widget.activeGame!.gameType,
      billingType: widget.activeGame!.billingType,
      activeSeconds: _elapsed.inSeconds,
      framesPlayed: math.max(widget.activeGame!.framesPlayed, widget.activeGame!.totalFrames),
      pricingConfig: widget.activeGame!.pricingSnapshot ?? appSettings.pricing,
      gameConfig: widget.activeGame!.gameSettingsSnapshot ?? appSettings.game,
      completedRounds: widget.activeGame!.rounds,
      customPrice: widget.activeGame!.customPrice,
      coinQuantity: widget.activeGame!.coinQuantity,
    );
    return breakdown.totalCharge;
  }
}

class _BillingToggleBtn extends StatelessWidget {
  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  const _BillingToggleBtn({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? theme.colorScheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
            color: isSelected ? theme.colorScheme.onPrimary : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }
}
