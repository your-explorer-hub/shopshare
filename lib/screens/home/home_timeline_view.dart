import 'package:flutter/material.dart';

import '../../models/shopping_item.dart';
import '../../utils/date_utils.dart';
import '../../widgets/item_card_widget.dart';

class HomeTimelineView extends StatelessWidget {
  final List<ShoppingItem> items;
  final bool isSharedList;
  final Set<String> selectedIds;
  final void Function(ShoppingItem item, String userName) onToggle;
  final void Function(ShoppingItem item) onDelete;
  final void Function(String id) onSelectToggle;
  final String userName;
  final bool isLoading;

  const HomeTimelineView({
    super.key,
    required this.items,
    required this.isSharedList,
    required this.selectedIds,
    required this.onToggle,
    required this.onDelete,
    required this.onSelectToggle,
    required this.userName,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const _LoadingState();
    }

    if (items.isEmpty) {
      return const SliverFillRemaining(
        hasScrollBody: false,
        child: Center(child: Text('No items')),
      );
    }

    // Group by date, sorted newest first
    final grouped = <String, List<ShoppingItem>>{};
    for (final item in items) {
      final key = AppDateUtils.dateKey(item.addedAt);
      grouped.putIfAbsent(key, () => []).add(item);
    }
    final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

    // Pre-calculate index map for O(1) lookups
    final indexMap = _IndexMap(grouped, sortedKeys);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final data = indexMap[index];

          // Check if this is a header
          if (indexMap.isHeader(index)) {
            return _TimelineDateHeader(dateKey: (data as _TimelineHeaderData).dateKey);
          }

          // Otherwise it's a timeline item
          final itemData = data as _TimelineItemData;
          return _TimelineItemRow(
            item: itemData.item,
            isLast: itemData.isLast,
            isSelected: selectedIds.contains(itemData.item.id),
            isSharedList: isSharedList,
            onToggle: () => onToggle(itemData.item, userName),
            onDelete: () => onDelete(itemData.item),
            onSelectToggle: () => onSelectToggle(itemData.item.id),
          );
        },
        childCount: indexMap.length,
      ),
    );
  }
}

class _TimelineDateHeader extends StatelessWidget {
  final String dateKey;
  const _TimelineDateHeader({required this.dateKey});

  String _label() {
    final parts = dateKey.split('-');
    if (parts.length != 3) return dateKey;
    final dt = DateTime(
        int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    if (dt == today) return 'Today';
    if (dt == yesterday) return 'Yesterday';
    return AppDateUtils.formatDate(dt);
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 20, 4, 8),
      child: Row(
        children: [
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: cs.primaryContainer,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _label(),
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: cs.onPrimaryContainer,
              ),
            ),
          ),
          Expanded(
            child: Divider(
              indent: 8,
              color: cs.outline.withValues(alpha: 0.2),
            ),
          ),
        ],
      ),
    );
  }
}

class _TimelineItemRow extends StatelessWidget {
  final ShoppingItem item;
  final bool isLast;
  final bool isSelected;
  final bool isSharedList;
  final VoidCallback onToggle;
  final VoidCallback onDelete;
  final VoidCallback onSelectToggle;

  const _TimelineItemRow({
    required this.item,
    required this.isLast,
    required this.isSelected,
    required this.isSharedList,
    required this.onToggle,
    required this.onDelete,
    required this.onSelectToggle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline bar
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  margin: const EdgeInsets.only(top: 14),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: item.completed
                        ? Colors.green.shade400
                        : cs.primary.withValues(alpha: 0.6),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      color: cs.outline.withValues(alpha: 0.15),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: RepaintBoundary(
                key: ValueKey(item.id),
                child: ItemCardWidget(
                  item: item,
                  isSelected: isSelected,
                  isSharedList: isSharedList,
                  onToggle: onToggle,
                  onDelete: onDelete,
                  onSelectToggle: onSelectToggle,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}


// ── Loading state ─────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                color: cs.primary,
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Loading items...',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: cs.onSurface.withValues(alpha: 0.6),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Index map for O(1) lookups ────────────────────────────────────────────────

class _IndexMap {
  final List<dynamic> items;

  _IndexMap(Map<String, List<ShoppingItem>> grouped, List<String> sortedKeys)
      : items = [] {
    for (final key in sortedKeys) {
      items.add(_TimelineHeaderData(dateKey: key));
      final groupItems = grouped[key]!;
      for (int i = 0; i < groupItems.length; i++) {
        items.add(_TimelineItemData(
          item: groupItems[i],
          isLast: i == groupItems.length - 1,
        ));
      }
    }
  }

  int get length => items.length;

  dynamic operator [](int index) => items[index];

  bool isHeader(int index) => items[index] is _TimelineHeaderData;
}

class _TimelineHeaderData {
  final String dateKey;
  const _TimelineHeaderData({required this.dateKey});
}

class _TimelineItemData {
  final ShoppingItem item;
  final bool isLast;
  const _TimelineItemData({required this.item, required this.isLast});
}
