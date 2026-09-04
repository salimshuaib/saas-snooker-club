import 'dart:async';
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
import 'package:snooker_club/features/games/presentation/screens/billing_screen.dart';
import 'package:snooker_club/features/games/presentation/widgets/orders_sheet.dart';

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

  final List<String> _teamAPlayers = ['Default 1'];
  final List<String> _teamBPlayers = ['Default 2'];
  
  Timer? _timer;
  Duration _elapsed = Duration.zero;

  @override
  void initState() {
    super.initState();
    _billingType = TablePricingConfig.supportedBillingTypes(widget.table.type, _gameType).first;
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
    final appSettings = ref.read(appSettingsProvider);
    final gamesRepo = ref.read(gamesRepositoryProvider);

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
      teamA: _teamAPlayers,
      teamB: _teamBPlayers,
      playerIds: [], // We skip ID resolution for defaults
      playerIdentities: {},
      orders: const [],
      pauseTimes: const [],
      resumeTimes: const [],
      customPrice: (_isCustomPrice && !widget.table.type.isOtherGame) ? double.tryParse(_customPriceController.text) : null,
      pricingSnapshot: appSettings.pricing,
      gameSettingsSnapshot: appSettings.game,
    );

    await gamesRepo.startGame(gameSession);
    if (mounted) setState(() => _isExpanded = false);
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

  void _endGame(BuildContext context) {
    if (widget.activeGame == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillingScreen(session: widget.activeGame!),
      ),
    );
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
      child: Column(
        children: [
          ListTile(
            contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            title: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(widget.table.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18), overflow: TextOverflow.ellipsis),
                ),
                if (isAvailable && (widget.table.type == TableType.indianPool || widget.table.type == TableType.americanPool))
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
                  if (timeText.isNotEmpty) ...[
                    const Gap(6),
                    const Text('•'),
                    const Gap(6),
                    Text(timeText, style: const TextStyle(fontWeight: FontWeight.w700, fontFamily: 'Courier')),
                  ],
                ],
              ),
            ),
            trailing: isAvailable ? IconButton(
              icon: Icon(_isExpanded ? Icons.expand_less : Icons.expand_more),
              onPressed: () => setState(() => _isExpanded = !_isExpanded),
            ) : null,
          ),
          if (isAvailable && !_isExpanded)
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
          if (isRunning || isPaused)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 20),
              child: Column(
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
              ),
            ),
          if (isAvailable && _isExpanded)
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
                    }).map((t) => DropdownMenuItem(value: t, child: Text(t.toString().split('.').last))).toList(),
                    onChanged: (v) {
                      setState(() {
                        _gameType = v!;
                        final validBillingTypes = TablePricingConfig.supportedBillingTypes(widget.table.type, _gameType);
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
                      items: TablePricingConfig.supportedBillingTypes(widget.table.type, _gameType)
                        .map((t) => DropdownMenuItem(value: t, child: Text(t.toString().split('.').last))).toList(),
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
                      items: MatchType.values.map((t) => DropdownMenuItem(value: t, child: Text(t.toString().split('.').last))).toList(),
                      onChanged: (v) => setState(() => _matchType = v!),
                    ),
                  ],
                  
                  const Gap(12),
                  Text('Players', style: theme.textTheme.labelMedium),
                  const Gap(4),
                  // Mockup of player names display to satisfy the prompt's request for 'Default 1', 'Default 2'
                  Wrap(
                    spacing: 8,
                    children: [
                      ..._teamAPlayers.map((p) => Chip(label: Text(p), onDeleted: () {})),
                      ..._teamBPlayers.map((p) => Chip(label: Text(p), onDeleted: () {})),
                    ],
                  ),
                  
                  const Gap(16),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton(
                      onPressed: () => _startGame(ref),
                      child: const Text('Start Game', style: TextStyle(fontSize: 16)),
                    ),
                  ),
                ],
              ),
            )
        ],
      ),
    );
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
