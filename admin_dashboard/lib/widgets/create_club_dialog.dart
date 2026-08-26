import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:admin_dashboard/data/admin_repository.dart';

class CreateClubDialog extends ConsumerStatefulWidget {
  const CreateClubDialog({super.key});

  @override
  ConsumerState<CreateClubDialog> createState() => _CreateClubDialogState();
}

class _CreateClubDialogState extends ConsumerState<CreateClubDialog> {
  final _formKey = GlobalKey<FormState>();
  final _clubNameCtrl = TextEditingController();
  final _appNameCtrl = TextEditingController();
  final _ownerNameCtrl = TextEditingController();
  final _ownerEmailCtrl = TextEditingController();
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Onboard New Club'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextFormField(
                controller: _clubNameCtrl,
                decoration: const InputDecoration(labelText: 'Club Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _appNameCtrl,
                decoration: const InputDecoration(labelText: 'App Name (For UI)'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerNameCtrl,
                decoration: const InputDecoration(labelText: 'Owner Name'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _ownerEmailCtrl,
                decoration: const InputDecoration(labelText: 'Owner Email'),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _isLoading ? null : () async {
            if (_formKey.currentState!.validate()) {
              setState(() => _isLoading = true);
              try {
                await ref.read(adminRepositoryProvider).createClub(
                  clubName: _clubNameCtrl.text.trim(),
                  appName: _appNameCtrl.text.trim(),
                  ownerName: _ownerNameCtrl.text.trim(),
                  ownerEmail: _ownerEmailCtrl.text.trim(),
                );
                if (context.mounted) Navigator.of(context).pop();
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e')));
                }
              } finally {
                if (mounted) setState(() => _isLoading = false);
              }
            }
          },
          child: _isLoading ? const CircularProgressIndicator() : const Text('Create'),
        )
      ],
    );
  }
}
