import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';

class ResourceManagementScreen extends ConsumerStatefulWidget {
  const ResourceManagementScreen({super.key});
  @override
  ConsumerState<ResourceManagementScreen> createState() => _ResourceManagementScreenState();
}

class _ResourceManagementScreenState extends ConsumerState<ResourceManagementScreen> {
  void _showAddResourceDialog() {
    showDialog(
      context: context,
      builder: (context) => const _AddResourceDialog(),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tablesAsync = ref.watch(tablesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Games & Tables'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddResourceDialog,
        child: const Icon(Icons.add),
      ),
      body: tablesAsync.when(
        data: (tables) {
          if (tables.isEmpty) {
            return const Center(child: Text('No resources found.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: tables.length,
            itemBuilder: (context, index) {
              final table = tables[index];
              return Card(
                child: ListTile(
                  title: Text(table.name),
                  subtitle: Text(table.type.displayName),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () {
                          showDialog(
                            context: context,
                            builder: (context) => _RenameResourceDialog(table),
                          );
                        },
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () async {
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              title: const Text('Delete Resource'),
                              content: Text('Are you sure you want to delete ${table.name}?'),
                              actions: [
                                TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Cancel')),
                                FilledButton(
                                  style: FilledButton.styleFrom(backgroundColor: Colors.red),
                                  onPressed: () => Navigator.pop(context, true),
                                  child: const Text('Delete'),
                                ),
                              ],
                            ),
                          );
                          if (confirm == true && context.mounted) {
                            await ref.read(gamesRepositoryProvider).deleteTable(table.id);
                          }
                        },
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text(err.toString())),
      ),
    );
  }
}

class _AddResourceDialog extends ConsumerStatefulWidget {
  const _AddResourceDialog();
  @override
  ConsumerState<_AddResourceDialog> createState() => _AddResourceDialogState();
}

class _AddResourceDialogState extends ConsumerState<_AddResourceDialog> {
  final _nameController = TextEditingController();
  TableType _type = TableType.snooker;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Add Resource'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextField(
            controller: _nameController,
            decoration: const InputDecoration(labelText: 'Name (e.g. PS5 - 1)'),
          ),
          const SizedBox(height: 16),
          DropdownButtonFormField<TableType>(
            value: _type,
            decoration: const InputDecoration(labelText: 'Resource Type'),
            items: TableType.values.map((t) => DropdownMenuItem(
              value: t,
              child: Text(t.displayName),
            )).toList(),
            onChanged: (v) {
              if (v != null) {
                setState(() => _type = v);
              }
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: _isLoading ? null : () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
          FilledButton(
            onPressed: _isLoading ? null : () async {
              if (_nameController.text.trim().isEmpty) return;
              setState(() => _isLoading = true);
              final newTable = TableModel(
                id: DateTime.now().millisecondsSinceEpoch.toString(),
                name: _nameController.text.trim(),
                type: _type,
                order: DateTime.now().millisecondsSinceEpoch,
              );
              await ref.read(gamesRepositoryProvider).addTable(newTable);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Add'),
          ),
        ],
      );
    }
  }

  class _RenameResourceDialog extends ConsumerStatefulWidget {
    final TableModel table;
    const _RenameResourceDialog(this.table);

    @override
    ConsumerState<_RenameResourceDialog> createState() => _RenameResourceDialogState();
  }

  class _RenameResourceDialogState extends ConsumerState<_RenameResourceDialog> {
    late final TextEditingController _nameController;
    bool _isLoading = false;

    @override
    void initState() {
      super.initState();
      _nameController = TextEditingController(text: widget.table.name);
    }

    @override
    Widget build(BuildContext context) {
      return AlertDialog(
        title: const Text('Rename Resource'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: _nameController,
              decoration: const InputDecoration(labelText: 'New Name'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: _isLoading ? null : () async {
              if (_nameController.text.trim().isEmpty) return;
              setState(() => _isLoading = true);
              final updatedTable = widget.table.copyWith(name: _nameController.text.trim());
              await ref.read(gamesRepositoryProvider).updateTable(updatedTable);
              if (context.mounted) {
                Navigator.pop(context);
              }
            },
            child: _isLoading ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('Save'),
          ),
        ],
      );
    }
  }
