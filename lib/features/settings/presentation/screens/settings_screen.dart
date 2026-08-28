import 'package:snooker_club/features/settings/presentation/screens/resource_management_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:gap/gap.dart';
import 'package:intl/intl.dart';
import 'package:snooker_club/core/models/currency.dart';
import 'package:snooker_club/core/providers/app_providers.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/widgets/dialogs/logout_dialog.dart';
import 'package:snooker_club/features/authentication/providers/auth_providers.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/settings/presentation/screens/administrative_settings_screen.dart';
import 'package:snooker_club/features/games/presentation/widgets/admin_passcode_dialog.dart';
import 'package:snooker_club/features/settings/presentation/widgets/settings_section_card.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:snooker_club/core/providers/update_provider.dart';
import 'package:snooker_club/core/providers/locale_provider.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final settings = ref.watch(appSettingsProvider);
    final themeMode = ref.watch(themeModeProvider);
    final currency = ref.watch(currencyProvider);
    final tables = ref.watch(resolvedTablesProvider);
    final syncStatus = ref.watch(firebaseSyncStatusProvider);
    final notifier = ref.read(appSettingsProvider.notifier);
    final packageInfo = ref.watch(packageInfoProvider);


    return Scaffold(
      appBar: AppBar(
        title: const Text('Club Configuration & Settings'),
        centerTitle: false,
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        children: [
          // 0. Administrative Settings
          SettingsSectionCard(
            title: 'Administrative Settings',
            icon: Icons.lock,
            iconColor: theme.colorScheme.error,
            children: [
              Text(
                'Manage business, pricing, security and system configuration',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const Gap(16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () async {
                    final bool? isAuthorized = await showDialog<bool>(
                      context: context,
                      builder: (context) => const AdminPasscodeDialog(
                        title: 'Administrative Access',
                        subtitle: 'Enter administrator passcode to continue.',
                      ),
                    );

                    if (isAuthorized == true && context.mounted) {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (context) => const AdministrativeSettingsScreen(),
                        ),
                      );
                    }
                  },
                  icon: const Icon(Icons.security, size: 18),
                  label: const Text('Access Administrative Settings'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.errorContainer,
                    foregroundColor: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),


          // 2. Table Configuration
          SettingsSectionCard(
            title: 'Table Configuration',
            icon: Icons.table_bar,
            iconColor: AppColors.secondary,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Text(
                  'Active club pool and snooker tables deployed across the facility:',
                  style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ),
              const Gap(8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildTableCountBadge('Snooker', tables.where((t) => t.type == TableType.snooker).length, Colors.red, context),
                  _buildTableCountBadge('Indian Pool', tables.where((t) => t.type == TableType.indianPool).length, Colors.amber, context),
                  _buildTableCountBadge('American Pool', tables.where((t) => t.type == TableType.americanPool).length, Colors.blue, context),
                ],
              ),
              const Gap(16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => const ResourceManagementScreen()));
                  },
                  icon: const Icon(Icons.settings_suggest),
                  label: const Text('Manage Games & Tables'),
                ),
              ),
              const Gap(8),
            ],
          ),


          // 6. Financial Settings
          SettingsSectionCard(
            title: 'Financial Settings',
            icon: Icons.currency_exchange,
            iconColor: AppColors.success,
            children: [
              ListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('System Currency'),
                subtitle: Text('${currency.symbol} - ${currency.name} (${currency.code})'),
                trailing: OutlinedButton(
                  onPressed: () => _showCurrencyPicker(context, ref, currency),
                  child: const Text('Change'),
                ),
              ),
            ],
          ),


          // 8. Theme Customization
          SettingsSectionCard(
            title: 'Theme Customization',
            icon: Icons.palette_outlined,
            iconColor: Colors.purpleAccent,
            children: [
              const Gap(4),
              Text('Select active appearance mode:', style: theme.textTheme.bodyMedium),
              const Gap(12),
              Row(
                children: [
                  Expanded(child: _buildThemeOption(ThemeMode.light, 'Light', Icons.light_mode, themeMode, ref)),
                  const Gap(8),
                  Expanded(child: _buildThemeOption(ThemeMode.dark, 'Dark', Icons.dark_mode, themeMode, ref)),
                  const Gap(8),
                  Expanded(child: _buildThemeOption(ThemeMode.system, 'System', Icons.settings_brightness, themeMode, ref)),
                ],
              ),
              const Gap(16),
              const Divider(),
              const Gap(8),
              ListTile(
                contentPadding: EdgeInsets.zero,
                leading: const Icon(Icons.language),
                title: const Text('Language / भाषा'),
                trailing: DropdownButton<Locale>(
                  value: ref.watch(localeProvider),
                  items: const [
                    DropdownMenuItem(value: Locale('en'), child: Text('English')),
                    DropdownMenuItem(value: Locale('hi'), child: Text('हिंदी')),
                  ],
                  onChanged: (locale) {
                    if (locale != null) {
                      ref.read(localeProvider.notifier).setLocale(locale);
                    }
                  },
                  underline: const SizedBox(),
                ),
              ),
            ],
          ),

          // 9. Notifications & Sound
          SettingsSectionCard(
            title: 'Notifications & Feedback',
            icon: Icons.notifications_active_outlined,
            iconColor: Colors.teal,
            children: [
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Low Stock Alerts'),
                subtitle: const Text('Notify operator immediately when inventory hits warning threshold'),
                value: settings.notifications.lowStockAlerts,
                onChanged: (val) => notifier.updateNotificationSettings(settings.notifications.copyWith(lowStockAlerts: val)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Daily Revenue Summary'),
                subtitle: const Text('Receive automatic closing reports and revenue summaries at end of day'),
                value: settings.notifications.dailyRevenueSummary,
                onChanged: (val) => notifier.updateNotificationSettings(settings.notifications.copyWith(dailyRevenueSummary: val)),
              ),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Backup Reminders'),
                subtitle: const Text('Periodic reminder prompts to verify offline local backups'),
                value: settings.notifications.backupReminders,
                onChanged: (val) => notifier.updateNotificationSettings(settings.notifications.copyWith(backupReminders: val)),
              ),
            ],
          ),


          // 11. App Diagnostics & Sync
          SettingsSectionCard(
            title: 'App Diagnostics & Sync',
            icon: Icons.cloud_sync,
            iconColor: AppColors.info,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Firebase Connection', style: theme.textTheme.bodyLarge),
                  Row(
                    children: [
                      Container(
                        width: 10,
                        height: 10,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: syncStatus == FirebaseSyncStatus.connected
                              ? AppColors.success
                              : (syncStatus == FirebaseSyncStatus.synchronizing ? AppColors.warning : AppColors.error),
                        ),
                      ),
                      const Gap(6),
                      Text(
                        syncStatus.displayName,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: syncStatus == FirebaseSyncStatus.connected
                              ? AppColors.success
                              : (syncStatus == FirebaseSyncStatus.synchronizing ? AppColors.warning : AppColors.error),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const Gap(12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Last Successful Sync', style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
                  Text(
                    settings.lastSyncTime == null
                        ? 'Not yet synced'
                        : DateFormat('MMM d, yyyy - HH:mm').format(settings.lastSyncTime!),
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),

          // 12. About Section & Logout
          SettingsSectionCard(
            title: 'About & System Information',
            icon: Icons.info_outline,
            iconColor: Colors.blueGrey,
            children: [
              _buildInfoTile('Application Name', '${settings.business.clubName} Management'),
              _buildInfoTile('Version & Build', packageInfo.when(
                data: (info) => 'v${info.version} (Build ${info.buildNumber})',
                loading: () => 'Loading...',
                error: (_, __) => 'Unknown',
              )),
              _buildInfoTile('Developer', 'Shuaib Ahmad'),
              const Gap(16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse('https://shuaibahmad.netlify.app/privacy-policy');
                        try {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open the privacy policy link.')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.privacy_tip_outlined, size: 18),
                      label: const Text('Privacy Policy'),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final url = Uri.parse('https://shuaibahmad.netlify.app/terms-of-service');
                        try {
                          await launchUrl(url, mode: LaunchMode.externalApplication);
                        } catch (e) {
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Could not open the terms of service link.')),
                            );
                          }
                        }
                      },
                      icon: const Icon(Icons.description_outlined, size: 18),
                      label: const Text('Terms of Service'),
                    ),
                  ),
                ],
              ),
              const Gap(24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: theme.colorScheme.errorContainer,
                    foregroundColor: theme.colorScheme.onErrorContainer,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () async {
                    final confirmed = await LogoutDialog.show(context);
                    if (confirmed == true && context.mounted) {
                      try {
                        await ref.read(authRepositoryProvider).signOut();
                      } catch (e) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('Logout failed: $e'), backgroundColor: theme.colorScheme.error),
                          );
                        }
                      }
                    }
                  },
                  icon: const Icon(Icons.logout),
                  label: Text('Sign Out of ${settings.business.clubName}', style: const TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
          const Gap(24),
        ],
      ),
    );
  }

  Widget _buildInfoTile(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
          const Gap(12),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildTableCountBadge(String label, int count, Color color, BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: [
          Text(count.toString(), style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: color)),
          const Gap(4),
          Text(label, style: Theme.of(context).textTheme.labelSmall?.copyWith(fontWeight: FontWeight.w600)),
        ],
      ),
    );
  }

  Widget _buildThemeOption(ThemeMode mode, String label, IconData icon, ThemeMode currentMode, WidgetRef ref) {
    final isSelected = mode == currentMode;
    return InkWell(
      onTap: () => ref.read(themeModeProvider.notifier).setThemeMode(mode),
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.grey.withValues(alpha: 0.3),
            width: isSelected ? 2 : 1,
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: isSelected ? AppColors.primary : Colors.grey),
            const Gap(6),
            Text(label, style: TextStyle(fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal)),
          ],
        ),
      ),
    );
  }


  void _showCurrencyPicker(BuildContext context, WidgetRef ref, Currency currentCurrency) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
                child: Text('Select Currency', style: Theme.of(context).textTheme.titleLarge),
              ),
              ...Currency.supportedCurrencies.map(
                (c) => ListTile(
                  leading: Text(c.symbol, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                  title: Text(c.name),
                  subtitle: Text(c.code),
                  trailing: c.code == currentCurrency.code ? const Icon(Icons.check, color: AppColors.success) : null,
                  onTap: () {
                    ref.read(currencyProvider.notifier).setCurrency(c);
                    Navigator.of(context).pop();
                  },
                ),
              ),
              const Gap(24),
            ],
          ),
        );
      },
    );
  }
}