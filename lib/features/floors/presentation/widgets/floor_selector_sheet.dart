import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_club/core/routes/route_names.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/theme/app_typography.dart';
import 'package:snooker_club/features/floors/providers/floor_providers.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';

class FloorSelectorSheet extends ConsumerWidget {
  const FloorSelectorSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final floors = ref.watch(floorsProvider).value ?? [];
    final selectedFloorId = ref.watch(selectedFloorIdProvider);
    final tables = ref.watch(resolvedTablesProvider);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.symmetric(vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Select Floor',
                  style: AppTypography.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.pop(context),
                ),
              ],
            ),
          ),
          const Divider(),
          Flexible(
            child: ListView(
              shrinkWrap: true,
              children: [
                _buildFloorItem(
                  context,
                  ref,
                  id: null,
                  name: 'All Floors',
                  tableCount: tables.length,
                  isSelected: selectedFloorId == null,
                  icon: Icons.layers,
                ),
                ...floors.map((floor) {
                  final count = tables.where((t) => t.floorId == floor.id).length;
                  return _buildFloorItem(
                    context,
                    ref,
                    id: floor.id,
                    name: floor.name,
                    tableCount: count,
                    isSelected: selectedFloorId == floor.id,
                  );
                }),
              ],
            ),
          ),
          const Divider(),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            child: ElevatedButton.icon(
              onPressed: () {
                Navigator.pop(context);
                context.push(RouteNames.floorManagement);
              },
              icon: const Icon(Icons.add),
              label: const Text('Manage Floors'),
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 50),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFloorItem(
    BuildContext context,
    WidgetRef ref, {
    required String? id,
    required String name,
    required int tableCount,
    required bool isSelected,
    IconData icon = Icons.business,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24),
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : Colors.grey,
      ),
      title: Text(
        name,
        style: TextStyle(
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? AppColors.primary : Colors.black87,
        ),
      ),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '$tableCount tables',
            style: const TextStyle(color: Colors.grey, fontSize: 13),
          ),
          if (isSelected) ...[
            const SizedBox(width: 12),
            const Icon(Icons.check_circle, color: AppColors.primary),
          ],
        ],
      ),
      onTap: () {
        ref.read(selectedFloorIdProvider.notifier).state = id;
        Navigator.pop(context);
      },
    );
  }
}
