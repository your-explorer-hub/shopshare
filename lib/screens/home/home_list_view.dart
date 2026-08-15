import 'package:flutter/material.dart';

import '../../models/shopping_item.dart';
import '../../utils/date_utils.dart';
import '../../widgets/item_card_widget.dart';

class HomeListView extends StatelessWidget {
  final List<ShoppingItem> items;
  final bool isSharedList;
  final Set<String> selectedIds;
  final void Function(ShoppingItem item, String userName) onToggle;
  final void Function(ShoppingItem item) onDelete;
  final void Function(String id) onSelectToggle;
  final String userName;
  final bool isLoading;

  const HomeListView({
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
      return const _EmptyState();
    }

    // Group by date
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
          final item = indexMap[index];

          // Check if this is a header
          if (indexMap.isHeader(index)) {
            return _DateHeader(dateKey: (item as _DateHeaderData).dateKey);
          }

          // Otherwise it's a shopping item
          final shoppingItem = item as ShoppingItem;
          return RepaintBoundary(
            key: ValueKey(shoppingItem.id),
            child: ItemCardWidget(
              item: shoppingItem,
              isSelected: selectedIds.contains(shoppingItem.id),
              isSharedList: isSharedList,
              onToggle: () => onToggle(shoppingItem, userName),
              onDelete: () => onDelete(shoppingItem),
              onSelectToggle: () => onSelectToggle(shoppingItem.id),
            ),
          );
        },
        childCount: indexMap.length,
      ),
    );
  }
}

class _DateHeader extends StatelessWidget {
  final String dateKey;
  const _DateHeader({required this.dateKey});

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
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Text(
        _label(),
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: cs.onSurface.withValues(alpha: 0.45),
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return SliverFillRemaining(
      hasScrollBody: false,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 64, color: cs.onSurface.withValues(alpha: 0.2)),
            const SizedBox(height: 16),
            Text(
              'No items yet',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: cs.onSurface.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Tap + to add your first item',
              style: TextStyle(
                fontSize: 14,
                color: cs.onSurface.withValues(alpha: 0.3),
              ),
            ),
          ],
        ),
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
      items.add(_DateHeaderData(dateKey: key));
      items.addAll(grouped[key]!);
    }
  }

  int get length => items.length;

  dynamic operator [](int index) => items[index];

  bool isHeader(int index) => items[index] is _DateHeaderData;
}

class _DateHeaderData {
  final String dateKey;
  const _DateHeaderData({required this.dateKey});
}
