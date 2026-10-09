import sys
import re

path = 'lib/features/games/presentation/widgets/active_game_card.dart'
with open(path, 'r', encoding='utf-8') as f:
    content = f.read()

import_lines = '''import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snooker_club/features/credit/domain/models/credit_models.dart';
import 'package:snooker_club/features/credit/providers/credit_providers.dart';
'''

content = content.replace("import 'package:flutter/material.dart';", "import 'package:flutter/material.dart';\n" + import_lines)

old_logic = '''    final repo = ref.read(gamesRepositoryProvider);

    if (selectedPlayers.length == 1) {
      await repo.markAsPendingBill(
        finalSession,
        customerId: selectedPlayers[0].id!,
        customerName: selectedPlayers[0].name,
      );
    } else {
      final playerMaps = selectedPlayers.map((p) => {'id': p.id!, 'name': p.name}).toList();
      await repo.markAsPendingBillWithSplits(finalSession, playerMaps);
    }'''

new_logic = '''    final repo = ref.read(gamesRepositoryProvider);
    final creditRepo = ref.read(creditRepositoryProvider);
    final allProfiles = ref.read(allCustomersProvider).value ?? [];
    final now = DateTime.now();

    final List<Map<String, String>> resolvedPlayers = [];

    for (final p in selectedPlayers) {
      if (p.id != null) {
        resolvedPlayers.add({'id': p.id!, 'name': p.name});
      } else {
        // Find existing match just in case
        final existingMatch = allProfiles.cast<PlayerProfile?>().firstWhere(
            (profile) => profile?.name.toLowerCase() == p.name.trim().toLowerCase(),
            orElse: () => null);

        if (existingMatch != null) {
          resolvedPlayers.add({'id': existingMatch.id, 'name': existingMatch.name});
        } else {
          // Create new profile
          final newId = FirebaseFirestore.instance.collection('dummy').doc().id;
          final newProfile = PlayerProfile(
            id: newId,
            name: p.name.trim(),
            createdAt: now,
            isActive: true,
          );
          await creditRepo.createPlayerProfile(newProfile);
          resolvedPlayers.add({'id': newId, 'name': newProfile.name});
        }
      }
    }

    if (resolvedPlayers.length == 1) {
      await repo.markAsPendingBill(
        finalSession,
        customerId: resolvedPlayers[0]['id']!,
        customerName: resolvedPlayers[0]['name']!,
      );
    } else {
      await repo.markAsPendingBillWithSplits(finalSession, resolvedPlayers);
    }'''

content = content.replace(old_logic, new_logic)

with open(path, 'w', encoding='utf-8') as f:
    f.write(content)
print('Patched active_game_card.dart for auto profile creation')
