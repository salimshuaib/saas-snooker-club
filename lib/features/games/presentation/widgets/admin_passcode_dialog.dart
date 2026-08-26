import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:gap/gap.dart';
import 'package:snooker_club/features/settings/providers/settings_providers.dart';

class AdminPasscodeDialog extends ConsumerStatefulWidget {
  final String title;
  final String subtitle;
  final String actionLabel;
  final bool isDestructive;

  const AdminPasscodeDialog({
    super.key,
    this.title = 'Admin Authorization',
    this.subtitle = 'Enter the administrator passcode to proceed.',
    this.actionLabel = 'Confirm',
    this.isDestructive = false,
  });

  static Future<bool> verify(
    BuildContext context, 
    WidgetRef ref, {
    String? title, 
    String? subtitle,
    String actionLabel = 'Confirm',
    bool isDestructive = false,
  }) async {
    final settings = ref.read(appSettingsProvider);
    if (!settings.security.requirePasscodeForDeletion) {
      return true;
    }
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AdminPasscodeDialog(
        title: title ?? 'Admin Authorization',
        subtitle: subtitle ?? 'Enter the administrator passcode to proceed.',
        actionLabel: actionLabel,
        isDestructive: isDestructive,
      ),
    );
    return result == true;
  }

  @override
  ConsumerState<AdminPasscodeDialog> createState() => _AdminPasscodeDialogState();
}

class _AdminPasscodeDialogState extends ConsumerState<AdminPasscodeDialog> {
  String _enteredPin = '';
  String? _errorMessage;

  void _onNumberTap(String number) {
    if (_enteredPin.length < 10) {
      setState(() {
        _enteredPin += number;
        _errorMessage = null;
      });
    }
  }

  void _onBackspace() {
    if (_enteredPin.isNotEmpty) {
      setState(() {
        _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
        _errorMessage = null;
      });
    }
  }

  void _onSubmit() {
    final configuredPasscode = ref.read(appSettingsProvider).security.adminPasscode;
    if (_enteredPin == configuredPasscode) {
      Navigator.of(context).pop(true);
    } else {
      setState(() {
        _errorMessage = 'Incorrect passcode. Access denied.';
        _enteredPin = '';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      elevation: 8,
      backgroundColor: theme.colorScheme.surface,
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 340),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.lock_outline_rounded, 
                size: 44, 
                color: widget.isDestructive ? theme.colorScheme.error : theme.colorScheme.primary,
              ),
              const Gap(12),
              Text(
                widget.title,
                style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
                textAlign: TextAlign.center,
              ),
              const Gap(8),
              Text(
                widget.subtitle,
                style: theme.textTheme.bodyMedium?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const Gap(20),
              // Masked password field display
              Container(
                height: 54,
                width: double.infinity,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: _errorMessage != null
                        ? theme.colorScheme.error
                        : theme.colorScheme.outlineVariant,
                  ),
                ),
                child: _enteredPin.isEmpty
                    ? Text(
                        '• • • • •',
                        style: TextStyle(
                          fontSize: 24,
                          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                          letterSpacing: 8,
                        ),
                      )
                    : Text(
                        '• ' * _enteredPin.length,
                        style: TextStyle(
                          fontSize: 24,
                          color: theme.colorScheme.onSurface,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 6,
                        ),
                      ),
              ),
              if (_errorMessage != null) ...[
                const Gap(8),
                Text(
                  _errorMessage!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                    fontWeight: FontWeight.w600,
                  ),
                  textAlign: TextAlign.center,
                ),
              ],
              const Gap(20),
              // Numeric Keypad
              _buildKeypad(theme),
              const Gap(24),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onPressed: () => Navigator.of(context).pop(false),
                      child: const Text('Cancel', style: TextStyle(fontWeight: FontWeight.w600)),
                    ),
                  ),
                  const Gap(12),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.isDestructive ? theme.colorScheme.error : theme.colorScheme.primary,
                        foregroundColor: widget.isDestructive ? theme.colorScheme.onError : theme.colorScheme.onPrimary,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 0,
                      ),
                      onPressed: _enteredPin.isEmpty ? null : _onSubmit,
                      child: Text(widget.actionLabel, style: const TextStyle(fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKeypad(ThemeData theme) {
    return Column(
      children: [
        _buildKeypadRow(['1', '2', '3'], theme),
        const Gap(10),
        _buildKeypadRow(['4', '5', '6'], theme),
        const Gap(10),
        _buildKeypadRow(['7', '8', '9'], theme),
        const Gap(10),
        Row(
          children: [
            const Expanded(child: SizedBox()),
            Expanded(child: _buildKeypadButton('0', theme)),
            Expanded(
              child: InkWell(
                onTap: _onBackspace,
                borderRadius: BorderRadius.circular(30),
                child: Container(
                  height: 48,
                  alignment: Alignment.center,
                  child: Icon(
                    Icons.backspace_outlined,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildKeypadRow(List<String> digits, ThemeData theme) {
    return Row(
      children: digits.map((d) => Expanded(child: _buildKeypadButton(d, theme))).toList(),
    );
  }

  Widget _buildKeypadButton(String digit, ThemeData theme) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6.0),
      child: InkWell(
        onTap: () => _onNumberTap(digit),
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 48,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
          ),
          child: Text(
            digit,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              fontSize: 20,
            ),
          ),
        ),
      ),
    );
  }
}
