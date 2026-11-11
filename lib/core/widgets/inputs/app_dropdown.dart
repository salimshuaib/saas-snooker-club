import 'package:flutter/material.dart';

/// Styled dropdown selector.
class AppDropdown<T> extends StatelessWidget {
  final String? label;
  final String? hint;
  final T? value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const AppDropdown({
    super.key,
    this.label,
    this.hint,
    this.value,
    required this.items,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null)
          Padding(
            padding: const EdgeInsets.only(bottom: 8, left: 4),
            child: Text(
              label!,
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        DropdownButtonFormField<T>(
          key: ValueKey(value),
          initialValue: value,
          hint: hint != null ? Text(hint!) : null,
          items: items,
          onChanged: onChanged,
          decoration: const InputDecoration(),
          borderRadius: BorderRadius.circular(12),
          dropdownColor: theme.colorScheme.surface,
        ),
      ],
    );
  }
}
