import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/shopping_item.dart';
import '../../../utils/list_formatter.dart';

/// Dialog to preview and copy selected shopping items as formatted text
class ShareItemsDialog extends StatelessWidget {
  final List<ShoppingItem> items;
  final String listName;

  const ShareItemsDialog({
    super.key,
    required this.items,
    required this.listName,
  });

  static Future<void> show({
    required BuildContext context,
    required List<ShoppingItem> items,
    required String listName,
  }) async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => ShareItemsDialog(
        items: items,
        listName: listName,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // Format items as text
    final formattedText = ListFormatter.formatItemsAsText(
      items: items,
      listName: listName,
    );

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      icon: Icon(
        Icons.shopping_cart_rounded,
        color: cs.primary,
        size: 32,
      ),
      iconPadding: const EdgeInsets.only(top: 20),
      title: const Text(
        'Copy items and share',
        style: TextStyle(fontWeight: FontWeight.w800),
        textAlign: TextAlign.center,
      ),
      contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      content: SizedBox(
        width: MediaQuery.of(context).size.width * 0.8,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Preview container with formatted text (scrollable)
            Flexible(
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(context).size.height * 0.5,
                ),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.green.shade200,
                    width: 1,
                  ),
                ),
                child: SingleChildScrollView(
                  child: SelectableText(
                    formattedText,
                    style: TextStyle(
                      fontSize: 14,
                      fontFamily: 'monospace',
                      color: Colors.grey.shade800,
                      height: 1.5,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      actionsPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      actions: [
        // Close button
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
        // Copy button
        FilledButton.icon(
          onPressed: () async {
            await Clipboard.setData(ClipboardData(text: formattedText));
            if (context.mounted) {
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.white, size: 18),
                      const SizedBox(width: 8),
                      Text(
                          '${items.length} item${items.length > 1 ? 's' : ''} copied to clipboard'),
                    ],
                  ),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Colors.green.shade600,
                  duration: const Duration(seconds: 2),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  margin: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                ),
              );
            }
          },
          icon: const Icon(Icons.content_copy_rounded, size: 18),
          label: const Text('Copy'),
        ),
      ],
    );
  }
}
