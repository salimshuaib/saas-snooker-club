import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/config/pricing_config.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/core/widgets/inputs/app_text_field.dart';
import 'package:snooker_club/features/games/presentation/screens/billing_screen.dart';
import 'package:snooker_club/features/credit/presentation/widgets/player_search_field.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:flutter/services.dart';
import 'package:snooker_club/features/games/utils/game_validation_utils.dart';

class ManualGameSetupScreen extends ConsumerStatefulWidget {
  final String employeeId;
  final bool isCompletedGame;

  const ManualGameSetupScreen({
    super.key,
    required this.employeeId,
    required this.isCompletedGame,
  });

  @override
  ConsumerState<ManualGameSetupScreen> createState() => _ManualGameSetupScreenState();
}

class _ManualGameSetupScreenState extends ConsumerState<ManualGameSetupScreen> with SingleTickerProviderStateMixin {
  int _step = 0; 
  final int _maxSteps = 5;

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {});
    });
  }

  // Step 0: Table Selection
  TableModel? _selectedTable;

  // Step 1: Start Time
  bool _useActualTime = true; // true = Option A (Time Picker), false = Option B (Elapsed Hours/Mins)
  TimeOfDay? _actualStartTime;
  final TextEditingController _elapsedHoursController = TextEditingController();
  final TextEditingController _elapsedMinsController = TextEditingController();

  // Step 2: Mode & Players
  GameMode _mode = GameMode.solo;
  final List<PlayerSelection?> _teamASelections = [null];
  final List<PlayerSelection?> _teamBSelections = [null];

  // Step 3: Game Type, Billing & Match Type
  GameType _gameType = GameType.standard;
  int? _targetPoints;
  BillingType? _billingType;

  bool _useCustomPrice = false;
  final TextEditingController _customPriceController = TextEditingController();

  // Step 4: Frame Setup
  int _totalFrames = 1;
  int _currentFrame = 1;
  int _elapsedCurrentFrameMins = 0;

  bool _isLoading = false;

  @override
  void dispose() {
    _tabController.dispose();
    _elapsedHoursController.dispose();
    _elapsedMinsController.dispose();
    _elapsedSecsController.dispose();
    _customPriceController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: AppColors.error),
    );
  }

  // ─────────────────────────────────────────────
  // UI Builders
  // ─────────────────────────────────────────────

  Widget _buildStep0TableSelection(ThemeData theme, List<TableModel> tables) {
    final availableTables = tables.where((t) => t.status == TableStatus.available).toList();
    final billiardsTables = availableTables.where((t) => !t.type.isOtherGame).toList();
    final otherGamesTables = availableTables.where((t) => t.type.isOtherGame).toList();

    if (availableTables.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.event_seat, size: 64, color: theme.colorScheme.onSurfaceVariant),
            const Gap(16),
            Text('No Tables Available', style: theme.textTheme.titleLarge),
            const Gap(8),
            Text('All tables are currently occupied.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    final currentList = _tabController.index == 0 ? billiardsTables : otherGamesTables;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.isCompletedGame 
            ? 'Select the table where this completed game took place.' 
            : 'Select an available table to resume a game on.',
          style: theme.textTheme.bodyMedium,
        ),
        const Gap(16),
        TabBar(
          controller: _tabController,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(text: 'Tables'),
            Tab(text: 'Other Games'),
          ],
        ),
        const Gap(16),
        if (currentList.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Center(
              child: Text(
                _tabController.index == 0 ? 'No Billiard Tables Available' : 'No Other Games Available',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
            ),
          )
        else
          ...currentList.map((t) {
            final isSelected = _selectedTable?.id == t.id;
            return GestureDetector(
              onTap: () {
                setState(() {
                  _selectedTable = t;
                  if (t.type == TableType.snooker && _billingType == BillingType.perFrame) {
                    _billingType = null;
                  }
                });
              },
              child: _SelectionTile(
                title: t.name,
                subtitle: t.type.displayName,
                isSelected: isSelected,
              ),
            );
          }),
      ],
    );
  }

  final TextEditingController _elapsedSecsController = TextEditingController();

  Widget _buildStep1TimeSelection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('How long did they play?', style: theme.textTheme.titleMedium),
        const Gap(8),
        Text('Enter the total duration of the completed game.', style: theme.textTheme.bodyMedium),
        const Gap(24),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: _elapsedHoursController,
                label: 'Hours',
                keyboardType: TextInputType.number,
              ),
            ),
            const Gap(12),
            Expanded(
              child: AppTextField(
                controller: _elapsedMinsController,
                label: 'Minutes',
                keyboardType: TextInputType.number,
              ),
            ),
            const Gap(12),
            Expanded(
              child: AppTextField(
                controller: _elapsedSecsController,
                label: 'Seconds',
                keyboardType: TextInputType.number,
              ),
            ),
          ],
        )
      ],
    );
  }

  Widget _buildStep2Players(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: GameMode.values.map((mode) {
            final isSelected = _mode == mode;
            return Expanded(
              child: GestureDetector(
                onTap: () => setState(() => _mode = mode),
                child: Container(
                  margin: EdgeInsets.only(right: mode == GameMode.solo ? 8 : 0),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primary : theme.colorScheme.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    mode == GameMode.solo ? 'Solo' : 'Team',
                    style: TextStyle(
                      color: isSelected ? Colors.white : theme.colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const Gap(20),
        if (_mode == GameMode.solo) ...[
          Text('Player Name', style: theme.textTheme.labelMedium),
          const Gap(8),
          PlayerSearchField(hint: 'Player 1', onSelected: (val) => setState(() => _teamASelections[0] = val)),
        ] else ...[
          _TeamPlayerFields(
            teamLabel: 'Team A',
            selections: _teamASelections,
            onChange: (i, val) => setState(() => _teamASelections[i] = val),
            onAdd: () => setState(() => _teamASelections.add(null)),
            onRemove: (i) => setState(() => _teamASelections.removeAt(i)),
          ),
          const Gap(20),
          _TeamPlayerFields(
            teamLabel: 'Team B',
            selections: _teamBSelections,
            onChange: (i, val) => setState(() => _teamBSelections[i] = val),
            onAdd: () => setState(() => _teamBSelections.add(null)),
            onRemove: (i) => setState(() => _teamBSelections.removeAt(i)),
          ),
        ],
      ],
    );
  }

  Widget _buildStep3Billing(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // GAME TYPE
        Text('Game Type', style: theme.textTheme.titleMedium),
        const Gap(12),
        DropdownButtonFormField<GameType>(
          isExpanded: true,
          value: _gameType,
          decoration: InputDecoration(
            isDense: true,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
          ),
          items: GameType.values
              .where((type) {
                if (type == GameType.rummy && _selectedTable?.type != TableType.snooker) {
                  return false;
                }
                return true;
              })
              .map((type) => DropdownMenuItem(
                value: type,
                child: Text(type.displayName, style: const TextStyle(fontWeight: FontWeight.w600)),
              ))
              .toList(),
          onChanged: (val) {
            if (val != null) {
              setState(() {
                _gameType = val;
                if (val != GameType.standard && _teamASelections.length < 2) {
                  _teamASelections.clear();
                  _teamASelections.addAll([null, null]);
                }
              });
            }
          },
        ),



        const Gap(24),

        if (_gameType == GameType.standard) ...[
          Text('Billing Type', style: theme.textTheme.titleMedium),
          const Gap(12),
          ...BillingType.values
            .where((type) => !(_selectedTable?.type == TableType.snooker && type == BillingType.perFrame))
            .map((type) {
            return GestureDetector(
              onTap: () => setState(() => _billingType = type),
              child: _SelectionTile(
                title: type.displayName,
                isSelected: _billingType == type,
              ),
            );
          }),
          if (_billingType == BillingType.perMinute) ...[
            const Gap(16),
            SwitchListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Custom Per-Minute Price'),
              subtitle: const Text('Override the global rate for this game only'),
              value: _useCustomPrice,
              onChanged: (v) => setState(() => _useCustomPrice = v),
            ),
            if (_useCustomPrice)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: AppTextField(
                  controller: _customPriceController,
                  label: 'Custom Rate (â‚¹/min)',
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
              ),
          ],
        ],

      ],
    );
  }

  Widget _buildStep4Frames(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Frame Setup', style: theme.textTheme.titleMedium),
        const Gap(8),
        Text('Since this is a per-frame game, specify the current frame.', style: theme.textTheme.bodySmall),
        const Gap(24),
        Row(
          children: [
            Expanded(
              child: AppTextField(
                controller: TextEditingController(text: _totalFrames.toString()),
                label: 'Total Frames',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null && n > 0) _totalFrames = n;
                },
              ),
            ),
            const Gap(16),
            Expanded(
              child: AppTextField(
                controller: TextEditingController(text: _currentFrame.toString()),
                label: 'Current Frame #',
                keyboardType: TextInputType.number,
                onChanged: (v) {
                  final n = int.tryParse(v);
                  if (n != null && n > 0) _currentFrame = n;
                },
              ),
            ),
          ],
        ),
        const Gap(16),
        AppTextField(
          controller: TextEditingController(text: _elapsedCurrentFrameMins.toString()),
          label: 'Mins elapsed in Current Frame',
          keyboardType: TextInputType.number,
          onChanged: (v) {
            final n = int.tryParse(v);
            if (n != null && n >= 0) _elapsedCurrentFrameMins = n;
          },
        ),
      ],
    );
  }

  // ─────────────────────────────────────────────
  // Action Handlers
  // ─────────────────────────────────────────────


  void _handleNext() {
    if (_step == 0 && _selectedTable == null) {
      _showError('Please select a table.');
      return;
    }

    if (_step == 1) {
      final h = int.tryParse(_elapsedHoursController.text) ?? 0;
      final m = int.tryParse(_elapsedMinsController.text) ?? 0;
      final s = int.tryParse(_elapsedSecsController.text) ?? 0;
      if (h == 0 && m == 0 && s == 0) {
        _showError('Please enter the elapsed duration.');
        return;
      }
    }

    if (_step == 2) {
      final teamANames = _teamASelections.where((s) => s != null).map((s) => s!.name.trim()).where((n) => n.isNotEmpty).toList();
      if (teamANames.isEmpty) {
        _showError('At least one player name is required.');
        return;
      }
      if (_mode == GameMode.team) {
        final teamBNames = _teamBSelections.where((s) => s != null).map((s) => s!.name.trim()).where((n) => n.isNotEmpty).toList();
        if (teamBNames.isEmpty) {
          _showError('Team B must have at least one player.');
          return;
        }
      }
    }

    if (_step == 3 && _gameType == GameType.standard && _billingType == null) {
      _showError('Please select a billing type.');
      return;
    }



    final isPerFrame = _gameType == GameType.standard && _billingType == BillingType.perFrame;
    if (_step == 3 && !isPerFrame) {
      _startManualGame(); // Skip frame step if not per frame
      return;
    }

    if (_step == 4) {
      if (_currentFrame > _totalFrames) {
        _showError('Current frame cannot exceed total frames.');
        return;
      }
      _startManualGame();
      return;
    }

    setState(() => _step++);
  }

  Future<void> _startManualGame() async {
    FocusScope.of(context).unfocus();
    await Future.delayed(const Duration(milliseconds: 50));
    
    // 1. Frame validation
    if (_gameType == GameType.standard && _billingType == BillingType.perFrame) {
      if (_totalFrames <= 0) {
        _showError('Frame count must be a valid number greater than 0.');
        return;
      }
    }

    // 2. Duplicate Players Check
    final duplicateError = GameValidationUtils.validateDuplicatePlayersWithinGame(
      _teamASelections, 
      _mode == GameMode.team ? _teamBSelections : []
    );
    
    if (duplicateError != null) {
      _showError(duplicateError);
      return;
    }

    setState(() => _isLoading = true);

    // 3. Active Elsewhere Check
    final activeElsewhereError = await GameValidationUtils.checkPlayerActiveElsewhere(
      [..._teamASelections, if (_mode == GameMode.team) ..._teamBSelections], 
      ref, 
      _selectedTable!.id
    );

    if (activeElsewhereError != null) {
      _showError(activeElsewhereError);
      setState(() => _isLoading = false);
      return;
    }

    final actualBillingType = _gameType == GameType.standard ? _billingType! : BillingType.perMinute;
    final actualMatchType = MatchType.friendly;

    final now = DateTime.now();
    final h = int.tryParse(_elapsedHoursController.text) ?? 0;
    final m = int.tryParse(_elapsedMinsController.text) ?? 0;
    final s = int.tryParse(_elapsedSecsController.text) ?? 0;
    final durationSeconds = (h * 3600) + (m * 60) + s;
    final startTime = now.subtract(Duration(seconds: durationSeconds));

    final teamANames = _teamASelections.where((s) => s != null).map((s) => s!.name.trim()).where((n) => n.isNotEmpty).toList();
    final teamBNames = _mode == GameMode.team ? _teamBSelections.where((s) => s != null).map((s) => s!.name.trim()).where((n) => n.isNotEmpty).toList() : <String>[];

    final allSelections = [..._teamASelections, if (_mode == GameMode.team) ..._teamBSelections]
        .where((s) => s != null)
        .map((s) => s!)
        .toList();

    final List<String> finalPlayerIds = [];
    final creditRepo = ref.read(creditRepositoryProvider);
    final gamesRepo = ref.read(gamesRepositoryProvider);
    final List<PlayerProfile> newProfilesToCreate = [];

    for (final sel in allSelections) {
      if (sel.name.trim().isEmpty) continue;
      if (sel.id != null) {
        finalPlayerIds.add(sel.id!);
      } else {
        final newId = FirebaseFirestore.instance.collection('credits').doc().id;
        final newProfile = PlayerProfile(
          id: newId,
          name: sel.name.trim(),
          lastTransactionDate: now,
        );
        newProfilesToCreate.add(newProfile);
        finalPlayerIds.add(newId);
      }
    }

    final docRef = FirebaseFirestore.instance.collection('games').doc();

    List<GameRound> rounds = [];
    int framesPlayed = 0;

    final appSettings = ref.read(appSettingsProvider);
    final pricingSnapshot = appSettings.pricing;
    final double? customPrice = (_useCustomPrice && !_selectedTable!.type.isOtherGame) 
      ? double.tryParse(_customPriceController.text)
      : TablePricingConfig.getPrice(_selectedTable!, _gameType, actualBillingType, pricingSnapshot);

    final double? customExtraCharge = TablePricingConfig.getExtraCharge(_selectedTable!, _gameType, actualBillingType, pricingSnapshot);

    if (actualBillingType == BillingType.perFrame) {
      framesPlayed = _currentFrame;
      final perFrameDuration = durationSeconds ~/ framesPlayed;
      final graceSeconds = appSettings.game.frameGracePeriodMinutes * 60;
      final overtimeEnabled = appSettings.game.enableOvertimeBilling;
      
      final perMinutePrice = TablePricingConfig.getPerMinutePrice(_selectedTable!.type, _gameType, pricingSnapshot);
      final perSecondRate = customPrice != null ? (customPrice / 60.0) : (perMinutePrice / 60.0);

      for (int i = 1; i <= framesPlayed; i++) {
        final roundStart = startTime.add(Duration(seconds: perFrameDuration * (i - 1)));
        final roundEnd = startTime.add(Duration(seconds: perFrameDuration * i));
        
        int? roundOvertimeMinutes;
        double? roundOvertimeCharge;
        
        final overtimeSeconds = perFrameDuration - graceSeconds;
        if (overtimeEnabled && overtimeSeconds > 0) {
          roundOvertimeMinutes = (overtimeSeconds / 60.0).ceil();
          roundOvertimeCharge = overtimeSeconds * perSecondRate;
        }

        rounds.add(GameRound(
          roundNumber: i,
          roundCost: 0,
          startTime: roundStart,
          endTime: roundEnd,
          durationSeconds: perFrameDuration,
          overtimeMinutes: roundOvertimeMinutes,
          overtimeCharge: roundOvertimeCharge,
        ));
      }
    }

    final session = GameSession(
      id: docRef.id,
      tableId: _selectedTable!.id,
      tableName: _selectedTable!.name,
      tableType: _selectedTable!.type,
      gameType: _gameType,
      targetPoints: _targetPoints,
      mode: _mode,
      billingType: actualBillingType,
      matchType: actualMatchType,
      teamA: teamANames,
      teamB: teamBNames,
      playerIds: finalPlayerIds,
      status: widget.isCompletedGame ? TableStatus.billing : TableStatus.running,
      startTime: startTime,
      endTime: widget.isCompletedGame ? now : null,
      totalFrames: _totalFrames,
      framesPlayed: framesPlayed,
      rounds: rounds,
      employeeId: widget.employeeId,
      date: DateFormat('yyyy-MM-dd').format(startTime),
      isManualEntry: widget.isCompletedGame, // True only for completed backdated games
      recordedTime: now,
      pricingSnapshot: pricingSnapshot,
      gameSettingsSnapshot: appSettings.game,
      customPrice: customPrice,
      customExtraCharge: customExtraCharge,
    );

    if (mounted) {
      if (widget.isCompletedGame) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => BillingScreen(session: session),
          ),
        );
      } else {
        Navigator.of(context).pop();
      }
    }

    Future.delayed(const Duration(milliseconds: 400), () async {
      try {
        for (final p in newProfilesToCreate) {
          await creditRepo.savePlayerProfile(p);
        }
        if (!widget.isCompletedGame) {
          await gamesRepo.startGame(session);
        }
      } catch (e) {
        debugPrint('Failed to process manual game setup in background: ');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tables = ref.watch(resolvedTablesProvider);
    final stepTitles = ['Select Table', 'Start Time', 'Players', 'Billing', 'Frame Setup'];
    
    final isPerFrame = _gameType == GameType.standard && _billingType == BillingType.perFrame;
    final totalSteps = isPerFrame ? 5 : 4;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.isCompletedGame ? 'Record Completed Game' : 'Record Ongoing Game'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Step Progress
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: List.generate(totalSteps, (i) {
                return Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < totalSteps - 1 ? 4 : 0),
                    decoration: BoxDecoration(
                      color: i <= _step ? AppColors.primary : theme.colorScheme.outlineVariant,
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                );
              }),
            ),
          ),
          Text(
            'Step ${_step + 1} of ${totalSteps} — ${stepTitles[_step]}',
            style: theme.textTheme.labelMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
          const Gap(16),
          // Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Builder(builder: (context) {
                switch (_step) {
                  case 0: return _buildStep0TableSelection(theme, tables);
                  case 1: return _buildStep1TimeSelection(theme);
                  case 2: return _buildStep2Players(theme);
                  case 3: return _buildStep3Billing(theme);
                  case 4: return _buildStep4Frames(theme);
                  default: return const SizedBox();
                }
              }),
            ),
          ),
          // Actions
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                if (_step > 0)
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => setState(() => _step--),
                      child: const Text('Back'),
                    ),
                  ),
                if (_step > 0) const Gap(12),
                Expanded(
                  flex: 2,
                  child: FilledButton(
                    onPressed: _isLoading ? null : _handleNext,
                    child: _isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2))
                        : Text(_step == totalSteps - 1 ? (widget.isCompletedGame ? 'Generate Bill' : 'Start Game') : 'Next'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SelectionTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool isSelected;

  const _SelectionTile({
    required this.title,
    this.subtitle,
    required this.isSelected,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.primary.withValues(alpha: 0.08) : theme.colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(12),
        border: isSelected ? Border.all(color: AppColors.primary, width: 1.5) : Border.all(color: Colors.transparent),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: theme.textTheme.titleSmall?.copyWith(
                    color: isSelected ? AppColors.primary : theme.colorScheme.onSurface,
                  ),
                ),
                if (subtitle != null) ...[
                  const Gap(2),
                  Text(
                    subtitle!,
                    style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ],
            ),
          ),
          if (isSelected) const Icon(Icons.check_circle, color: AppColors.primary),
        ],
      ),
    );
  }
}

class _TeamPlayerFields extends StatelessWidget {
  final String teamLabel;
  final List<PlayerSelection?> selections;
  final void Function(int, PlayerSelection) onChange;
  final VoidCallback onAdd;
  final void Function(int) onRemove;

  const _TeamPlayerFields({
    required this.teamLabel,
    required this.selections,
    required this.onChange,
    required this.onAdd,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(teamLabel, style: Theme.of(context).textTheme.labelMedium),
        const SizedBox(height: 8),
        for (int i = 0; i < selections.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: PlayerSearchField(
                    hint: 'Player ' + (i + 1).toString(),
                    initialSelection: selections[i],
                    onSelected: (val) => onChange(i, val),
                  ),
                ),
                if (selections.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => onRemove(i),
                  ),
              ],
            ),
          ),
        TextButton.icon(
          onPressed: onAdd,
          icon: const Icon(Icons.add),
          label: const Text('Add Player'),
        ),
      ],
    );
  }
}
