import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/widgets/loading/skeleton_loader.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';

class AuditLogSheet extends ConsumerWidget {
  const AuditLogSheet({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final auditLogsAsync = ref.watch(auditLogsProvider);

    return Container(
      height: MediaQuery.of(context).size.height * 0.8,
      padding: const EdgeInsets.only(top: 8),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
      ),
      child: Column(
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            margin: const EdgeInsets.only(bottom: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              children: [
                Icon(Icons.history, color: theme.colorScheme.primary),
                const Gap(8),
                Text(
                  'Deletion Audit Log',
                  style: theme.textTheme.titleLarge?.copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
          ),
          const Divider(),
          
          Expanded(
            child: auditLogsAsync.when(
              loading: () => ListView.separated(
                padding: const EdgeInsets.all(20),
                itemCount: 5,
                separatorBuilder: (_, __) => const Gap(12),
                itemBuilder: (_, __) => const SkeletonLoader(height: 80, borderRadius: 12),
              ),
              error: (err, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text(
                    'Error loading logs:\n$err',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: theme.colorScheme.error),
                  ),
                ),
              ),
              data: (logs) {
                if (logs.isEmpty) {
                  return Center(
                    child: Text(
                      'No deletion logs found.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: logs.length,
                  separatorBuilder: (_, __) => const Gap(12),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.error.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: AppColors.error.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.delete_forever, size: 16, color: AppColors.error),
                              const Gap(6),
                              Expanded(
                                child: Text(
                                  log.field,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.error,
                                  ),
                                ),
                              ),
                              Text(
                                log.formattedDate,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ],
                          ),
                          const Gap(8),
                          Text(
                            'Deleted by: ${log.editedBy}',
                            style: theme.textTheme.bodyMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            log.newValue,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const Gap(4),
                          Text(
                            log.previousValue,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
