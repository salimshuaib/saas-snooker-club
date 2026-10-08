import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/floors/domain/models/floor_model.dart';
import 'package:snooker_club/features/floors/providers/floor_providers.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FloorSetupSheet extends ConsumerStatefulWidget {
  final FloorModel? floorToEdit;

  const FloorSetupSheet({super.key, this.floorToEdit});

  @override
  ConsumerState<FloorSetupSheet> createState() => _FloorSetupSheetState();
}

class _FloorSetupSheetState extends ConsumerState<FloorSetupSheet> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  Map<TableType, int> _counts = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.floorToEdit?.name ?? '');
    
    for (final type in TableType.values) {
      _counts[type] = 0;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.floorToEdit != null) {
        final tables = ref.read(resolvedTablesProvider);
        setState(() {
          for (final t in tables.where((t) => t.floorId == widget.floorToEdit!.id)) {
            _counts[t.type] = (_counts[t.type] ?? 0) + 1;
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);
    final repo = ref.read(floorRepositoryProvider);
    final gamesRepo = ref.read(gamesRepositoryProvider);
    final allTables = ref.read(resolvedTablesProvider);
    
    try {
      String floorId = widget.floorToEdit?.id ?? '';
      final name = _nameController.text.trim();
      
      if (floorId.isEmpty) {
        final docRef = FirebaseFirestore.instance.collection('dummy').doc();
        floorId = docRef.id;
        final newFloor = FloorModel(
          id: floorId,
          name: name,
          createdAt: DateTime.now(),
        );
        await repo.addFloor(newFloor);
      } else {
        await repo.updateFloor(widget.floorToEdit!.copyWith(name: name));
      }

      for (final type in TableType.values) {
        final desiredCount = _counts[type] ?? 0;
        final currentTables = allTables.where((t) => t.floorId == floorId && t.type == type).toList();
        
        if (desiredCount > currentTables.length) {
          final toAdd = desiredCount - currentTables.length;
          final allTypeTables = allTables.where((t) => t.type == type).toList();
          int maxNum = 0;
          final r = RegExp(r'\d+');
          for (final t in allTypeTables) {
            final m = r.firstMatch(t.name);
            if (m != null) {
              final num = int.tryParse(m.group(0)!);
              if (num != null && num > maxNum) maxNum = num;
            }
          }
          
          for (int i = 0; i < toAdd; i++) {
            maxNum++;
            final newTable = TableModel(
              id: DateTime.now().millisecondsSinceEpoch.toString() + '_$i',
              name: '${type.displayName} $maxNum',
              type: type,
              order: DateTime.now().millisecondsSinceEpoch + i,
              floorId: floorId,
              floorName: name,
            );
            await gamesRepo.addTable(newTable);
          }
        } else if (desiredCount < currentTables.length) {
          final toRemove = currentTables.length - desiredCount;
          currentTables.sort((a, b) => b.name.compareTo(a.name));
          
          for (int i = 0; i < toRemove; i++) {
            await gamesRepo.deleteTable(currentTables[i].id);
          }
        }
      }
      
      if (widget.floorToEdit != null && widget.floorToEdit!.name != name) {
         final updatedTables = allTables.where((t) => t.floorId == floorId).map((t) => t.id).toList();
         if (updatedTables.isNotEmpty) {
           await repo.assignTablesToFloor(floorId, name, updatedTables);
         }
      }

      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom,
        left: 20,
        right: 20,
        top: 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  widget.floorToEdit == null ? 'Create New Floor' : 'Edit Floor',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _nameController,
              decoration: const InputDecoration(
                labelText: 'Floor Name (e.g. Ground Floor)',
                border: OutlineInputBorder(),
              ),
              validator: (val) => val == null || val.trim().isEmpty ? 'Enter a name' : null,
            ),
            const SizedBox(height: 24),
            const Text(
              'Assign Games',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: ListView(
                shrinkWrap: true,
                children: TableType.values.map((type) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          type.displayName,
                          style: const TextStyle(fontSize: 16),
                        ),
                        Row(
                          children: [
                            IconButton(
                              icon: const Icon(Icons.remove, color: Colors.redAccent),
                              onPressed: () {
                                if ((_counts[type] ?? 0) > 0) {
                                  setState(() {
                                    _counts[type] = (_counts[type] ?? 0) - 1;
                                  });
                                }
                              },
                            ),
                            SizedBox(
                              width: 30,
                              child: Text(
                                '${_counts[type] ?? 0}',
                                textAlign: TextAlign.center,
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add, color: Colors.green),
                              onPressed: () {
                                setState(() {
                                  _counts[type] = (_counts[type] ?? 0) + 1;
                                });
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isLoading ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
              child: _isLoading
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Text('Save Floor'),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
