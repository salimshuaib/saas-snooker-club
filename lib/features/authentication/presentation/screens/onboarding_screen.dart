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
  int _snookerCount = 0;
  int _poolCount = 0;
  final _snookerRateCtrl = TextEditingController(text: "250");
  final _poolRateCtrl = TextEditingController(text: "200");
  bool _isLoading = false;

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

  @override
  void dispose() {
    _snookerRateCtrl.dispose();
    _poolRateCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('You must agree to the User Agreement to proceed.')),
      );
      return;
    }

    if (_snookerCount == 0 && _poolCount == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please add at least one table to continue.')),
      );
      return;
    }

    final snookerRate = double.tryParse(_snookerRateCtrl.text) ?? 250.0;
    final poolRate = double.tryParse(_poolRateCtrl.text) ?? 200.0;

    setState(() => _isLoading = true);

    try {
      final gamesRepo = ref.read(gamesRepositoryProvider);

      // Add Snooker Tables
      for (int i = 1; i <= _snookerCount; i++) {
        final table = TableModel(
          id: '',
          name: 'Snooker $i',
          type: TableType.snooker,
          hourlyRate: snookerRate,
          createdAt: DateTime.now(),
        );
        await gamesRepo.addTable(table);
      }

      // Add Pool Tables
      for (int i = 1; i <= _poolCount; i++) {
        final table = TableModel(
          id: '',
          name: 'Pool $i',
          type: TableType.pool,
          hourlyRate: poolRate,
          createdAt: DateTime.now(),
        );
        await gamesRepo.addTable(table);
      }

      // Complete Onboarding
      await ref.read(settingsRepositoryProvider).completeOnboarding();

      if (mounted) {
        context.go(RouteNames.dashboard);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
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
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
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
                title: const Text('I have read and agree to the User Agreement', style: TextStyle(fontWeight: FontWeight.bold)),
                value: _agreedToTerms,
                onChanged: (val) => setState(() => _agreedToTerms = val ?? false),
                controlAffinity: ListTileControlAffinity.leading,
                contentPadding: EdgeInsets.zero,
                activeColor: AppColors.primary,
              ),
              const Gap(32),
              Text(
                'Step 2: Table Setup',
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
              ),
              const Gap(8),
              Text(
                'Add your tables so you can start tracking time immediately.',
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const Gap(24),
              _buildTableConfigurator(
                title: 'Snooker Tables',
                count: _snookerCount,
                rateCtrl: _snookerRateCtrl,
                onAdd: () => setState(() => _snookerCount++),
                onRemove: () => setState(() {
                  if (_snookerCount > 0) _snookerCount--;
                }),
              ),
              const Gap(24),
              _buildTableConfigurator(
                title: 'Pool Tables',
                count: _poolCount,
                rateCtrl: _poolRateCtrl,
                onAdd: () => setState(() => _poolCount++),
                onRemove: () => setState(() {
                  if (_poolCount > 0) _poolCount--;
                }),
              ),
              const Gap(48),
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
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Complete Setup & Go to Dashboard', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              const Gap(24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildTableConfigurator({
    required String title,
    required int count,
    required TextEditingController rateCtrl,
    required VoidCallback onAdd,
    required VoidCallback onRemove,
  }) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: theme.colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
              ),
              Row(
                children: [
                  IconButton(
                    onPressed: onRemove,
                    icon: const Icon(Icons.remove_circle_outline),
                    color: AppColors.error,
                  ),
                  Text(
                    '$count',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  IconButton(
                    onPressed: onAdd,
                    icon: const Icon(Icons.add_circle_outline),
                    color: AppColors.success,
                  ),
                ],
              ),
            ],
          ),
          if (count > 0) ...[
            const Gap(16),
            TextFormField(
              controller: rateCtrl,
              decoration: InputDecoration(
                labelText: 'Default Hourly Rate (₹)',
                prefixIcon: const Icon(Icons.currency_rupee, size: 16),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                isDense: true,
              ),
              keyboardType: TextInputType.number,
            ),
          ],
        ],
      ),
    );
  }
}
