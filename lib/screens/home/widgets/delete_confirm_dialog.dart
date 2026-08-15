import 'package:flutter/material.dart';

import '../../../providers/shopping_provider.dart';

class DeleteConfirmDialog {
  // ── Delete all completed items ────────────────────────────────────────────

  static Future<void> showDeleteCompleted({
    required BuildContext context,
    required ShoppingProvider shopping,
  }) async {
    final completedItems =
        shopping.allItems.where((i) => i.completed).toList();
    final count = completedItems.length;
    if (count == 0) return;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.delete_sweep_rounded,
            color: Colors.orange, size: 32),
        iconPadding: const EdgeInsets.only(top: 20),
        title: Text(
          'Delete $count completed item${count > 1 ? 's' : ''}?',
          style: const TextStyle(fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        content: Text(
          '$count completed item${count > 1 ? 's' : ''} will be permanently removed.\nThis action cannot be undone.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(110, 40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.orange.shade600,
              minimumSize: const Size(110, 40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await shopping
          .deleteItemsBatch(completedItems.map((i) => i.id).toList());
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(children: [
              const Icon(Icons.check_circle_rounded,
                  color: Colors.white, size: 18),
              const SizedBox(width: 8),
              Text(
                  '$count completed item${count > 1 ? 's' : ''} deleted'),
            ]),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.orange.shade700,
            duration: const Duration(seconds: 2),
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
            margin: const EdgeInsets.fromLTRB(12, 0, 12, 100),
          ),
        );
      }
    }
  }

  // ── Delete selected items ─────────────────────────────────────────────────

  static Future<void> showDeleteSelected({
    required BuildContext context,
    required ShoppingProvider shopping,
    required Set<String> selectedIds,
    required VoidCallback onClearSelection,
  }) async {
    if (selectedIds.isEmpty) return;
    final count = selectedIds.length;

    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape:
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.delete_outline_rounded,
            color: Colors.red, size: 32),
        iconPadding: const EdgeInsets.only(top: 20),
        title: Text(
          'Delete $count item${count > 1 ? 's' : ''}?',
          style: const TextStyle(fontWeight: FontWeight.w800),
          textAlign: TextAlign.center,
        ),
        content: Text(
          '$count item${count > 1 ? 's' : ''} will be permanently removed from the list.\nThis action cannot be undone.',
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 14, height: 1.5),
        ),
        actionsAlignment: MainAxisAlignment.spaceEvenly,
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        actions: [
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(110, 40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red.shade500,
              minimumSize: const Size(110, 40),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await shopping.deleteItemsBatch(selectedIds.toList());
      onClearSelection();
    }
  }
}
