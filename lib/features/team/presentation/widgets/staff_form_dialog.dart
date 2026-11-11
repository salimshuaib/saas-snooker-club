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
  StaffAccessLevel _accessLevel = StaffAccessLevel.full;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(
      text: widget.existingMember?.name ?? '',
    );
    _emailController = TextEditingController(
      text: widget.existingMember?.email ?? '',
    );
    _passwordController = TextEditingController();
    _role = widget.existingMember?.role ?? StaffRole.staff;
    _accessLevel = widget.existingMember?.accessLevel ?? StaffAccessLevel.full;
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
      final effectiveAccess = _role == StaffRole.owner ? StaffAccessLevel.full : _accessLevel;

      if (widget.existingMember == null) {
        // Create new
        await repo.addStaffMember(
          name: _nameController.text,
          email: _emailController.text,
          password: _passwordController.text,
          role: _role,
          accessLevel: effectiveAccess,
        );
      } else {
        // Update existing
        final updated = widget.existingMember!.copyWith(
          name: _nameController.text,
          role: _role,
          accessLevel: effectiveAccess,
          updatedAt: DateTime.now(),
        );
        await repo.updateStaffMember(updated);
      }

      if (mounted) Navigator.of(context).pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: AppColors.error,
          ),
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
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 480),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isEditing ? 'Edit Team Member' : 'Add Team Member',
                  style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Gap(24),
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Name',
                    border: OutlineInputBorder(),
                  ),
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
                ),
                const Gap(16),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                  ),
                  enabled:
                      !isEditing, // Do not allow changing email for existing accounts
                  validator: (val) =>
                      val == null || val.isEmpty ? 'Required' : null,
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
                    validator: (val) =>
                        val == null || val.length < 6 ? 'Min 6 characters' : null,
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
                    if (val != null) {
                      setState(() {
                        _role = val;
                        if (val == StaffRole.owner) {
                          _accessLevel = StaffAccessLevel.full;
                        }
                      });
                    }
                  },
                ),
                const Gap(20),

                // Access Level Option (Full Access vs Limited Access)
                if (_role == StaffRole.owner) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.shield_outlined, color: theme.colorScheme.primary, size: 20),
                        const Gap(10),
                        Expanded(
                          child: Text(
                            'Owner role always has Full Access to all business financials and reports.',
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ] else ...[
                  Text(
                    'Access Level',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Gap(8),
                  // Full Access Option
                  InkWell(
                    onTap: () => setState(() => _accessLevel = StaffAccessLevel.full),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _accessLevel == StaffAccessLevel.full
                            ? theme.colorScheme.primary.withValues(alpha: 0.1)
                            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _accessLevel == StaffAccessLevel.full
                              ? theme.colorScheme.primary
                              : theme.colorScheme.outlineVariant,
                          width: _accessLevel == StaffAccessLevel.full ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Radio<StaffAccessLevel>(
                            value: StaffAccessLevel.full,
                            groupValue: _accessLevel,
                            onChanged: (val) {
                              if (val != null) setState(() => _accessLevel = val);
                            },
                          ),
                          const Gap(8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Full Access',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _accessLevel == StaffAccessLevel.full
                                            ? theme.colorScheme.primary
                                            : null,
                                      ),
                                    ),
                                    const Gap(8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.green.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Recommended',
                                        style: TextStyle(
                                          color: Colors.green,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(4),
                                Text(
                                  'Complete access to overview revenue metrics, financial calculations, and report downloads.',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const Gap(10),
                  // Limited Access Option
                  InkWell(
                    onTap: () => setState(() => _accessLevel = StaffAccessLevel.limited),
                    borderRadius: BorderRadius.circular(12),
                    child: Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: _accessLevel == StaffAccessLevel.limited
                            ? AppColors.warning.withValues(alpha: 0.1)
                            : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: _accessLevel == StaffAccessLevel.limited
                              ? AppColors.warning
                              : theme.colorScheme.outlineVariant,
                          width: _accessLevel == StaffAccessLevel.limited ? 2 : 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Radio<StaffAccessLevel>(
                            value: StaffAccessLevel.limited,
                            groupValue: _accessLevel,
                            activeColor: AppColors.warning,
                            onChanged: (val) {
                              if (val != null) setState(() => _accessLevel = val);
                            },
                          ),
                          const Gap(8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                      'Limited Access',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: _accessLevel == StaffAccessLevel.limited
                                            ? AppColors.warning
                                            : null,
                                      ),
                                    ),
                                    const Gap(8),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: AppColors.warning.withValues(alpha: 0.15),
                                        borderRadius: BorderRadius.circular(6),
                                      ),
                                      child: const Text(
                                        'Restricted',
                                        style: TextStyle(
                                          color: AppColors.warning,
                                          fontSize: 10,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const Gap(4),
                                Text(
                                  'Operational only (start/end games, clear credit, attendance, game history). Overview financials & reports will show "Not Authorized".',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const Gap(28),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: _isProcessing ? null : _submit,
                    child: _isProcessing
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(isEditing ? 'Save Changes' : 'Create Account'),
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
