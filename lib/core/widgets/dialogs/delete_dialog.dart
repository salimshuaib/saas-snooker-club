import 'package:flutter/material.dart';
import 'package:snooker_club/core/widgets/dialogs/confirmation_dialog.dart';

/// Destructive action confirmation dialog.
class DeleteDialog {
  DeleteDialog._();

  static Future<bool?> show(
    BuildContext context, {
    String title = 'Delete',
    String message = 'Are you sure you want to delete this? This action cannot be undone.',
  }) {
    return ConfirmationDialog.show(
      context,
      title: title,
      message: message,
      confirmLabel: 'Delete',
      isDestructive: true,
    );
  }
}
