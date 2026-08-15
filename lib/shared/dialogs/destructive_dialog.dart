import 'package:flutter/material.dart';
import 'app_dialog.dart';

/// High-stakes destructive action dialogs with red warning styling.
/// Use for irreversible actions like deletions.
class DestructiveDialog {
  DestructiveDialog._();

  /// Shows a destructive action dialog with red styling.
  /// Returns true if confirmed, false if cancelled, null if dismissed.
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmText = 'Delete',
    String cancelText = 'Cancel',
  }) async {
    final cs = Theme.of(context).colorScheme;

    return showDialog<bool>(
      context: context,
      barrierDismissible: true,
      builder: (ctx) => AlertDialog(
        shape: AppDialog.shape,
        icon: const Icon(Icons.warning_rounded, color: Colors.red, size: 32),
        iconPadding: AppDialog.iconPadding,
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
            style: AppDialog.primaryButtonStyle(cs, isDestructive: true),
            onPressed: () => Navigator.pop(ctx, true),
            child: Text(confirmText),
          ),
        ],
      ),
    );
  }
}
