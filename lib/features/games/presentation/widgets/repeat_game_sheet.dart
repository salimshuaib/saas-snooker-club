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
import 'package:snooker_club/features/games/domain/config/pricing_config.dart';

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
  
  // Standard configs
  BillingType _billingType = BillingType.perMinute;

  int _totalFrames = 1;

  // Players
  final List<PlayerSelection?> _playerSelections = [];

  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _billingType = widget.originalSession.billingType;
    _totalFrames = widget.originalSession.totalFrames;

    // Load initial players
    if (widget.originalSession.playerIdentities != null) {
      for (final pName in widget.originalSession.players) {
        _playerSelections.add(PlayerSelection(
          id: widget.originalSession.playerIdentities![pName], 
          name: pName,
        ));
      }
    } else {
      for (final pName in widget.originalSession.players) {
        _playerSelections.add(PlayerSelection(name: pName));
      }
    }
    
    if (_playerSelections.isEmpty) _playerSelections.add(null);
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

    return Material(
      color: Colors.transparent,
      child: Container(
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
      Text('Players', style: theme.textTheme.labelMedium),
      const Gap(8),
      _buildPlayerSection('Players', _playerSelections, 10, theme),
    ];
  }

  Widget _buildPlayerSection(String title, List<PlayerSelection?> list, int max, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < list.length; i++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: PlayerSearchField(
                    hint: 'Player ${i + 1}',
                    initialSelection: list[i],
                    onSelected: (selection) {
                      setState(() {
                        list[i] = selection;
                      });
                    },
                  ),
                ),
                if (list.length > 1)
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline, color: Colors.red),
                    onPressed: () => setState(() => list.removeAt(i)),
                  ),
              ],
            ),
          ),
        if (list.length < max)
          TextButton.icon(
            onPressed: () => setState(() => list.add(null)),
            icon: const Icon(Icons.add),
            label: const Text('Add Player'),
          ),
      ],
    );
  }

  List<Widget> _buildStep2(ThemeData theme, List<TableModel> tables) {
    // Determine available billing types for the selected table
    final availableBilling = _selectedTable != null 
        ? TablePricingConfig.supportedBillingTypes(_selectedTable!, GameType.standard)
        : <BillingType>[BillingType.perMinute];
    
    if (!availableBilling.contains(_billingType)) {
      _billingType = availableBilling.first;
    }

    return [
      Text('Table', style: theme.textTheme.labelMedium),
      const Gap(8),
      Wrap(
        spacing: 8, runSpacing: 8,
        children: tables.where((t) => t.status == TableStatus.available || t.id == _selectedTable?.id).map((t) {
          final isSelected = _selectedTable?.id == t.id;
          final isUnavailable = t.status != TableStatus.available && !isSelected;
          return ChoiceChip(
            label: Text(t.name),
            selected: isSelected,
            onSelected: isUnavailable ? null : (selected) {
              if (selected) setState(() => _selectedTable = t);
            },
            selectedColor: AppColors.primary,
            labelStyle: TextStyle(color: isSelected ? Colors.white : (isUnavailable ? Colors.grey : Colors.black)),
          );
        }).toList(),
      ),
      if (tables.isEmpty || tables.where((t) => t.status == TableStatus.available).isEmpty)
        Padding(
          padding: const EdgeInsets.only(top: 8),
          child: Text('No tables currently available.', style: TextStyle(color: Colors.red.shade400)),
        ),
        
      const Gap(24),
      Text('Billing Type', style: theme.textTheme.labelMedium),
      const Gap(8),
      if (_selectedTable == null)
        const Text('Select a table first', style: TextStyle(color: Colors.grey, fontStyle: FontStyle.italic))
      else
        Wrap(
          spacing: 8,
          children: availableBilling.map((bt) {
            final isSelected = _billingType == bt;
            return ChoiceChip(
              label: Text(bt.name.toUpperCase()),
              selected: isSelected,
              onSelected: (selected) {
                if (selected) setState(() => _billingType = bt);
              },
              selectedColor: AppColors.primary,
              labelStyle: TextStyle(color: isSelected ? Colors.white : Colors.black),
            );
          }).toList(),
        ),

      if (_billingType == BillingType.perFrame) ...[
        const Gap(24),
        Text('Total Frames', style: theme.textTheme.labelMedium),
        const Gap(8),
        Row(
          children: [
            IconButton(
              icon: const Icon(Icons.remove_circle_outline),
              onPressed: _totalFrames > 1 ? () => setState(() => _totalFrames--) : null,
            ),
            Text('$_totalFrames', style: theme.textTheme.titleMedium),
            IconButton(
              icon: const Icon(Icons.add_circle_outline),
              onPressed: () => setState(() => _totalFrames++),
            ),
          ],
        ),
      ],
    ];
  }

  List<Widget> _buildStep3(ThemeData theme) {
    return [
      Text('Review', style: theme.textTheme.labelMedium),
      const Gap(16),
      _buildReviewRow('Table', _selectedTable?.name ?? 'None'),
      _buildReviewRow('Billing', _billingType.name.toUpperCase()),
      if (_billingType == BillingType.perFrame)
        _buildReviewRow('Frames', '$_totalFrames'),
      const Gap(16),
      const Text('Players:', style: TextStyle(fontWeight: FontWeight.bold)),
      const Gap(8),
      ..._playerSelections
          .where((p) => p != null && p.name.trim().isNotEmpty)
          .map((p) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Text('• ${p!.name}'),
              )),
    ];
  }

  Widget _buildReviewRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
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
    if (_billingType == BillingType.perFrame) {
      if (_totalFrames <= 0) {
        if (mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Frame count must be a valid number greater than 0.')));
        return;
      }
    }

    // 2. Duplicate Players Check
    final duplicateError = GameValidationUtils.validateDuplicatePlayersWithinGame(
      _playerSelections, 
      []
    );
    
    if (duplicateError != null) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(duplicateError)));
      return;
    }

    // 3. Active Elsewhere Check
    if (_selectedTable != null) {
      final activeElsewhereError = await GameValidationUtils.checkPlayerActiveElsewhere(
        _playerSelections, 
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
      final combinedSelections = _playerSelections.where((p) => p != null && p.name.trim().isNotEmpty).map((p) => p!).toList();
      final actualBillingType = _billingType;
      
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
        startTime: now,
        status: TableStatus.running,
        mode: GameMode.solo,
      matchType: MatchType.friendly,
      billingType: actualBillingType,
        totalFrames: (actualBillingType == BillingType.perFrame) ? _totalFrames : 1,
        framesPlayed: 0,
        teamA: combinedSelections.map((p) => p.name).toList(),
        teamB: const [],
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
