import 'package:flutter/material.dart';
import 'app_dialog.dart';

/// Simple Yes/No confirmation dialogs.
/// Use for non-destructive actions that need user confirmation.
class ConfirmationDialog {
  ConfirmationDialog._();

  /// Shows a confirmation dialog and returns true if confirmed, false if cancelled, null if dismissed.
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Confirm',
    String cancelText = 'Cancel',
    IconData? icon,
    Color? iconColor,
  }) async {
    final cs = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: AppDialog.shape,
        icon: icon != null
            ? Icon(icon, color: iconColor ?? cs.primary, size: 32)
            : null,
        iconPadding: icon != null ? AppDialog.iconPadding : null,
        title: Text(
          title,
          style: const TextStyle(fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        content: Text(
          message,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          OutlinedButton(
            style: AppDialog.secondaryButtonStyle(),
            onPressed: () => Navigator.pop(ctx, false),
            child: Text(cancelText),
          ),
          FilledButton(
            style: AppDialog.primaryButtonStyle(cs),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
