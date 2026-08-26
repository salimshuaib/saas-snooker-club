import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/features/settings/domain/models/settings_models.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';

class PricingEditSheet extends ConsumerStatefulWidget {
  final PricingSettings initialSettings;

  const PricingEditSheet({super.key, required this.initialSettings});

  @override
  ConsumerState<PricingEditSheet> createState() => _PricingEditSheetState();
}

class _PricingEditSheetState extends ConsumerState<PricingEditSheet> {
  final _formKey = GlobalKey<FormState>();

  // Snooker
  late final TextEditingController _snookerMinController;
  late final TextEditingController _snooker30mController;
  late final TextEditingController _snooker1hController;
  late final TextEditingController _snookerRaceMinController;
  late final TextEditingController _snookerRummyMinController;

  // Indian Pool
  late final TextEditingController _indianFrameController;
  late final TextEditingController _indianMinController;
  late final TextEditingController _indian30mController;
  late final TextEditingController _indian1hController;
  late final TextEditingController _indianRaceMinController;

  // American Pool
  late final TextEditingController _americanFrameController;
  late final TextEditingController _americanMinController;
  late final TextEditingController _american30mController;
  late final TextEditingController _american1hController;
  late final TextEditingController _americanRaceMinController;

  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    final p = widget.initialSettings;
    _snookerMinController = TextEditingController(text: p.snookerPerMinute.toStringAsFixed(2));
    _snooker30mController = TextEditingController(text: p.snookerHalfHour.toStringAsFixed(2));
    _snooker1hController = TextEditingController(text: p.snookerOneHour.toStringAsFixed(2));
    _snookerRaceMinController = TextEditingController(text: p.snookerRacePerMinute.toStringAsFixed(2));
    _snookerRummyMinController = TextEditingController(text: p.snookerRummyPerMinute.toStringAsFixed(2));

    _indianFrameController = TextEditingController(text: p.indianPoolPerFrame.toStringAsFixed(2));
    _indianMinController = TextEditingController(text: p.indianPoolPerMinute.toStringAsFixed(2));
    _indian30mController = TextEditingController(text: p.indianPoolHalfHour.toStringAsFixed(2));
    _indian1hController = TextEditingController(text: p.indianPoolOneHour.toStringAsFixed(2));
    _indianRaceMinController = TextEditingController(text: p.indianPoolRacePerMinute.toStringAsFixed(2));

    _americanFrameController = TextEditingController(text: p.americanPoolPerFrame.toStringAsFixed(2));
    _americanMinController = TextEditingController(text: p.americanPoolPerMinute.toStringAsFixed(2));
    _american30mController = TextEditingController(text: p.americanPoolHalfHour.toStringAsFixed(2));
    _american1hController = TextEditingController(text: p.americanPoolOneHour.toStringAsFixed(2));
    _americanRaceMinController = TextEditingController(text: p.americanPoolRacePerMinute.toStringAsFixed(2));
  }

  @override
  void dispose() {
    _snookerMinController.dispose();
    _snooker30mController.dispose();
    _snooker1hController.dispose();
    _snookerRaceMinController.dispose();
    _snookerRummyMinController.dispose();

    _indianFrameController.dispose();
    _indianMinController.dispose();
    _indian30mController.dispose();
    _indian1hController.dispose();
    _indianRaceMinController.dispose();

    _americanFrameController.dispose();
    _americanMinController.dispose();
    _american30mController.dispose();
    _american1hController.dispose();
    _americanRaceMinController.dispose();
    super.dispose();
  }

  String? _validatePrice(String? value) {
    if (value == null || value.trim().isEmpty) return 'Required';
    final parsed = double.tryParse(value.trim());
    if (parsed == null || parsed < 0) return 'Invalid amount';
    return null;
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final updated = PricingSettings(
        snookerPerMinute: double.parse(_snookerMinController.text.trim()),
        snookerHalfHour: double.parse(_snooker30mController.text.trim()),
        snookerOneHour: double.parse(_snooker1hController.text.trim()),
        snookerRacePerMinute: double.parse(_snookerRaceMinController.text.trim()),
        snookerRummyPerMinute: double.parse(_snookerRummyMinController.text.trim()),
        indianPoolPerFrame: double.parse(_indianFrameController.text.trim()),
        indianPoolPerMinute: double.parse(_indianMinController.text.trim()),
        indianPoolHalfHour: double.parse(_indian30mController.text.trim()),
        indianPoolOneHour: double.parse(_indian1hController.text.trim()),
        indianPoolRacePerMinute: double.parse(_indianRaceMinController.text.trim()),
        americanPoolPerFrame: double.parse(_americanFrameController.text.trim()),
        americanPoolPerMinute: double.parse(_americanMinController.text.trim()),
        americanPoolHalfHour: double.parse(_american30mController.text.trim()),
        americanPoolOneHour: double.parse(_american1hController.text.trim()),
        americanPoolRacePerMinute: double.parse(_americanRaceMinController.text.trim()),
      );

      await ref.read(appSettingsProvider.notifier).updatePricingSettings(updated);
      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Table pricing updated successfully.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving pricing: $e'),
            backgroundColor: Theme.of(context).colorScheme.error,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.85),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Configure Table Pricing',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () => Navigator.of(context).pop(),
                ),
              ],
            ),
            const Gap(12),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionHeader('Snooker Tables', Icons.circle, Colors.red),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Per Minute', _snookerMinController)),
                        const Gap(12),
                        Expanded(child: _buildTextField('Half Hour (30m)', _snooker30mController)),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('One Hour (1h)', _snooker1hController)),
                        const Gap(12),
                        Expanded(child: _buildTextField('Race / min', _snookerRaceMinController)),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Rummy / min', _snookerRummyMinController)),
                        const Gap(12),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                    const Gap(24),
                    _buildSectionHeader('Indian Pool Tables', Icons.lens, Colors.amber),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Per Frame', _indianFrameController)),
                        const Gap(12),
                        Expanded(child: _buildTextField('Overtime/min', _indianMinController)),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Half Hour (30m)', _indian30mController)),
                        const Gap(12),
                        Expanded(child: _buildTextField('One Hour (1h)', _indian1hController)),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Race / min', _indianRaceMinController)),
                        const Gap(12),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                    const Gap(24),
                    _buildSectionHeader('American Pool Tables', Icons.album, Colors.blue),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Per Frame', _americanFrameController)),
                        const Gap(12),
                        Expanded(child: _buildTextField('Per Minute', _americanMinController)),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Half Hour (30m)', _american30mController)),
                        const Gap(12),
                        Expanded(child: _buildTextField('One Hour (1h)', _american1hController)),
                      ],
                    ),
                    const Gap(12),
                    Row(
                      children: [
                        Expanded(child: _buildTextField('Race / min', _americanRaceMinController)),
                        const Gap(12),
                        const Expanded(child: SizedBox()),
                      ],
                    ),
                    const Gap(24),
                  ],
                ),
              ),
            ),
            const Gap(16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: theme.colorScheme.onPrimary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                onPressed: _isSaving ? null : _onSave,
                child: _isSaving
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Save Pricing Rates', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, Color color) {
    return Row(
      children: [
        Icon(icon, color: color, size: 18),
        const Gap(8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
      ),
      validator: _validatePrice,
    );
  }
}
