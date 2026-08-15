import 'package:flutter/material.dart';

import '../../models/shopping_item.dart';
import '../../theme/app_theme.dart';
import '../../utils/item_categories.dart';
import '../../widgets/item_card_widget.dart';

class HomeCategorisedView extends StatelessWidget {
  final List<ShoppingItem> items;
  final bool isSharedList;
  final Set<String> selectedIds;
  final void Function(ShoppingItem item, String userName) onToggle;
  final void Function(ShoppingItem item) onDelete;
  final void Function(String id) onSelectToggle;
  final String userName;
  final bool isLoading;

  const HomeCategorisedView({
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

    // Group by category in the order defined by ItemCategory.all
    final grouped = <String, List<ShoppingItem>>{};
    for (final cat in ItemCategory.all) {
      final catItems = items.where((i) => i.category == cat).toList();
      if (catItems.isNotEmpty) grouped[cat] = catItems;
    }
    // Any items with categories not in ItemCategory.all go to Other
    final otherItems = items
        .where((i) => !ItemCategory.all.contains(i.category))
        .toList();
    if (otherItems.isNotEmpty) {
      grouped.putIfAbsent(ItemCategory.other, () => []).addAll(otherItems);
    }

    final cats = grouped.keys.toList();

    // Pre-calculate index map for O(1) lookups
    final indexMap = _IndexMap(grouped, cats);

    return SliverList(
      delegate: SliverChildBuilderDelegate(
        (context, index) {
          final data = indexMap[index];

          // Check if this is a header
          if (indexMap.isHeader(index)) {
            return _CategoryHeader(category: (data as _CategoryHeaderData).category);
          }

          // Otherwise it's a shopping item
          final item = data as ShoppingItem;
          return RepaintBoundary(
            key: ValueKey(item.id),
            child: ItemCardWidget(
              item: item,
              isSelected: selectedIds.contains(item.id),
              isSharedList: isSharedList,
              onToggle: () => onToggle(item, userName),
              onDelete: () => onDelete(item),
              onSelectToggle: () => onSelectToggle(item.id),
            ),
          );
        },
        childCount: indexMap.length,
      ),
    );
  }
}

class _CategoryHeader extends StatelessWidget {
  final String category;
  const _CategoryHeader({required this.category});

  @override
  Widget build(BuildContext context) {
    final color = AppTheme.categoryColor(category);
    final emoji = ItemCategory.emoji(category);
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 16, 4, 6),
      child: Row(
        children: [
          Text(emoji, style: const TextStyle(fontSize: 14)),
          const SizedBox(width: 6),
          Text(
            category,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: color,
              letterSpacing: 0.3,
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

  _IndexMap(Map<String, List<ShoppingItem>> grouped, List<String> categories)
      : items = [] {
    for (final cat in categories) {
      items.add(_CategoryHeaderData(category: cat));
      items.addAll(grouped[cat]!);
    }
  }

  int get length => items.length;

  dynamic operator [](int index) => items[index];

  bool isHeader(int index) => items[index] is _CategoryHeaderData;
}

class _CategoryHeaderData {
  final String category;
  const _CategoryHeaderData({required this.category});
}
