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
  final TableModel? initialTable;

  const ManualGameSetupScreen({
    super.key,
    required this.employeeId,
    required this.isCompletedGame,
    this.initialTable,
  });

  @override
  ConsumerState<ManualGameSetupScreen> createState() =>
      _ManualGameSetupScreenState();
}

class _ManualGameSetupScreenState extends ConsumerState<ManualGameSetupScreen> {
  late bool _isCompletedMode;
  TableModel? _selectedTable;

  // Time State
  bool _useManualDuration = false;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  final TextEditingController _elapsedHoursController = TextEditingController();
  final TextEditingController _elapsedMinsController = TextEditingController();
  final TextEditingController _elapsedSecsController = TextEditingController();

  // Players
  final List<PlayerSelection?> _playerSelections = [PlayerSelection(name: 'Default 1')];
  int _nextDefaultNumber = 2;

  // Billing
  BillingType? _billingType;
  bool _useCustomPrice = false;
  final TextEditingController _customPriceController = TextEditingController();

  // Frame Setup (For Per Frame)
  int _totalFrames = 1;
  int _currentFrame = 1;

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _isCompletedMode = widget.isCompletedGame;
    _selectedTable = widget.initialTable;
    if (_selectedTable != null) {
      _billingType = BillingType.perMinute;
    }
  }

  @override
  void dispose() {
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

  Future<void> _pickTime(bool isStart) async {
    final TimeOfDay? picked = await showTimePicker(
      context: context,
      initialEntryMode: TimePickerEntryMode.input,
      initialTime: isStart
          ? (_startTime ?? TimeOfDay.now())
          : (_endTime ?? TimeOfDay.now()),
    );
    if (picked != null) {
      setState(() {
        if (isStart) {
          _startTime = picked;
        } else {
          _endTime = picked;
        }
      });
    }
  }

  void _addPlayer() {
    setState(() {
      _playerSelections.add(PlayerSelection(name: 'Default $_nextDefaultNumber'));
      _nextDefaultNumber++;
    });
  }

  void _removePlayer(int index) {
    if (_playerSelections.length > 1) {
      setState(() {
        _playerSelections.removeAt(index);
      });
    }
  }

  Future<void> _handleSave() async {
    if (_selectedTable == null) {
      _showError('Please select a table.');
      return;
    }

    // Time Validation
    DateTime now = DateTime.now();
    DateTime? finalStartTime;
    int durationSeconds = 0;

    if (_isCompletedMode) {
      if (_startTime == null || _endTime == null) {
        _showError('Please provide both Start and End Time.');
        return;
      }
      finalStartTime = DateTime(
        now.year,
        now.month,
        now.day,
        _startTime!.hour,
        _startTime!.minute,
      );
      DateTime finalEndTime = DateTime(
        now.year,
        now.month,
        now.day,
        _endTime!.hour,
        _endTime!.minute,
      );
      if (finalEndTime.isBefore(finalStartTime)) {
        // Assume next day
        finalEndTime = finalEndTime.add(const Duration(days: 1));
      }
      durationSeconds = finalEndTime.difference(finalStartTime).inSeconds;
    } else {
      if (_useManualDuration) {
        int h = int.tryParse(_elapsedHoursController.text) ?? 0;
        int m = int.tryParse(_elapsedMinsController.text) ?? 0;
        int s = int.tryParse(_elapsedSecsController.text) ?? 0;
        durationSeconds = (h * 3600) + (m * 60) + s;
        if (durationSeconds <= 0) {
          _showError('Please enter a valid elapsed duration.');
          return;
        }
        finalStartTime = now.subtract(Duration(seconds: durationSeconds));
      } else {
        if (_startTime == null) {
          _showError('Please provide a Start Time.');
          return;
        }
        finalStartTime = DateTime(
          now.year,
          now.month,
          now.day,
          _startTime!.hour,
          _startTime!.minute,
        );
        if (finalStartTime.isAfter(now)) {
          finalStartTime = finalStartTime.subtract(const Duration(days: 1));
        }
        durationSeconds = now.difference(finalStartTime).inSeconds;
        if (durationSeconds <= 0) durationSeconds = 60; // fallback
      }
    }

    if (_billingType == null) {
      _showError('Please select a Billing Type.');
      return;
    }

    final hasValidPlayer = _playerSelections.any(
      (s) => s != null && s.name.trim().isNotEmpty,
    );
    if (!hasValidPlayer) {
      _showError('Please add at least one player.');
      return;
    }

    double? customPrice;
    if (_useCustomPrice) {
      customPrice = double.tryParse(_customPriceController.text);
      if (customPrice == null || customPrice <= 0) {
        _showError('Please enter a valid custom price.');
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);
      final creditRepo = ref.read(creditRepositoryProvider);
      final appSettings = ref.read(appSettingsProvider);

      // Process Players
      final newProfilesToCreate = <PlayerProfile>[];
      final teamANames = <String>[];
      final finalPlayerIds = <String>[];

      for (var s in _playerSelections) {
        if (s == null) continue;
        String name = s.name.trim();
        if (name.isEmpty) continue;
        teamANames.add(name);

        if (s.id != null) {
          finalPlayerIds.add(s.id!);
        } else {
          // New player - don't create profiles for default players
          if (!name.toLowerCase().startsWith('default ')) {
            final newId = FirebaseFirestore.instance
                .collection('credits')
                .doc()
                .id;
            final newProfile = PlayerProfile(
              id: newId,
              name: name,
              lastTransactionDate: now,
            );
            newProfilesToCreate.add(newProfile);
            finalPlayerIds.add(newId);
          }
        }
      }

      int framesPlayed = (_billingType == BillingType.perFrame)
          ? _currentFrame
          : 0;
      List<GameRound> rounds = [];
      if (_billingType == BillingType.perFrame) {
        rounds = List.generate(
          _currentFrame,
          (index) => GameRound(
            roundNumber: index + 1,
            durationSeconds: index == _currentFrame - 1 ? durationSeconds : 0,
            startTime: finalStartTime!,
            endTime: index == _currentFrame - 1 ? (now) : null,
            roundCost: 0.0,
          ),
        );
      }

      final pricingSnapshot = appSettings.pricing;

      double? customExtraCharge = TablePricingConfig.getExtraCharge(
        _selectedTable!,
        GameType.standard,
        _billingType!,
        pricingSnapshot,
      );

      final session = GameSession(
        id: FirebaseFirestore.instance.collection('dummy').doc().id,
        tableId: _selectedTable!.id,
        tableName: _selectedTable!.name,
        tableType: _selectedTable!.type,
        gameType: GameType.standard,
        matchType: MatchType.friendly,
        billingType: _billingType!,
        mode: GameMode.solo,
        teamA: teamANames,
        teamB: [],
        playerIds: finalPlayerIds,
        status: _isCompletedMode ? TableStatus.billing : TableStatus.running,
        startTime: finalStartTime!,
        endTime: _isCompletedMode
            ? finalStartTime.add(Duration(seconds: durationSeconds))
            : null,
        totalFrames: _currentFrame,
        framesPlayed: framesPlayed,
        rounds: rounds,
        employeeId: widget.employeeId,
        date: DateFormat('yyyy-MM-dd').format(finalStartTime),
        isManualEntry: _isCompletedMode,
        recordedTime: now,
        pricingSnapshot: pricingSnapshot,
        gameSettingsSnapshot: appSettings.game,
        customPrice: customPrice,
        customExtraCharge: customExtraCharge,
      );

      if (mounted) {
        if (_isCompletedMode) {
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
          if (!_isCompletedMode) {
            await gamesRepo.startGame(session);
          }
        } catch (e) {
          debugPrint('Failed to process manual game setup in background.');
        }
      });
    } catch (e) {
      if (mounted) {
        _showError('Error: $e');
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tables = ref.watch(resolvedTablesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manual Entry'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Column(
        children: [
          // Segmented Button
          Padding(
            padding: const EdgeInsets.all(20),
            child: SegmentedButton<bool>(
              segments: const [
                ButtonSegment(value: false, label: Text('Ongoing Game')),
                ButtonSegment(value: true, label: Text('Completed Game')),
              ],
              selected: {_isCompletedMode},
              onSelectionChanged: (Set<bool> newSelection) {
                setState(() {
                  _isCompletedMode = newSelection.first;
                });
              },
            ),
          ),

          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // --- TABLE SELECTION ---
                  if (widget.initialTable == null) ...[
                    Text('Table', style: theme.textTheme.labelMedium),
                    const Gap(8),
                    DropdownButtonFormField<TableModel>(
                      value: _selectedTable,
                      hint: const Text('Select a table'),
                      items: tables
                          .map(
                            (t) =>
                                DropdownMenuItem(value: t, child: Text(t.name)),
                          )
                          .toList(),
                      onChanged: (val) {
                        setState(() {
                          _selectedTable = val;
                          _billingType = BillingType
                              .perMinute; // Reset billing when table changes
                        });
                      },
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const Gap(32),
                  ],

                  // --- TIME SELECTION ---
                  Text('Time', style: theme.textTheme.labelMedium),
                  const Gap(8),
                  if (_isCompletedMode) ...[
                    Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(true),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  ),
                                  const Gap(8),
                                  Text(
                                    _startTime?.format(context) ?? 'Start Time',
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: InkWell(
                            onTap: () => _pickTime(false),
                            borderRadius: BorderRadius.circular(12),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 16,
                              ),
                              decoration: BoxDecoration(
                                color:
                                    theme.colorScheme.surfaceContainerHighest,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                children: [
                                  Icon(
                                    Icons.access_time,
                                    color: theme.colorScheme.primary,
                                    size: 20,
                                  ),
                                  const Gap(8),
                                  Text(_endTime?.format(context) ?? 'End Time'),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ] else ...[
                    // Ongoing Mode
                    Row(
                      children: [
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Set Start Time'),
                            selected: !_useManualDuration,
                            onSelected: (val) =>
                                setState(() => _useManualDuration = !val),
                          ),
                        ),
                        const Gap(12),
                        Expanded(
                          child: ChoiceChip(
                            label: const Text('Enter Duration'),
                            selected: _useManualDuration,
                            onSelected: (val) =>
                                setState(() => _useManualDuration = val),
                          ),
                        ),
                      ],
                    ),
                    const Gap(16),
                    if (!_useManualDuration)
                      InkWell(
                        onTap: () => _pickTime(true),
                        borderRadius: BorderRadius.circular(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 16,
                          ),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.surfaceContainerHighest,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.access_time,
                                color: theme.colorScheme.primary,
                                size: 20,
                              ),
                              const Gap(8),
                              Text(
                                _startTime?.format(context) ??
                                    'Tap to select start time',
                              ),
                            ],
                          ),
                        ),
                      )
                    else
                      Row(
                        children: [
                          Expanded(
                            child: AppTextField(
                              controller: _elapsedHoursController,
                              label: 'Hours',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          const Gap(8),
                          Expanded(
                            child: AppTextField(
                              controller: _elapsedMinsController,
                              label: 'Mins',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                          const Gap(8),
                          Expanded(
                            child: AppTextField(
                              controller: _elapsedSecsController,
                              label: 'Secs',
                              keyboardType: TextInputType.number,
                              inputFormatters: [
                                FilteringTextInputFormatter.digitsOnly,
                              ],
                            ),
                          ),
                        ],
                      ),
                  ],
                  const Gap(32),

                  // --- PLAYERS ---
                  Text('Players', style: theme.textTheme.labelMedium),
                  const Gap(8),
                  for (int i = 0; i < _playerSelections.length; i++)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8.0),
                      child: Row(
                        children: [
                          Expanded(
                            child: PlayerSearchField(
                              hint: 'Player ' + (i + 1).toString(),
                              initialSelection: _playerSelections[i],
                              onSelected: (val) {
                                setState(() {
                                  _playerSelections[i] = val;
                                });
                              },
                            ),
                          ),
                          if (_playerSelections.length > 1)
                            IconButton(
                              icon: const Icon(
                                Icons.remove_circle_outline,
                                color: Colors.red,
                              ),
                              onPressed: () => _removePlayer(i),
                            ),
                        ],
                      ),
                    ),
                  TextButton.icon(
                    onPressed: _addPlayer,
                    icon: const Icon(Icons.add),
                    label: const Text('Add Player'),
                  ),
                  const Gap(32),

                  // --- BILLING TYPE ---
                  Text('Billing', style: theme.textTheme.labelMedium),
                  const Gap(8),
                  if (_selectedTable != null) ...[
                    DropdownButtonFormField<BillingType>(
                      value: _billingType,
                      hint: const Text('Select Billing Type'),
                      items: BillingType.values
                          .where((b) {
                            if (b == BillingType.perCoin)
                              return false; // Not for manual entry
                            if (_selectedTable!.billingOptions != null) {
                              return _selectedTable!
                                      .billingOptions![b.name]
                                      ?.enabled ==
                                  true;
                            }
                            if (_selectedTable!.type == TableType.snooker &&
                                b == BillingType.perFrame)
                              return false;
                            return true;
                          })
                          .map((b) {
                            String label = '';
                            switch (b) {
                              case BillingType.perMinute:
                                label = 'Per Minute';
                                break;
                              case BillingType.halfHour:
                                label = 'Half Hour';
                                break;
                              case BillingType.oneHour:
                                label = 'One Hour';
                                break;
                              case BillingType.perFrame:
                                label = 'Per Frame';
                                break;
                              case BillingType.perCoin:
                                label = 'Per Coin';
                                break;
                            }
                            return DropdownMenuItem(
                              value: b,
                              child: Text(label),
                            );
                          })
                          .toList(),
                      onChanged: (val) => setState(() => _billingType = val),
                      decoration: InputDecoration(
                        filled: true,
                        fillColor: theme.colorScheme.surfaceContainerHighest,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const Gap(16),
                    if (_billingType == BillingType.perMinute &&
                        _selectedTable!.allowCustomPrice) ...[
                      SwitchListTile(
                        title: const Text('Custom Base Price'),
                        value: _useCustomPrice,
                        onChanged: (val) {
                          setState(() {
                            _useCustomPrice = val;
                            if (!val) _customPriceController.clear();
                          });
                        },
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (_useCustomPrice)
                        AppTextField(
                          controller: _customPriceController,
                          label: 'Custom Base Price (\$/min)',
                          keyboardType: const TextInputType.numberWithOptions(
                            decimal: true,
                          ),
                        ),
                    ],
                    if (_billingType == BillingType.perFrame) ...[
                      const Gap(16),
                      Text('Frames Played', style: theme.textTheme.titleSmall),
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_circle_outline),
                            onPressed: () {
                              if (_currentFrame > 1)
                                setState(() => _currentFrame--);
                            },
                          ),
                          Text(
                            '$_currentFrame',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_circle_outline),
                            onPressed: () => setState(() => _currentFrame++),
                          ),
                        ],
                      ),
                    ],
                  ] else
                    Text(
                      'Select a table first',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),

                  const Gap(32),

                  // --- ACTION BUTTON ---
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: FilledButton(
                      onPressed: _isLoading ? null : _handleSave,
                      child: _isLoading
                          ? const CircularProgressIndicator(color: Colors.white)
                          : Text(
                              _isCompletedMode ? 'Generate Bill' : 'Start Game',
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                    ),
                  ),
                  const Gap(64),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
