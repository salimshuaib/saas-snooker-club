import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/floors/providers/floor_providers.dart';
import 'package:snooker_club/features/floors/presentation/widgets/floor_setup_sheet.dart';
import 'package:snooker_club/core/widgets/modals/app_modal.dart';


class FloorManagementScreen extends ConsumerWidget {
  const FloorManagementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final floorsAsync = ref.watch(floorsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Manage Floors'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          AppModal.showBottomSheet(
            context: context,
            isScrollControlled: true,
            builder: (_) => const FloorSetupSheet(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Floor'),
      ),
      body: floorsAsync.when(
        data: (floors) {
          if (floors.isEmpty) {
            return const Center(
              child: Text(
                'No floors configured.\nClick + Add Floor to create one.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey, fontSize: 16),
              ),
            );
          }

          return Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: ReorderableListView.builder(
                itemCount: floors.length,
                onReorder: (oldIndex, newIndex) {
                  if (newIndex > oldIndex) newIndex -= 1;
                  final list = List.of(floors);
                  final item = list.removeAt(oldIndex);
                  list.insert(newIndex, item);
                  ref.read(floorRepositoryProvider).reorderFloors(list);
                },
                itemBuilder: (context, index) {
                  final floor = floors[index];
                  return ListTile(
                    key: ValueKey(floor.id),
                    title: Text(floor.name),
                    leading: const Icon(Icons.drag_handle),
                    trailing: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        IconButton(
                          icon: const Icon(Icons.edit, color: AppColors.primary),
                          onPressed: () {
                            AppModal.showBottomSheet(
                              context: context,
                              isScrollControlled: true,
                              builder: (_) => FloorSetupSheet(floorToEdit: floor),
                            );
                          },
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete, color: AppColors.error),
                          onPressed: () async {
                            final confirm = await showDialog<bool>(
                              context: context,
                              builder: (ctx) => AlertDialog(
                                title: const Text('Delete Floor'),
                                content: Text('Are you sure you want to delete ${floor.name}?\nTables assigned to this floor will be unassigned.'),
                                actions: [
                                  TextButton(
                                    onPressed: () => Navigator.pop(ctx, false),
                                    child: const Text('Cancel'),
                                  ),
                                  FilledButton(
                                    onPressed: () => Navigator.pop(ctx, true),
                                    style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                                    child: const Text('Delete'),
                                  ),
                                ],
                              ),
                            );
                            if (confirm == true) {
                              ref.read(floorRepositoryProvider).deleteFloor(floor.id);
                            }
                          },
                        ),
                      ],
                    ),
                  );
                },
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => Center(child: Text('Error: $error')),
      ),
    );
  }
}
