import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/features/credit/presentation/widgets/player_search_field.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/utils/game_validation_utils.dart';

class MarkPendingDialog extends ConsumerStatefulWidget {
  const MarkPendingDialog({Key? key}) : super(key: key);

  @override
  ConsumerState<MarkPendingDialog> createState() => _MarkPendingDialogState();
}

class _MarkPendingDialogState extends ConsumerState<MarkPendingDialog> {
  final List<PlayerSelection?> _selections = [null];

  void _addPlayerRow() {
    setState(() {
      _selections.add(null);
    });
  }

  void _removePlayerRow(int index) {
    setState(() {
      _selections.removeAt(index);
      if (_selections.isEmpty) _selections.add(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    final hasValidSelections = _selections.every((s) => s != null && s.name.trim().isNotEmpty) && _selections.isNotEmpty;

    return AlertDialog(
      title: const Text('Mark as Pending?'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Are you willing to end this game and mark payment as pending?'),
            const Gap(16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Players', style: TextStyle(fontWeight: FontWeight.bold)),
                TextButton.icon(
                  onPressed: _addPlayerRow,
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
            const Gap(12),
            ...List.generate(_selections.length, (i) {
               return Padding(
                 padding: const EdgeInsets.only(bottom: 8.0),
                 child: Row(
                   children: [
                     Expanded(
                       child: PlayerSearchField(
                         hint: 'Search Customer...',
                         initialSelection: _selections[i],
                         onSelected: (selection) {
                           setState(() {
                             _selections[i] = selection;
                           });
                         },
                       ),
                     ),
                     if (_selections.length > 1)
                       IconButton(
                         icon: const Icon(Icons.remove_circle_outline, color: AppColors.error),
                         onPressed: () => _removePlayerRow(i),
                       ),
                   ],
                 ),
               );
            }),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, null),
          child: const Text('No'),
        ),
        FilledButton(
          onPressed: hasValidSelections ? () {
             final validPlayers = _selections.where((s) => s != null && s.name.trim().isNotEmpty).cast<PlayerSelection>().toList();
               
               final duplicateError = GameValidationUtils.validateDuplicatePlayersWithinGame(validPlayers, []);
               if (duplicateError != null) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(duplicateError)));
                 return;
               }

               final dbNameError = GameValidationUtils.validateNameNotExistingInDatabase(validPlayers, ref);
               if (dbNameError != null) {
                 ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(dbNameError)));
                 return;
               }

               Navigator.pop(context, validPlayers);
          } : null,
          style: FilledButton.styleFrom(backgroundColor: Colors.orange),
          child: const Text('Yes'),
        ),
      ],
    );
  }
}



