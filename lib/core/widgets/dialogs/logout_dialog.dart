import 'package:flutter/material.dart';
import 'package:snooker_club/core/widgets/dialogs/confirmation_dialog.dart';

/// Logout confirmation dialog.
class LogoutDialog {
  LogoutDialog._();

  static Future<bool?> show(BuildContext context) {
    return ConfirmationDialog.show(
      context,
      title: 'Logout',
      message: 'Are you sure you want to logout?',
      confirmLabel: 'Logout',
      isDestructive: true,
    );
  }
}
