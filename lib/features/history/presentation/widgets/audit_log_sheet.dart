import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:snooker_club/core/constants/firebase_constants.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/widgets/loading/skeleton_loader.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/presentation/screens/bill_details_screen.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';

class AuditLogSheet extends ConsumerWidget {
  const AuditLogSheet({super.key});

  Future<void> _openBillDetails(BuildContext context, WidgetRef ref, String gameId) async {
    final clubId = ref.read(clubIdProvider);
    if (clubId == null) return;
    try {
      final doc = await FirebaseFirestore.instance
          .collection(FirebaseConstants.clubsCollection)
          .doc(clubId)
          .collection(FirebaseConstants.gamesCollection)
          .doc(gameId)
          .get();
      if (doc.exists && doc.data() != null && context.mounted) {
        final session = GameSession.fromMap(doc.data()!);
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => BillDetailsScreen(session: session),
          ),
        );
      } else if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Original bill is no longer available in database.'),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not load bill: $e')),
        );
      }
    }
  }

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
                  'Activity & Audit Log',
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
                separatorBuilder: (context, index) => const Gap(12),
                itemBuilder: (context, index) => const SkeletonLoader(height: 80, borderRadius: 12),
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
                      'No activity logs found.',
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  );
                }

                return ListView.separated(
                  padding: const EdgeInsets.all(20),
                  itemCount: logs.length,
                  separatorBuilder: (context, index) => const Gap(12),
                  itemBuilder: (context, index) {
                    final log = logs[index];
                    final fieldLower = log.field.toLowerCase();
                    final bool isConsolidation = fieldLower.contains('consolidat');
                    final bool isPending = fieldLower.contains('pending');
                    final bool isCancelled = fieldLower.contains('cancel');

                    final Color primaryColor = isConsolidation
                        ? AppColors.primary
                        : isPending
                            ? Colors.orange
                            : AppColors.error;

                    final IconData icon = isConsolidation
                        ? Icons.merge_type
                        : isPending
                            ? Icons.hourglass_top
                            : isCancelled
                                ? Icons.cancel_outlined
                                : Icons.delete_forever;

                    final String actionBy = isConsolidation
                        ? 'Consolidated by: ${log.editedBy}'
                        : isPending
                            ? 'Marked pending by: ${log.editedBy}'
                            : isCancelled
                                ? 'Cancelled by: ${log.editedBy}'
                                : 'Deleted by: ${log.editedBy}';

                    return Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(icon, size: 16, color: primaryColor),
                              const Gap(6),
                              Expanded(
                                child: Text(
                                  log.field,
                                  style: theme.textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
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
                            actionBy,
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
                          if (isConsolidation && log.recordId != null) ...[
                            const Gap(10),
                            InkWell(
                              onTap: () => _openBillDetails(context, ref, log.recordId!),
                              borderRadius: BorderRadius.circular(8),
                              child: Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.receipt_long, size: 14, color: AppColors.primary),
                                    const Gap(6),
                                    Text(
                                      'View Consolidated Bill',
                                      style: theme.textTheme.labelMedium?.copyWith(
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Gap(4),
                                    const Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.primary),
                                  ],
                                ),
                              ),
                            ),
                          ],
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
