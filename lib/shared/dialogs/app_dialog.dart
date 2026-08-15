import 'package:flutter/material.dart';

/// Base styling constants and utilities for all app dialogs.
/// Ensures consistent design across confirmation, destructive, form, and list dialogs.
class AppDialog {
  AppDialog._();

  // ── Shape & Styling Constants ─────────────────────────────────────────────
  static const borderRadius = BorderRadius.all(Radius.circular(16));
  static const iconPadding = EdgeInsets.only(top: 20);
  static const contentPadding = EdgeInsets.symmetric(horizontal: 20, vertical: 16);
  static const actionButtonSize = Size(110, 40);
  static const actionButtonRadius = 10.0;

  static ShapeBorder get shape =>
      RoundedRectangleBorder(borderRadius: borderRadius);

  // ── Button Styles ──────────────────────────────────────────────────────────

  /// Primary action button style (FilledButton).
  /// Set [isDestructive] to true for red destructive actions.
  static ButtonStyle primaryButtonStyle(ColorScheme cs,
      {bool isDestructive = false}) {
    return FilledButton.styleFrom(
      backgroundColor: isDestructive ? Colors.red.shade600 : cs.primary,
      minimumSize: actionButtonSize,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(actionButtonRadius),
      ),
    );
  }

  /// Secondary action button style (OutlinedButton).
  static ButtonStyle secondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      minimumSize: actionButtonSize,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(actionButtonRadius),
      ),
    );
  }
}
