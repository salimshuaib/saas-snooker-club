import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/core/theme/app_colors.dart';
import 'package:snooker_club/features/team/domain/models/staff_member.dart';
import 'package:snooker_club/features/team/providers/team_providers.dart';

class StaffFormDialog extends ConsumerStatefulWidget {
  final StaffMember? existingMember;

  const StaffFormDialog({super.key, this.existingMember});

  @override
  ConsumerState<StaffFormDialog> createState() => _StaffFormDialogState();
}

class _StaffFormDialogState extends ConsumerState<StaffFormDialog> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _passwordController;
  StaffRole _role = StaffRole.staff;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.existingMember?.name ?? '');
    _emailController = TextEditingController(text: widget.existingMember?.email ?? '');
    _passwordController = TextEditingController();
    _role = widget.existingMember?.role ?? StaffRole.staff;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isProcessing = true);

    try {
      final repo = ref.read(teamRepositoryProvider);
      
      if (widget.existingMember == null) {
        // Create new
        await repo.addStaffMember(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          role: _role,
        );
      } else {
        // Update existing
        final updated = widget.existingMember!.copyWith(
          name: _nameController.text,
          role: _role,
          updatedAt: DateTime.now(),
        );
        await repo.updateStaffMember(updated);
      }
      
      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: AppColors.error),
        );
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isEditing = widget.existingMember != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Team Member' : 'Add Team Member',
                style: theme.textTheme.titleLarge,
              ),
              const Gap(24),
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Name',
                  border: OutlineInputBorder(),
                ),
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              const Gap(16),
              TextFormField(
                controller: _emailController,
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                enabled: !isEditing, // Do not allow changing email for existing accounts
                validator: (val) => val == null || val.isEmpty ? 'Required' : null,
              ),
              if (!isEditing) ...[
                const Gap(16),
                TextFormField(
                  controller: _passwordController,
                  decoration: const InputDecoration(
                    labelText: 'Password',
                    border: OutlineInputBorder(),
                  ),
                  obscureText: true,
                  validator: (val) => val == null || val.length < 6 ? 'Min 6 characters' : null,
                ),
              ],
              const Gap(16),
              DropdownButtonFormField<StaffRole>(
                initialValue: _role,
                decoration: const InputDecoration(
                  labelText: 'Role',
                  border: OutlineInputBorder(),
                ),
                items: StaffRole.values.map((r) {
                  return DropdownMenuItem(
                    value: r,
                    child: Text(r.name.toUpperCase()),
                  );
                }).toList(),
                onChanged: (val) {
                  if (val != null) setState(() => _role = val);
                },
              ),
              const Gap(32),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: _isProcessing ? null : _submit,
                  child: _isProcessing
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : Text(isEditing ? 'Save Changes' : 'Create Account'),
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
