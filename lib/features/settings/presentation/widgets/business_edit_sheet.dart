import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/features/settings/domain/models/settings_models.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';
import 'package:snooker_club/core/providers/club_scope_provider.dart';

class BusinessEditSheet extends ConsumerStatefulWidget {
  final BusinessSettings initialSettings;

  const BusinessEditSheet({super.key, required this.initialSettings});

  @override
  ConsumerState<BusinessEditSheet> createState() => _BusinessEditSheetState();
}

class _BusinessEditSheetState extends ConsumerState<BusinessEditSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nameController;
  late final TextEditingController _phoneController;
  late final TextEditingController _addressController;
  late final TextEditingController _slugController;
  late final TextEditingController _upiIdController;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.initialSettings.clubName,
    );
    _phoneController = TextEditingController(
      text: widget.initialSettings.contactNumber,
    );
    _addressController = TextEditingController(
      text: widget.initialSettings.address,
    );
    _slugController = TextEditingController(
      text: widget.initialSettings.slug ?? '',
    );
    _upiIdController = TextEditingController(
      text: widget.initialSettings.upiId ?? '',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _slugController.dispose();
    _upiIdController.dispose();
    super.dispose();
  }

  Future<void> _onSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final slugValue = _slugController.text.trim().toLowerCase().replaceAll(
        RegExp(r'[^a-z0-9\-]'),
        '',
      );

      final updated = widget.initialSettings.copyWith(
        clubName: _nameController.text.trim(),
        contactNumber: _phoneController.text.trim(),
        address: _addressController.text.trim(),
        slug: slugValue.isEmpty ? null : slugValue,
        upiId: _upiIdController.text.trim().isEmpty ? null : _upiIdController.text.trim(),
      );

      await ref
          .read(appSettingsProvider.notifier)
          .updateBusinessSettings(updated);

      // Update root club document with slug and clubName so the website can find it
      final clubId = ref.read(clubIdProvider);
      if (clubId != null) {
        await FirebaseFirestore.instance.collection('clubs').doc(clubId).set({
          'slug': slugValue.isEmpty ? null : slugValue,
          'clubName': _nameController.text.trim(),
        }, SetOptions(merge: true));
      }

      if (mounted) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Business information saved successfully.'),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error saving settings: ' + e.toString()),
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

    return Padding(
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 20,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Edit Business Information',
                    style: theme.textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const Gap(16),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Club Name *',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.business),
                ),
                validator: (val) => val == null || val.trim().isEmpty
                    ? 'Club Name is required'
                    : null,
              ),
              const Gap(16),
              TextFormField(
                controller: _slugController,
                decoration: const InputDecoration(
                  labelText: 'Booking Link URL / Slug',
                  hintText: 'e.g., my-club',
                  helperText: 'Your link will be: .../?club=my-club',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.link),
                ),
              ),
              const Gap(16),
              TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Contact Number',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.phone),
                ),
              ),
              const Gap(16),
              TextFormField(
                controller: _upiIdController,
                decoration: const InputDecoration(
                  labelText: 'UPI ID (For Payments)',
                  hintText: 'e.g., myclub@ybl',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.qr_code_scanner),
                ),
              ),
              const Gap(16),
              TextFormField(
                controller: _addressController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Address / Location',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.location_on),
                ),
              ),
              const Gap(24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: theme.colorScheme.primary,
                    foregroundColor: theme.colorScheme.onPrimary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  onPressed: _isSaving ? null : _onSave,
                  child: _isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Text(
                          'Save Changes',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 16,
                          ),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
