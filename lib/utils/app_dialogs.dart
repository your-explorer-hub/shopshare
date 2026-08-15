import 'package:flutter/material.dart';
import '../providers/auth_provider.dart';
import '../shared/dialogs/destructive_dialog.dart';

// Re-export dialog classes for convenience
export '../shared/dialogs/confirmation_dialog.dart';
export '../shared/dialogs/destructive_dialog.dart';

class AppDialogs {
  AppDialogs._();

  static Future<void> confirmSignOut(
      BuildContext context, AuthProvider auth) async {
    final confirmed = await DestructiveDialog.show(
      context: context,
      title: 'Sign Out?',
      message: 'You will be signed out of your account.',
      confirmText: 'Sign Out',
    );

    if (confirmed == true && context.mounted) {
      await auth.signOut();
    }
  }
}