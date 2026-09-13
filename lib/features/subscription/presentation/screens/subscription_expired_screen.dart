import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:snooker_club/core/providers/subscription_provider.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/authentication/data/auth_repository.dart';

class SubscriptionExpiredScreen extends ConsumerWidget {
  const SubscriptionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final subscriptionState = ref.watch(subscriptionStateProvider);
    final theme = Theme.of(context);
    final price = subscriptionState.price;
    final upiId = subscriptionState.upiId;

    // Generate UPI URL: upi://pay?pa=<upi_id>&pn=Snooker%20Club&am=<amount>&cu=INR
    final upiUrl = 'upi://pay?pa=$upiId&pn=SaaS%20Snooker&am=$price&cu=INR';

    return Scaffold(
      backgroundColor: AppColors.darkBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const Gap(40),
                const Icon(
                  Icons.warning_amber_rounded,
                  size: 80,
                  color: Colors.redAccent,
                ),
                const Gap(24),
                Text(
                  'Subscription Expired',
                  style: theme.textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: AppColors.darkOnSurface,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(16),
                Text(
                  subscriptionState.suspensionMessage ??
                      'Your club subscription has expired. Please renew to continue using the application.',
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: AppColors.darkOnSurfaceVariant,
                  ),
                  textAlign: TextAlign.center,
                ),
                const Gap(32),

                // QR Code Section
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.darkSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.darkOutline.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      Text(
                        'Amount Due: ₹${price.toStringAsFixed(0)}/month',
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                      const Gap(24),
                      if (upiId != null && upiId.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: QrImageView(
                            data: upiUrl,
                            version: QrVersions.auto,
                            size: 200.0,
                            backgroundColor: Colors.white,
                          ),
                        )
                      else
                        const Icon(
                          Icons.qr_code_2,
                          size: 150,
                          color: Colors.grey,
                        ),

                      const Gap(16),
                      if (upiId != null)
                        Text(
                          'Scan to Pay (UPI: $upiId)',
                          style: theme.textTheme.bodyLarge?.copyWith(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                    ],
                  ),
                ),

                const Gap(32),
                const Text(
                  'After payment, please contact support to restore access:',
                  textAlign: TextAlign.center,
                ),
                const Gap(16),
                if (subscriptionState.supportPhone != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.phone, size: 20),
                      const Gap(8),
                      Text(subscriptionState.supportPhone!),
                    ],
                  ),
                const Gap(8),
                if (subscriptionState.supportEmail != null)
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.email, size: 20),
                      const Gap(8),
                      Text(subscriptionState.supportEmail!),
                    ],
                  ),
                const Gap(48),

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
      ),
    );
  }
}
