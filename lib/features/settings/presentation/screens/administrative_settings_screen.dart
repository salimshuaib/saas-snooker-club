import 'package:snooker_club/l10n/app_localizations.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/settings/presentation/widgets/business_edit_sheet.dart';
import 'package:snooker_club/features/settings/presentation/widgets/change_passcode_dialog.dart';
import 'package:snooker_club/features/settings/presentation/widgets/pricing_edit_sheet.dart';
import 'package:snooker_club/features/settings/presentation/widgets/settings_section_card.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';

class AdministrativeSettingsScreen extends ConsumerWidget {
  const AdministrativeSettingsScreen({super.key});

  Widget _buildInfoTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            flex: 2,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(color: Colors.white70, fontSize: 13),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRateOverviewTile(String label, String rates) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
          Text(rates, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
        ],
      ),
    );
  }

  void _confirmClearCache(BuildContext context, WidgetRef ref) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Local Cache?'),
        content: const Text(
          'This will remove temporarily cached offline data on this device. No data will be deleted from your Firebase Cloud server.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: Text(AppLocalizations.of(context)!.cancel)),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppColors.error, foregroundColor: Colors.white),
            onPressed: () {
              ref.read(appSettingsProvider.notifier).clearLocalCache();
              Navigator.of(ctx).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Local offline cache cleared successfully.')),
              );
            },
            child: const Text('Clear Cache'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(appSettingsProvider);
    final currency = ref.watch(currencyProvider);
    final notifier = ref.read(appSettingsProvider.notifier);

    return Scaffold(
      appBar: AppBar(
        title: const Row(
          children: [
            Icon(Icons.lock, size: 18),
            Gap(8),
            Text('Administrative Settings'),
          ],
        ),
        centerTitle: false,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // Security & Permissions
          SettingsSectionCard(
            title: 'Security & Permissions',
            icon: Icons.security,
            iconColor: AppColors.error,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Require Passcode for Deletions'),
                subtitle: const Text('Enforce admin PIN when removing records from Games, Credit, and Sales'),
                value: settings.security.requirePasscodeForDeletion,
                onChanged: (val) => notifier.updateSecuritySettings(settings.security.copyWith(requirePasscodeForDeletion: val)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Administrator Passcode'),
                subtitle: const Text('Change the active PIN required for high-security actions'),
                trailing: ElevatedButton.icon(
                  onPressed: () => showDialog(context: context, builder: (_) => const ChangePasscodeDialog()),
                  icon: const Icon(Icons.lock_reset, size: 16),
                  label: const Text('Update PIN'),
                ),
              ),
            ],
          ),

          // Business Information
          SettingsSectionCard(
            title: 'Business Information',
            icon: Icons.business,
            iconColor: AppColors.primary,
            trailing: OutlinedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => BusinessEditSheet(initialSettings: settings.business),
                );
              },
              icon: const Icon(Icons.edit, size: 16),
              label: const Text('Edit'),
            ),
            children: [
              _buildInfoTile('Club Name', settings.business.clubName),
              _buildInfoTile('Contact Number', settings.business.contactNumber.isEmpty ? 'Not set' : settings.business.contactNumber),
              _buildInfoTile('Address / Location', settings.business.address.isEmpty ? 'Not set' : settings.business.address),
            ],
          ),

          // Game Rules & Timing
          SettingsSectionCard(
            title: 'Game Rules & Timing',
            icon: Icons.timer_outlined,
            iconColor: AppColors.running,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Frame Grace Period (Mins)'),
                subtitle: const Text('Time allowed before overtime charge begins'),
                trailing: DropdownButton<int>(
                  value: settings.game.frameGracePeriodMinutes,
                  underline: const SizedBox(),
                  items: [10, 15, 20, 25, 30].map((mins) {
                    return DropdownMenuItem(value: mins, child: Text('$mins Mins'));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      notifier.updateGameSettings(settings.game.copyWith(frameGracePeriodMinutes: val));
                    }
                  },
                ),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable Overtime Billing'),
                subtitle: const Text('Automatically calculate extra charges after grace period'),
                value: settings.game.enableOvertimeBilling,
                onChanged: (val) => notifier.updateGameSettings(settings.game.copyWith(enableOvertimeBilling: val)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Allow Pause & Resume'),
                subtitle: const Text('Permit operators to pause active table sessions'),
                value: settings.game.allowPauseResume,
                onChanged: (val) => notifier.updateGameSettings(settings.game.copyWith(allowPauseResume: val)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Max Players per Team'),
                subtitle: const Text('Maximum squad limit for games'),
                trailing: DropdownButton<int>(
                  value: settings.game.maxPlayersPerTeam,
                  underline: const SizedBox(),
                  items: [2, 3, 4, 5, 6].map((count) {
                    return DropdownMenuItem(value: count, child: Text('$count Players'));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      notifier.updateGameSettings(settings.game.copyWith(maxPlayersPerTeam: val));
                    }
                  },
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Default Match Type'),
                subtitle: const Text('Default preset when creating new table sessions'),
                trailing: DropdownButton<MatchType>(
                  value: settings.game.defaultMatchType,
                  underline: const SizedBox(),
                  items: MatchType.values.map((type) {
                    return DropdownMenuItem(value: type, child: Text(type == MatchType.friendly ? 'Friendly' : 'Tournament'));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      notifier.updateGameSettings(settings.game.copyWith(defaultMatchType: val));
                    }
                  },
                ),
              ),
            ],
          ),

          // Pricing Customization
          SettingsSectionCard(
            title: 'Pricing Customization',
            icon: Icons.price_change,
            iconColor: AppColors.tertiary,
            trailing: ElevatedButton.icon(
              onPressed: () {
                showModalBottomSheet(
                  context: context,
                  isScrollControlled: true,
                  shape: const RoundedRectangleBorder(
                    borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
                  ),
                  builder: (context) => PricingEditSheet(initialSettings: settings.pricing),
                );
              },
              icon: const Icon(Icons.tune, size: 16),
              label: const Text('Configure'),
            ),
            children: [
              _buildRateOverviewTile('Snooker (Per Min / 1h)', '${currency.symbol}${settings.pricing.snookerPerMinute.toStringAsFixed(2)} / ${currency.symbol}${settings.pricing.snookerOneHour.toStringAsFixed(0)}'),
              _buildRateOverviewTile('Indian Pool (Per Frame / 1h)', '${currency.symbol}${settings.pricing.indianPoolPerFrame.toStringAsFixed(0)} / ${currency.symbol}${settings.pricing.indianPoolOneHour.toStringAsFixed(0)}'),
              _buildRateOverviewTile('American Pool (Per Frame / 1h)', '${currency.symbol}${settings.pricing.americanPoolPerFrame.toStringAsFixed(0)} / ${currency.symbol}${settings.pricing.americanPoolOneHour.toStringAsFixed(0)}'),
            ],
          ),

          // Inventory Settings
          SettingsSectionCard(
            title: 'Inventory Settings',
            icon: Icons.inventory_2_outlined,
            iconColor: AppColors.available,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Enable Low Stock Alerts'),
                subtitle: const Text('Highlight inventory items falling below warning threshold'),
                value: settings.inventory.enableLowStockAlerts,
                onChanged: (val) => notifier.updateInventorySettings(settings.inventory.copyWith(enableLowStockAlerts: val)),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Low Stock Warning Threshold'),
                subtitle: const Text('Items at or below this count will flag as low stock'),
                trailing: DropdownButton<int>(
                  value: settings.inventory.lowStockThreshold,
                  underline: const SizedBox(),
                  items: [3, 5, 10, 15, 20].map((cnt) {
                    return DropdownMenuItem(value: cnt, child: Text('$cnt Units'));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      notifier.updateInventorySettings(settings.inventory.copyWith(lowStockThreshold: val));
                    }
                  },
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Default Initial Stock Quantity'),
                subtitle: const Text('Default stock count when registering new products'),
                trailing: DropdownButton<int>(
                  value: settings.inventory.defaultInitialQuantity,
                  underline: const SizedBox(),
                  items: [1, 5, 10, 20, 50, 100].map((cnt) {
                    return DropdownMenuItem(value: cnt, child: Text('$cnt Units'));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) {
                      notifier.updateInventorySettings(settings.inventory.copyWith(defaultInitialQuantity: val));
                    }
                  },
                ),
              ),
            ],
          ),

          // Data Management
          SettingsSectionCard(
            title: 'Data & Sync Management',
            icon: Icons.storage_rounded,
            iconColor: Colors.deepOrange,
            children: [
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    try {
                      await notifier.forceManualSync();
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Manual sync completed successfully.')),
                        );
                      }
                    } catch (e) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Sync failed: $e'), backgroundColor: AppColors.error),
                        );
                      }
                    }
                  },
                  icon: const Icon(Icons.cloud_sync, size: 18),
                  label: const Text('Force Manual Sync Now'),
                ),
              ),
              const Gap(12),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Refresh Cached Data'),
                subtitle: const Text('Reload in-memory data providers without deleting storage'),
                trailing: OutlinedButton(
                  onPressed: () {
                    ref.invalidate(resolvedTablesProvider);
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('In-memory cache refreshed.')),
                    );
                  },
                  child: const Text('Refresh'),
                ),
              ),
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Clear Local Offline Cache'),
                subtitle: const Text('Remove local offline persistence without affecting Firebase records'),
                trailing: OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: AppColors.error),
                  onPressed: () => _confirmClearCache(context, ref),
                  child: const Text('Clear Cache'),
                ),
              ),
            ],
          ),
          const Gap(32),
        ],
      ),
    );
  }
}
