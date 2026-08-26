import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/authentication/data/auth_repository.dart';

class NoClubScreen extends ConsumerWidget {
  const NoClubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final platformConfig = ref.watch(platformConfigProvider).value;
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
                Icons.domain_disabled_rounded,
                size: 80,
                color: Colors.orange,
              ),
              const Gap(24),
              Text(
                'No Club Assigned',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: AppColors.darkOnSurface,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(16),
              Text(
                'Your account has not been assigned to any club yet. Please contact the platform administrator to set up your account.',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: AppColors.darkOnSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
              const Gap(48),
              if (platformConfig?.supportPhone != null || platformConfig?.supportEmail != null) ...[
                const Text(
                  'Contact Support:',
                  textAlign: TextAlign.center,
                ),
                const Gap(16),
                if (platformConfig?.supportPhone != null)
                  Text('📞 ${platformConfig!.supportPhone}'),
                const Gap(8),
                if (platformConfig?.supportEmail != null)
                  Text('📧 ${platformConfig!.supportEmail}'),
                const Gap(48),
              ],
              TextButton.icon(
                onPressed: () async {
                  await AuthRepository().signOut();
                },
                icon: const Icon(Icons.logout),
                label: const Text('Sign Out'),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
