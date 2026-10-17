import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/presentation/widgets/admin_passcode_dialog.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/happy_hour/domain/models/happy_hour_offer.dart';
import 'package:snooker_club/features/happy_hour/presentation/screens/happy_hour_offer_form.dart';
import 'package:snooker_club/features/happy_hour/providers/happy_hour_providers.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';

class HappyHourManagementScreen extends ConsumerWidget {
  const HappyHourManagementScreen({super.key});

  Future<void> _deleteOffer(
    BuildContext context,
    WidgetRef ref,
    HappyHourOffer offer,
  ) async {
    final settings = ref.read(appSettingsProvider);
    final requirePasscode = settings.security.requirePasscodeForDeletion;

    if (requirePasscode) {
      final isAuthorized = await showDialog<bool>(
        context: context,
        builder: (ctx) => const AdminPasscodeDialog(
          title: 'Confirm Deletion',
          subtitle: 'Enter passcode to permanently delete this offer.',
        ),
      );
      if (isAuthorized != true) return;
    } else {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (ctx) => AlertDialog(
          title: const Text('Delete Offer?'),
          content: Text(
            'Are you sure you want to permanently delete offer "${offer.name}" (${offer.code})?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text('Cancel'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.error,
              ),
              onPressed: () => Navigator.pop(ctx, true),
              child: const Text('Delete'),
            ),
          ],
        ),
      );
      if (confirmed != true) return;
    }

    try {
      final repo = ref.read(happyHourRepositoryProvider);
      await repo.deleteOffer(offer.id);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Offer "${offer.name}" deleted.'),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to delete offer: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final offersAsync = ref.watch(happyHourOffersProvider);
    final tables = ref.watch(resolvedTablesProvider);
    final tablesMap = {for (final t in tables) t.id: t.name};
    final dateFormat = DateFormat('dd MMM yyyy');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Happy Hour Offers'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            tooltip: 'Add Offer',
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const HappyHourOfferFormScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: offersAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.error_outline, size: 48, color: AppColors.error),
                const Gap(12),
                Text('Error loading offers: $err', textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
        data: (offers) {
          if (offers.isEmpty) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.discount_outlined,
                        size: 64,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const Gap(20),
                    Text(
                      'No Happy Hour Offers Yet',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const Gap(8),
                    Text(
                      'Create custom promotional rates for specific games and hours to boost off-peak attendance.',
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const Gap(24),
                    FilledButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const HappyHourOfferFormScreen(),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add),
                      label: const Text('Create First Offer'),
                    ),
                  ],
                ),
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: offers.length,
            separatorBuilder: (_, _) => const Gap(12),
            itemBuilder: (context, index) {
              final offer = offers[index];
              final isCurrentlyActive =
                  offer.isActive && offer.isTimeEligible(DateTime.now());

              return Card(
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: isCurrentlyActive
                        ? AppColors.success.withValues(alpha: 0.5)
                        : theme.colorScheme.outlineVariant,
                    width: isCurrentlyActive ? 1.5 : 1,
                  ),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header Row
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: isCurrentlyActive
                                  ? AppColors.success.withValues(alpha: 0.2)
                                  : (offer.isActive
                                      ? Colors.blue.withValues(alpha: 0.15)
                                      : Colors.grey.withValues(alpha: 0.15)),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(
                                  Icons.circle,
                                  size: 8,
                                  color: isCurrentlyActive
                                      ? AppColors.success
                                      : (offer.isActive
                                          ? Colors.blue
                                          : Colors.grey),
                                ),
                                const Gap(6),
                                Text(
                                  isCurrentlyActive
                                      ? 'LIVE NOW'
                                      : (offer.isActive ? 'SCHEDULED' : 'DISABLED'),
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isCurrentlyActive
                                        ? AppColors.success
                                        : (offer.isActive
                                            ? Colors.blue
                                            : Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Gap(8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surfaceContainerHighest,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              offer.code,
                              style: theme.textTheme.labelSmall?.copyWith(
                                fontWeight: FontWeight.bold,
                                letterSpacing: 1.1,
                              ),
                            ),
                          ),
                          const Spacer(),
                          Switch(
                            value: offer.isActive,
                            onChanged: (val) {
                              ref
                                  .read(happyHourRepositoryProvider)
                                  .toggleOfferActive(offer.id, val);
                            },
                          ),
                        ],
                      ),
                      const Gap(10),

                      // Offer Name
                      Text(
                        offer.name,
                        style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const Gap(8),

                      // Schedule info
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                          const Gap(6),
                          Text(
                            '${dateFormat.format(offer.startDate)} - ${dateFormat.format(offer.endDate)}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                      const Gap(4),
                      Row(
                        children: [
                          Icon(
                            offer.isOvernightSchedule
                                ? Icons.access_time
                                : Icons.access_time,
                            size: 14,
                            color: offer.isOvernightSchedule
                                ? Colors.amber
                                : theme.colorScheme.onSurfaceVariant,
                          ),
                          const Gap(6),
                          Text(
                            'Daily: ${offer.dailyStartTime} - ${offer.dailyEndTime}${offer.isOvernightSchedule ? " (Overnight)" : ""}',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: offer.isOvernightSchedule
                                  ? Colors.amber
                                  : theme.colorScheme.onSurfaceVariant,
                              fontWeight: offer.isOvernightSchedule
                                  ? FontWeight.w600
                                  : FontWeight.normal,
                            ),
                          ),
                        ],
                      ),
                      const Gap(12),

                      // Game promo prices chips
                      Wrap(
                        spacing: 8,
                        runSpacing: 6,
                        children: offer.gameOffers.entries.map((entry) {
                          final tableName = tablesMap[entry.key] ?? 'Table';
                          return Chip(
                            visualDensity: VisualDensity.compact,
                            labelPadding: const EdgeInsets.symmetric(horizontal: 4),
                            avatar: const Icon(Icons.table_bar, size: 14),
                            label: Text(
                              '$tableName: ₹${entry.value.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 12),
                            ),
                          );
                        }).toList(),
                      ),
                      const Divider(height: 24),

                      // Actions row
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton.icon(
                            onPressed: () => _deleteOffer(context, ref, offer),
                            icon: const Icon(Icons.delete_outline, size: 18),
                            label: const Text('Delete'),
                            style: TextButton.styleFrom(
                              foregroundColor: AppColors.error,
                            ),
                          ),
                          const Gap(8),
                          FilledButton.tonalIcon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      HappyHourOfferFormScreen(offer: offer),
                                ),
                              );
                            },
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: const Text('Edit'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
