import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:go_router/go_router.dart';
import 'package:snooker_club/core/routes/route_names.dart';
import 'package:snooker_club/features/games/domain/models/game_models.dart';
import 'package:snooker_club/features/games/providers/games_providers.dart';
import 'package:snooker_club/features/settings/data/settings_repository.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:snooker_club/core/theme/app_colors.dart';

class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  bool _agreedToTerms = false;
  bool _isLoading = false;

  final Map<TableType, int> _counts = {
    for (var type in TableType.values) type: 0,
  };

  final String _userAgreementText = '''
# SaaS Snooker Club Management - User Agreement (v1.0)

Welcome to the Snooker & Billiards Club Management Platform. By registering your club, logging in, or using our software, you agree to be bound by the following terms and conditions.

1. Service Overview
Our platform provides digital tools for club management, including table time-tracking, automated billing calculation, inventory management, and customer credit tracking.

2. Data Ownership and Responsibilities
- Your Data: You retain full ownership of all data entered into the system regarding your club, inventory, and customers.
- Customer Privacy: You act as the data controller for your customers. You are solely responsible for obtaining any necessary consent from your players to store their information (such as names, phone numbers, and financial credit histories) within our system in compliance with local privacy laws.
- Account Security: You are responsible for maintaining the confidentiality of your Super Admin and staff credentials. You are liable for any actions taken under your club's account.

3. Financial Calculations and Liability
- Accuracy Disclaimer: The software is provided "as is". While we strive for absolute accuracy in our time-tracking algorithms and billing calculations, it is ultimately your responsibility to verify final bills before charging customers.
- Limitation of Liability: The platform developers and administrators shall not be held liable for any financial losses, accounting discrepancies, lost revenue due to offline periods, or network failures.
- Customer Credit: The customer credit and transaction history features act purely as a digital ledger for your convenience. We do not process payments directly or handle real-world debt collection.

4. Acceptable Use
- You agree not to use the software to facilitate any illegal activities or unauthorized gambling operations that violate your local jurisdictions.
- No Credential Sharing or Reselling: Your subscription is strictly for your specific club. You agree not to share your account credentials, resell access to the app, or allow unauthorized third parties or other physical clubs to use your account.
- You agree not to reverse engineer, disrupt, or attempt to bypass the security and multi-tenant architecture of the platform.

5. Subscription, Suspension, and Termination
- Access to the platform is granted on a SaaS (Software as a Service) subscription basis.
- The platform administrators reserve the right to suspend or terminate your club's access at any time if you violate these terms, misuse the system, or fail to pay subscription fees. Upon termination, you may request an export of your club's data.

By checking "I Agree" and proceeding, you acknowledge that you have read, understood, and agree to these terms.
''';

  Future<void> _submit() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('You must agree to the User Agreement to proceed.'),
        ),
      );
      return;
    }

    final totalCount = _counts.values.fold(0, (sum, count) => sum + count);
    if (totalCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please add at least one table or game to continue.'),
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);

      for (final entry in _counts.entries) {
        final type = entry.key;
        final count = entry.value;

        for (int i = 1; i <= count; i++) {
          final table = TableModel(
            id: '',
            name: '${type.displayName} $i',
            type: type,
          );
          await gamesRepo.addTable(table);
        }
      }

      // Complete Onboarding
      final settingsRepo = ref.read(settingsRepositoryProvider);
      await settingsRepo.completeOnboarding();

      if (mounted) {
        context.go(RouteNames.dashboard);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: $e')));
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Welcome! Setup Your Club'),
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                'Step 1: User Agreement',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(16),
              Container(
                height: 250,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(color: theme.colorScheme.outlineVariant),
                  borderRadius: BorderRadius.circular(8),
                  color: theme.colorScheme.surface,
                ),
                child: SingleChildScrollView(
                  child: Text(
                    _userAgreementText,
                    style: theme.textTheme.bodyMedium,
                  ),
                ),
              ),
              const Gap(8),
              CheckboxListTile(
                title: const Text(
                  'I have read and agree to the User Agreement',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                value: _agreedToTerms,
                onChanged: (val) =>
                    setState(() => _agreedToTerms = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
              ),
              const Gap(32),
              Text(
                'Step 2: Table Setup',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const Gap(8),
              Text(
                'Add your tables so you can start tracking time immediately.',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
              const Gap(16),
              DefaultTabController(
                length: 2,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TabBar(
                      labelColor: AppColors.primary,
                      unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
                      indicatorColor: AppColors.primary,
                      tabs: const [
                        Tab(text: 'Billiards'),
                        Tab(text: 'Other Games'),
                      ],
                    ),
                    const Gap(16),
                    SizedBox(
                      height: 450,
                      child: TabBarView(
                        children: [
                          _buildTabContent([
                            TableType.snooker,
                            TableType.indianPool,
                            TableType.americanPool,
                          ]),
                          _buildTabContent(
                            TableType.values
                                .where((t) => t.isOtherGame)
                                .toList(),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const Gap(16),
              ElevatedButton(
                onPressed: _isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                child: _isLoading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text(
                        'Complete Setup & Go to Dashboard',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
              ),
              const Gap(24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTabContent(List<TableType> types) {
    return ListView.separated(
      itemCount: types.length,
      separatorBuilder: (_, __) => const Gap(12),
      itemBuilder: (context, index) {
        final type = types[index];
        return _buildTableConfigurator(type);
      },
    );
  }

  Widget _buildTableConfigurator(TableType type) {
    final theme = Theme.of(context);
    final count = _counts[type] ?? 0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            type.displayName,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          Row(
            children: [
              IconButton(
                onPressed: () {
                  if (count > 0) {
                    setState(() => _counts[type] = count - 1);
                  }
                },
                icon: const Icon(Icons.remove_circle_outline),
                color: AppColors.error,
              ),
              Text(
                '$count',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              IconButton(
                onPressed: () {
                  setState(() => _counts[type] = count + 1);
                },
                icon: const Icon(Icons.add_circle_outline),
                color: AppColors.success,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
