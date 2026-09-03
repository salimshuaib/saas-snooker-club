import 'package:flutter/material.dart';
import 'package:snooker_club/features/dashboard/presentation/widgets/financial_summary_card.dart';

class FinancialOverviewScreen extends StatelessWidget {
  const FinancialOverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Financial Overview'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: const [
            FinancialSummaryCard(),
          ],
        ),
      ),
    );
  }
}
