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
  Set<String> _selectedTableIds = {};
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.floorToEdit?.name ?? '');
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.floorToEdit != null) {
        final tables = ref.read(resolvedTablesProvider);
        setState(() {
          _selectedTableIds = tables
              .where((t) => t.floorId == widget.floorToEdit!.id)
              .map((t) => t.id)
              .toSet();
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
    
    try {
      String floorId = widget.floorToEdit?.id ?? '';
      final name = _nameController.text.trim();
      
      if (floorId.isEmpty) {
        // Create
        final newFloor = FloorModel(
          id: '',
          name: name,
          createdAt: DateTime.now(),
        );
        // addFloor doesn't return the ID, so we'll generate it. 
        // Wait, our repository generates it if empty, but we need it for assigning tables.
        // Let's modify addFloor locally or use a manual ID.
        final docRef = FirebaseFirestore.instance.collection('dummy').doc(); // Just to generate ID
        floorId = docRef.id;
        await repo.addFloor(newFloor.copyWith(id: floorId));
      } else {
        // Update
        await repo.updateFloor(widget.floorToEdit!.copyWith(name: name));
      }

      // Assign tables
      // We unassign tables that were previously in this floor but now unchecked,
      // and assign the currently checked ones.
      final allTables = ref.read(resolvedTablesProvider);
      final previouslyAssigned = allTables.where((t) => t.floorId == floorId).map((t) => t.id).toSet();
      
      final toUnassign = previouslyAssigned.difference(_selectedTableIds);
      final toAssign = _selectedTableIds.difference(previouslyAssigned);

      if (toUnassign.isNotEmpty) {
        await repo.unassignTablesFromFloor(toUnassign.toList());
      }
      if (toAssign.isNotEmpty) {
        await repo.assignTablesToFloor(floorId, name, toAssign.toList());
      }
      // Note: If floor name changed, we might need to update the floorName in all assigned tables.
      if (widget.floorToEdit != null && widget.floorToEdit!.name != name) {
         await repo.assignTablesToFloor(floorId, name, _selectedTableIds.toList());
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
    final tables = ref.watch(resolvedTablesProvider);
    
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
            Text(
              widget.floorToEdit == null ? 'Create New Floor' : 'Edit Floor',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
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
              'Assign Tables',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            ConstrainedBox(
              constraints: BoxConstraints(
                maxHeight: MediaQuery.of(context).size.height * 0.4,
              ),
              child: tables.isEmpty
                  ? const Text('No tables available.')
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: tables.length,
                      itemBuilder: (context, index) {
                        final table = tables[index];
                        final isSelected = _selectedTableIds.contains(table.id);
                        final isAssignedElsewhere = table.floorId != null && table.floorId != widget.floorToEdit?.id;
                        
                        return CheckboxListTile(
                          title: Text(table.name),
                          subtitle: isAssignedElsewhere 
                              ? Text('Currently on ${table.floorName}', style: const TextStyle(color: Colors.orange, fontSize: 12)) 
                              : null,
                          value: isSelected,
                          onChanged: (val) {
                            setState(() {
                              if (val == true) {
                                _selectedTableIds.add(table.id);
                              } else {
                                _selectedTableIds.remove(table.id);
                              }
                            });
                          },
                        );
                      },
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
