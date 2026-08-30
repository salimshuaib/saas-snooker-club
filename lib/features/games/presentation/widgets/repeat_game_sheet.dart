import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';
import 'package:snooker_club/features/credit/presentation/widgets/player_search_field.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';
import 'package:snooker_club/core/models/audit_log.dart';
import 'package:snooker_club/features/games/utils/game_validation_utils.dart';

class RepeatGameSheet extends ConsumerStatefulWidget {
  final GameSession originalSession;

  const RepeatGameSheet({
    super.key,
    required this.originalSession,
  });

  @override
  ConsumerState<RepeatGameSheet> createState() => _RepeatGameSheetState();
}

class _RepeatGameSheetState extends ConsumerState<RepeatGameSheet> {
  int _step = 0; // 0: Who, 1: Change Players, 2: Table & Game, 3: Review
  
  bool _samePlayers = true;

  TableModel? _selectedTable;
  late GameType _gameType;
  int? _targetPoints;
  late GameMode _mode;
  
  // Standard configs
  BillingType _billingType = BillingType.perMinute;
  MatchType _matchType = MatchType.loserPays;
  int _totalFrames = 1;

  // Players
  final List<PlayerSelection?> _teamASelections = [];
  final List<PlayerSelection?> _teamBSelections = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _gameType = widget.originalSession.gameType;
    _targetPoints = widget.originalSession.targetPoints;
    _mode = widget.originalSession.mode;
    _billingType = widget.originalSession.billingType;
    _matchType = widget.originalSession.matchType;
    _totalFrames = widget.originalSession.totalFrames;

    // Load initial players
    if (widget.originalSession.playerIdentities != null) {
      for (final pName in widget.originalSession.teamA) {
        _teamASelections.add(PlayerSelection(
          id: widget.originalSession.playerIdentities![pName], 
          name: pName,
        ));
      }
      for (final pName in widget.originalSession.teamB) {
        _teamBSelections.add(PlayerSelection(
          id: widget.originalSession.playerIdentities![pName], 
          name: pName,
        ));
      }
    } else {
      for (final pName in widget.originalSession.teamA) {
        _teamASelections.add(PlayerSelection(name: pName));
      }
      for (final pName in widget.originalSession.teamB) {
        _teamBSelections.add(PlayerSelection(name: pName));
      }
    }
    
    if (_teamASelections.isEmpty) _teamASelections.add(null);
    if (_teamBSelections.isEmpty) _teamBSelections.add(null);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final tables = ref.watch(resolvedTablesProvider);

