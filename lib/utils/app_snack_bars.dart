import 'package:flutter/material.dart';

class AppSnackBars {
  AppSnackBars._();

  static const EdgeInsets _margin = EdgeInsets.fromLTRB(12, 0, 12, 100);
  static const Duration _duration = Duration(seconds: 2);
  static final ShapeBorder _shape =
      RoundedRectangleBorder(borderRadius: BorderRadius.circular(12));

  static SnackBar success(String message, {Widget? icon}) => SnackBar(
        content: _SnackRow(
          icon: icon ?? const Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
          message: message,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.green.shade600,
        duration: _duration, shape: _shape, margin: _margin,
      );

  static SnackBar error(String message, {Widget? icon}) => SnackBar(
        content: _SnackRow(
          icon: icon ?? const Icon(Icons.error_outline_rounded, color: Colors.white, size: 18),
          message: message,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.red.shade600,
        duration: _duration, shape: _shape, margin: _margin,
      );

  static SnackBar info(String message, {Color? color, Widget? icon}) => SnackBar(
        content: _SnackRow(
          icon: icon ?? const Icon(Icons.info_outline_rounded, color: Colors.white, size: 18),
          message: message,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color ?? Colors.blue.shade600,
        duration: _duration, shape: _shape, margin: _margin,
      );

  static SnackBar warning(String message, {Widget? icon}) => SnackBar(
        content: _SnackRow(
          icon: icon ?? const Icon(Icons.warning_amber_rounded, color: Colors.white, size: 18),
          message: message,
        ),
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.orange.shade700,
        duration: _duration, shape: _shape, margin: _margin,
      );
}

class _SnackRow extends StatelessWidget {
  final Widget icon;
  final String message;
  const _SnackRow({required this.icon, required this.message});

  @override
  Widget build(BuildContext context) => Row(children: [
        icon, const SizedBox(width: 8),
        Expanded(child: Text(message, overflow: TextOverflow.ellipsis)),
      ]);
}
