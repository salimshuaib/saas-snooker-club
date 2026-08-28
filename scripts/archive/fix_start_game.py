import os
import re

def fix_start_game():
    path = 'lib/features/games/presentation/widgets/game_setup_sheet.dart'
    if not os.path.exists(path):
        return
        
    with open(path, 'r', encoding='utf-8') as f:
        content = f.read()

    # We need to replace the whole _startGame method
    pattern = r"Future<void> _startGame\(\) async \{[\s\S]*?^  \}"
    
    replacement = """Future<void> _startGame() async {
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
              
              final newProfile = PlayerProfile(
                id: newId,
                name: p.name.trim(),
                outstandingAmount: 0.0,
                totalPendingTransactions: 0,
                lastTransactionDate: DateTime.now(),
              );
              await FirebaseFirestore.instance.collection('credits').doc(newId).set(newProfile.toMap());
            }
          } else {
            final newId = FirebaseFirestore.instance.collection('credits').doc().id;
            resolvedIdentities[p.name] = newId;
            finalPlayerIds.add(newId);
            
            final newProfile = PlayerProfile(
              id: newId,
              name: p.name.trim(),
              outstandingAmount: 0.0,
              totalPendingTransactions: 0,
              lastTransactionDate: DateTime.now(),
            );
            await FirebaseFirestore.instance.collection('credits').doc(newId).set(newProfile.toMap());
          }
        }
      }

      final teamAIds = teamAPlayers.map((p) => p.name).toList();
      final teamBIds = teamBPlayers.map((p) => p.name).toList();

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
        startTime: DateTime.now(),
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
      );

      await ref.read(gamesRepositoryProvider).startGame(gameSession);

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error starting game: $e'), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }"""
  
    content = re.sub(pattern, replacement, content, flags=re.MULTILINE)

    with open(path, 'w', encoding='utf-8') as f:
        f.write(content)

if __name__ == '__main__':
    fix_start_game()