    if (_selectedTable == null) {
      final orig = tables.where((t) => t.id == widget.originalSession.tableId && t.status == TableStatus.available).firstOrNull;
      if (orig != null) {
        _selectedTable = orig;
      } else {
        _selectedTable = tables.where((t) => t.status == TableStatus.available).firstOrNull;
      }
    }

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.9),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Handle
          Container(
            width: 40, height: 4, margin: const EdgeInsets.only(top: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withOpacity(0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Repeat This Game', style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold)),
                IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
              ],
            ),
          ),
          const Divider(height: 1),

          Expanded(
            child: ListView(
              padding: const EdgeInsets.all(20),
              children: [
                if (_step == 0) ..._buildStep0(theme),
                if (_step == 1) ..._buildStep1(theme),
                if (_step == 2) ..._buildStep2(theme, tables),
                if (_step == 3) ..._buildStep3(theme),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _handleNext,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary, foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0,
                ),
                child: _isLoading 
                    ? const SizedBox(height: 24, width: 24, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : Text(_step == 3 ? 'Start Game' : 'Continue', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _handleNext() {
    if (_step == 0) {
      setState(() => _step = _samePlayers ? 2 : 1);
    } else if (_step == 1) {
      setState(() => _step = 2);
    } else if (_step == 2) {
      if (_selectedTable == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please select an available table'), backgroundColor: AppColors.error));
        return;
      }
      setState(() => _step = 3);
    } else if (_step == 3) {
      _startGame();
    }
  }

  List<Widget> _buildStep0(ThemeData theme) {
    return [
      Text('Who will play?', style: theme.textTheme.titleMedium),
      const Gap(16),
      _buildOptionCard(
        title: 'Same Players', subtitle: 'Keep the exact same players and teams.', icon: Icons.group,
        isSelected: _samePlayers,
        onTap: () => setState(() => _samePlayers = true),
      ),
      const Gap(12),
      _buildOptionCard(
        title: 'Change Players', subtitle: 'Add or remove players, or change teams.', icon: Icons.group_add,
        isSelected: !_samePlayers,
        onTap: () => setState(() => _samePlayers = false),
      ),
    ];
  }

  Widget _buildOptionCard({required String title, required String subtitle, required IconData icon, required bool isSelected, required VoidCallback onTap}) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: isSelected ? AppColors.primary : Colors.grey.shade300, width: isSelected ? 2 : 1),
          borderRadius: BorderRadius.circular(12),
          color: isSelected ? AppColors.primary.withOpacity(0.05) : Colors.transparent,
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
            const Gap(16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: isSelected ? AppColors.primary : Colors.black87)),
                  Text(subtitle, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildStep1(ThemeData theme) {
    return [
      Text('Mode', style: theme.textTheme.labelMedium),
      const Gap(8),
      Row(
        children: GameMode.values.map((mode) {
          final isSelected = _mode == mode;
          return Expanded(
            child: InkWell(
              onTap: () => setState(() => _mode = mode),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 12),
                decoration: BoxDecoration(
                  color: isSelected ? AppColors.primary : Colors.transparent,
                  border: Border.all(color: isSelected ? AppColors.primary : theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Text(mode == GameMode.team ? 'Team' : 'Solo', style: TextStyle(color: isSelected ? Colors.white : theme.colorScheme.onSurface, fontWeight: FontWeight.w600)),
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
    ];
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
                  child: PlayerSearchField(
                    hint: 'Select or create player',
                    initialSelection: selections[index],
                    onSelected: (selection) => setState(() => selections[index] = selection),
                  ),
                ),
                if (selections.length > 1 || _mode == GameMode.team)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                    onPressed: () => setState(() => selections.removeAt(index)),
                  ),
              ],
            ),
          );
        }),
        if (selections.length < maxPlayers)
          TextButton.icon(
            onPressed: () => setState(() => selections.add(null)),
            icon: const Icon(Icons.add), label: const Text('Add Player'),
          ),
      ],
    );
  }

  List<Widget> _buildStep2(ThemeData theme, List<TableModel> tables) {
    return [
      Text('Select Table', style: theme.textTheme.labelMedium),
      const Gap(8),
      DropdownButtonFormField<TableModel>(
        isExpanded: true,
        value: _selectedTable,
        decoration: InputDecoration(isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        items: tables.where((t) => t.status == TableStatus.available).map((t) => DropdownMenuItem(value: t, child: Text(t.name))).toList(),
        onChanged: (val) {
          if (val != null) setState(() {
            _selectedTable = val;
            if (val.type != TableType.snooker && _gameType == GameType.rummy) _gameType = GameType.standard;
          });
        },
      ),
      const Gap(24),
      Text('Game Type', style: theme.textTheme.labelMedium),
      const Gap(8),
      DropdownButtonFormField<GameType>(
        isExpanded: true, value: _gameType,
        decoration: InputDecoration(isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
        items: GameType.values.where((t) => !(t == GameType.rummy && _selectedTable?.type != TableType.snooker)).map((t) => DropdownMenuItem(value: t, child: Text(t == GameType.standard ? 'Standard' : t == GameType.race ? 'Race' : 'Rummy'))).toList(),
        onChanged: (val) {
          if (val != null) setState(() => _gameType = val);
        },
      ),

      const Gap(24),
      if (_gameType == GameType.standard) ...[
        Text('Billing Type', style: theme.textTheme.labelMedium),
        const Gap(8),
        DropdownButtonFormField<BillingType>(
          isExpanded: true, value: _billingType,
          decoration: InputDecoration(isDense: true, border: OutlineInputBorder(borderRadius: BorderRadius.circular(12))),
          items: BillingType.values.where((t) => !(_selectedTable?.type == TableType.snooker && t == BillingType.perFrame)).map((t) => DropdownMenuItem(value: t, child: Text(t.displayName))).toList(),
          onChanged: (v) => setState(() => _billingType = v!),
        ),
      ],
    ];
  }

  List<Widget> _buildStep3(ThemeData theme) {
    return [
      Text('Review & Start', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
      const Gap(16),
      _buildSummaryRow('Table', _selectedTable?.name ?? 'None'),
      _buildSummaryRow('Game Type', _gameType == GameType.standard ? 'Standard' : _gameType == GameType.race ? 'Race' : 'Rummy'),

      _buildSummaryRow('Billing', _gameType == GameType.standard ? _billingType.displayName : 'Per Minute (Fixed)'),
      const Gap(12),
      Text('Players', style: theme.textTheme.labelMedium),
      const Gap(4),
      if (_mode == GameMode.solo) 
        Text(_teamASelections.where((p) => p != null && p.name.trim().isNotEmpty).map((p) => p!.name).join(', '))
      else ...[
        Text('Team A: '),
        Text('Team B: '),
      ],
    ];
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Future<void> _startGame() async {
    // 1. Frame validation
    if (_gameType == GameType.standard && _billingType == BillingType.perFrame) {
      if (_totalFrames <= 0) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Frame count must be a valid number greater than 0.')));
        return;
      }
    }

    // 2. Duplicate Players Check
    final duplicateError = GameValidationUtils.validateDuplicatePlayersWithinGame(
      _teamASelections, 
      _mode == GameMode.team ? _teamBSelections : []
    );
    
    if (duplicateError != null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(duplicateError)));
      return;
    }

    // 3. Active Elsewhere Check
    if (_selectedTable != null) {
      final activeElsewhereError = await GameValidationUtils.checkPlayerActiveElsewhere(
        [..._teamASelections, if (_mode == GameMode.team) ..._teamBSelections], 
        ref, 
        _selectedTable!.id
      );

      if (activeElsewhereError != null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(activeElsewhereError)));
        return;
      }
    }

    setState(() => _isLoading = true);

    try {
      final teamAPlayers = _teamASelections.where((p) => p != null && p.name.trim().isNotEmpty).map((p) => p!).toList();
      final teamBPlayers = _mode == GameMode.team ? _teamBSelections.where((p) => p != null && p.name.trim().isNotEmpty).map((p) => p!).toList() : <PlayerSelection>[];

      final combinedSelections = [...teamAPlayers, ...teamBPlayers];
      final actualBillingType = _gameType == GameType.standard ? _billingType : BillingType.perMinute;
      
      if (combinedSelections.isEmpty) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('At least one player is required.'), backgroundColor: AppColors.error));
        setState(() => _isLoading = false);
        return;
      }

      if (_selectedTable == null) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('No table selected.'), backgroundColor: AppColors.error));
        setState(() => _isLoading = false);
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
            resolvedIdentities[p.name] = existingMatch.id;
            finalPlayerIds.add(existingMatch.id);
          } else {
            final newId = FirebaseFirestore.instance.collection('credits').doc().id;
            resolvedIdentities[p.name] = newId;
            finalPlayerIds.add(newId);
            
            newProfilesToCreate.add(PlayerProfile(
              id: newId, name: p.name.trim(), outstandingAmount: 0.0,
              totalPendingTransactions: 0, lastTransactionDate: DateTime.now(),
            ));
          }
        }
      }

      final teamAIds = teamAPlayers.map((p) => p.name).toList();
      final teamBIds = teamBPlayers.map((p) => p.name).toList();

      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      
      final currentStaff = ref.read(currentStaffProvider).value;
      final staffName = currentStaff?.name ?? 'Admin';
      final staffId = currentStaff?.id ?? 'admin';

      final auditLog = AuditLog(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        editedBy: staffName,
        timestamp: now,
        field: 'Game Repeated',
        previousValue: 'Original ID: ${widget.originalSession.id}',
        newValue: _samePlayers ? 'Same Players' : 'Changed Players',
      );

      final gameSession = GameSession(
        date: dateStr,
        id: FirebaseFirestore.instance.collection('games').doc().id,
        tableId: _selectedTable!.id,
        tableName: _selectedTable!.name,
        tableType: _selectedTable!.type,
        gameType: _gameType,
        mode: _mode,
        startTime: now,
        status: TableStatus.running,
        targetPoints: _targetPoints,
        billingType: actualBillingType,
        matchType: _gameType == GameType.standard ? _matchType : MatchType.friendly,
        totalFrames: (_gameType == GameType.standard && actualBillingType == BillingType.perFrame) ? _totalFrames : 1,
        framesPlayed: 0,
        teamA: teamAIds,
        teamB: teamBIds,
        playerIds: finalPlayerIds,
        playerIdentities: resolvedIdentities,
        orders: const [],
        pauseTimes: const [],
        resumeTimes: const [],
        createdByUserId: staffId,
        createdByName: staffName,
        auditLogs: [auditLog],
      );

      final creditRepo = ref.read(creditRepositoryProvider);
      final gamesRepo = ref.read(gamesRepositoryProvider);

      if (mounted) Navigator.pop(context);

      Future.delayed(const Duration(milliseconds: 400), () async {
        try {
          for (final profile in newProfilesToCreate) {
            await creditRepo.savePlayerProfile(profile);
          }
          await gamesRepo.startGame(gameSession);
        } catch (e) {
          debugPrint('Error in background repeat game: $e');
        }
      });

    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }
}
