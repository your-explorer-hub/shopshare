import 'package:flutter/material.dart';

import '../../../models/shopping_item.dart';
import '../../../models/shopping_list.dart';
import '../../../providers/shopping_provider.dart';
import '../../../utils/list_banner.dart';

class MoveDialog {
  static Future<void> show({
    required BuildContext context,
    required List<ShoppingItem> selectedItems,
    required ShoppingProvider shopping,
    required String userId,
    required String userName,
    required VoidCallback onClearSelection,
  }) async {
    final sharedLists = shopping.availableLists
        .where((l) => l.isShared && l.id != shopping.listId)
        .toList();
    final personalLists = shopping.availableLists
        .where((l) => !l.isShared && l.id != shopping.listId)
        .toList();

    final cs = Theme.of(context).colorScheme;

    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        icon: const Icon(Icons.drive_file_move_rounded,
            color: Colors.blue, size: 32),
        iconPadding: const EdgeInsets.only(top: 20),
        title: Column(
          children: [
            Text(
              'Move ${selectedItems.length} item${selectedItems.length > 1 ? 's' : ''}',
              style: const TextStyle(fontWeight: FontWeight.w800),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 4),
            Text(
              'Selected items will be removed from current list',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.normal,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // ── Shared Lists Section ──
              if (sharedLists.isNotEmpty) ...[
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(
                    "📋 Shared Lists",
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey),
                  ),
                ),
                // Show ALL shared lists as banners
                ...sharedLists.map((list) => _ListBanner(
                      list: list,
                      isShared: true,
                      onTap: () async {
                        Navigator.pop(ctx);
                        final count = selectedItems.length;
                        final ids = selectedItems.map((i) => i.id).toList();
                        final err = await shopping.moveItemsToList(
                          itemIds: ids,
                          targetListId: list.id,
                          movedBy: userId,
                          movedByName: userName,
                        );
                        onClearSelection();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Row(children: [
                              Icon(
                                err == null
                                    ? Icons.check_circle_rounded
                                    : Icons.error_outline_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  err == null
                                      ? '$count item${count > 1 ? 's' : ''} moved to "${list.name}"'
                                      : 'Failed to move items',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ]),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: err == null
                                ? Colors.blue.shade600
                                : Colors.red.shade600,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                          ));
                        }
                      },
                    )),
              ],

              // ── Personal Lists Section ──
              if (personalLists.isNotEmpty) ...[
                if (sharedLists.isNotEmpty) const SizedBox(height: 12),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  child: Text(
                    "📄 Personal Lists",
                    style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey),
                  ),
                ),
                // Show ALL personal lists as banners
                ...personalLists.map((list) => _ListBanner(
                      list: list,
                      isShared: false,
                      onTap: () async {
                        Navigator.pop(ctx);
                        final count = selectedItems.length;
                        final ids = selectedItems.map((i) => i.id).toList();
                        final err = await shopping.moveItemsToList(
                          itemIds: ids,
                          targetListId: list.id,
                          movedBy: userId,
                          movedByName: userName,
                        );
                        onClearSelection();
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                            content: Row(children: [
                              Icon(
                                err == null
                                    ? Icons.check_circle_rounded
                                    : Icons.error_outline_rounded,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  err == null
                                      ? '$count item${count > 1 ? 's' : ''} moved to "${list.name}"'
                                      : 'Failed to move items',
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                            ]),
                            behavior: SnackBarBehavior.floating,
                            backgroundColor: err == null
                                ? Colors.purple.shade600
                                : Colors.red.shade600,
                            duration: const Duration(seconds: 2),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12)),
                            margin: const EdgeInsets.fromLTRB(12, 0, 12, 100),
                          ));
                        }
                      },
                    )),
              ],

              // ── No Lists Available ──
              if (sharedLists.isEmpty && personalLists.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Icon(Icons.inbox_rounded,
                          size: 48, color: cs.onSurface.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text(
                        "No other lists available",
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: cs.onSurface.withValues(alpha: 0.6),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Create a new list to move items",
                        style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha: 0.45),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 8),
            ],
          ),
        ),
        actionsPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
        ],
      ),
    );
  }
}

/// List banner widget matching home screen style
class _ListBanner extends StatelessWidget {
  final ShoppingList list;
  final bool isShared;
  final VoidCallback onTap;

  const _ListBanner({
    required this.list,
    required this.isShared,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final gradient = isShared
        ? ListBannerVariant.gradientForList(list.id)
        : ListBannerVariant.gradientForMyList();

    final shadowColor = isShared
        ? ListBannerVariant.startColorForList(list.id)
        : const Color(0xFF6A3DE8);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          height: 64,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            gradient: gradient,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: shadowColor.withValues(alpha: 0.3),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  isShared ? Icons.group_rounded : Icons.person_rounded,
                  size: 22,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      list.name,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      isShared
                          ? '${list.memberIds.length} member${list.memberIds.length > 1 ? 's' : ''}'
                          : 'Private shopping list',
                      style: TextStyle(
                        color: Colors.white.withValues(alpha: 0.85),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.white.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
