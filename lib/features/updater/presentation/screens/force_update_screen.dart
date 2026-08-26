import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/providers/update_provider.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/core/widgets/buttons/app_primary_button.dart';
import 'package:url_launcher/url_launcher.dart';

class ForceUpdateScreen extends ConsumerWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final updateState = ref.watch(updateStateProvider);
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.system_update_rounded,
                size: 80,
                color: AppColors.primary,
              ),
              const Gap(24),
              Text(
                'Update Required',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkOnSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(16),
              Text(
                updateState.updateMessage.isNotEmpty
                    ? updateState.updateMessage
                    : 'A new critical version of Sharma Billiards is available. Please update to continue using the app.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.darkOnSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(48),
              AppPrimaryButton(
                label: 'Update Now',
                icon: Icons.download_rounded,
                onPressed: () async {
                  final url = Uri.parse(updateState.updateUrl);
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Could not launch update URL. Please check your connection.')),
                      );
                    }
                  }
                },
              ),
              const Gap(16),
              Text(
                'Current Version: ${updateState.currentVersion}\nLatest Version: ${updateState.latestVersion}',
                style: theme.textTheme.bodySmall?.copyWith(
                  color: AppColors.darkOutline,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
