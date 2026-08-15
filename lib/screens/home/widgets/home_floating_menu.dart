import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/shopping_provider.dart';
import '../../../utils/constants.dart';
import '../../../widgets/voice_input_sheet.dart';

class HomeFloatingMenu extends StatelessWidget {
  final bool hasSelection;
  final VoidCallback onMove;
  final VoidCallback onShare;
  final VoidCallback onDelete;

  const HomeFloatingMenu({
    super.key,
    required this.hasSelection,
    required this.onMove,
    required this.onShare,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final shopping = context.read<ShoppingProvider>();
    final auth = context.read<AuthProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width - 40,
        ),
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: cs.surface,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.15),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
              border: Border.all(
                color: cs.outlineVariant.withValues(alpha: 0.5),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Add by voice
                _FloatingMenuButton(
                  icon: Icons.mic_rounded,
                  label: 'Voice',
                  isCompact: hasSelection,
                  onPressed: () {
                    showModalBottomSheet<void>(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (_) => VoiceInputSheet(
                        onItemConfirmed: (name, category, quantity) async {
                          final user = auth.userProfile;
                          if (user == null) return;
                          await shopping.addItem(
                            name: name,
                            category: category,
                            addedBy: user.id,
                            addedByName: user.displayName,
                            quantity: quantity,
                            inputMethod: 'voice',
                          );
                        },
                      ),
                    );
                  },
                ),
                const SizedBox(width: 4),
                // Add item
                _FloatingMenuButton(
                  icon: Icons.add_rounded,
                  label: 'Add',
                  isPrimary: true,
                  isCompact: hasSelection,
                  onPressed: () => context.push(AppConstants.routeAddItem),
                ),
                // Move (shown when items selected)
                if (hasSelection) ...[
                  const SizedBox(width: 4),
                  _FloatingMenuButton(
                    icon: Icons.drive_file_move_rounded,
                    label: 'Move',
                    isCompact: true,
                    onPressed: onMove,
                  ),
                ],
                // Share (shown when items selected)
                if (hasSelection) ...[
                  const SizedBox(width: 4),
                  _FloatingMenuButton(
                    icon: Icons.share_rounded,
                    label: 'Share',
                    isCompact: true,
                    onPressed: onShare,
                  ),
                ],
                // Delete (shown when items selected)
                if (hasSelection) ...[
                  const SizedBox(width: 4),
                  _FloatingMenuButton(
                    icon: Icons.delete_outline_rounded,
                    label: 'Delete',
                    isDestructive: true,
                    isCompact: true,
                    onPressed: onDelete,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Floating Menu Button ──────────────────────────────────────────────────────

class _FloatingMenuButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final bool isPrimary;
  final bool isDestructive;
  final bool isCompact;

  const _FloatingMenuButton({
    required this.icon,
    required this.label,
    required this.onPressed,
    this.isPrimary = false,
    this.isDestructive = false,
    this.isCompact = false,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    Color backgroundColor;
    Color foregroundColor;

    if (isPrimary) {
      backgroundColor = cs.primaryContainer;
      foregroundColor = cs.onPrimaryContainer;
    } else if (isDestructive) {
      backgroundColor = Colors.red.shade50;
      foregroundColor = Colors.red.shade700;
    } else {
      backgroundColor = cs.surfaceContainerHighest.withValues(alpha: 0.6);
      foregroundColor = cs.onSurface;
    }

    final button = Material(
      color: backgroundColor,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isCompact ? 10 : 16,
            vertical: isCompact ? 8 : 10,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: isCompact ? 18 : 20, color: foregroundColor),
              if (!isCompact) ...[
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );

    // Show tooltip when in compact (icon-only) mode
    if (isCompact) {
      return Tooltip(
        message: label,
        child: button,
      );
    }

    return button;
  }
}
