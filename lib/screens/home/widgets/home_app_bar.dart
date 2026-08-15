import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/shopping_provider.dart';
import '../../../widgets/profile_menu_widget.dart';

class HomeAppBar extends StatelessWidget {
  final String userName;
  final bool hasSelection;
  final int selectedCount;
  final VoidCallback onClearSelection;
  final VoidCallback onDeleteCompleted;

  const HomeAppBar({
    super.key,
    required this.userName,
    required this.hasSelection,
    required this.selectedCount,
    required this.onClearSelection,
    required this.onDeleteCompleted,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    return SliverAppBar(
      pinned: true,
      floating: false,
      expandedHeight: 56,
      backgroundColor: cs.surface,
      surfaceTintColor: Colors.transparent,
      title: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('ShopShare',
                    style: TextStyle(
                        color: cs.onSurface,
                        fontSize: 22,
                        fontWeight: FontWeight.w700)),
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 300),
                  child: _HomeItemsCounter(
                    key: ValueKey(hasSelection),
                    hasSelection: hasSelection,
                    selectedCount: selectedCount,
                  ),
                ),
              ],
            ),
          ),
          if (hasSelection)
            IconButton(
              icon: Icon(Icons.deselect_rounded, color: cs.onSurface),
              tooltip: 'Clear selection',
              onPressed: onClearSelection,
              visualDensity: VisualDensity.compact,
              padding: EdgeInsets.zero,
              constraints:
                  const BoxConstraints(minWidth: 36, minHeight: 36),
            ),
          const _ShowCompletedButton(),
          _DeleteCompletedButton(onPressed: onDeleteCompleted),
          const ProfileMenuWidget(),
        ],
      ),
    );
  }
}

// Import required widgets that are still in home_screen.dart
// These are already defined in home_screen.dart, we'll use them

/// Items counter that only rebuilds when pending count changes
class _HomeItemsCounter extends StatelessWidget {
  final bool hasSelection;
  final int selectedCount;

  const _HomeItemsCounter({
    super.key,
    required this.hasSelection,
    required this.selectedCount,
  });

  @override
  Widget build(BuildContext context) {
    if (hasSelection) {
      return Text(
        '$selectedCount item${selectedCount > 1 ? 's' : ''} selected',
        style: TextStyle(
            color: Theme.of(context).colorScheme.primary,
            fontSize: 12),
      );
    }

    return Selector<ShoppingProvider, int>(
      selector: (context, shopping) =>
          shopping.filteredItems.where((i) => !i.completed).length,
      builder: (context, pendingCount, _) => Text(
        '$pendingCount items left',
        style: TextStyle(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 12),
      ),
    );
  }
}

/// Show completed toggle that only rebuilds when showCompleted changes
class _ShowCompletedButton extends StatelessWidget {
  const _ShowCompletedButton();

  @override
  Widget build(BuildContext context) {
    return Selector<ShoppingProvider, bool>(
      selector: (context, shopping) => shopping.showCompleted,
      builder: (context, showCompleted, _) {
        final shopping = context.read<ShoppingProvider>();
        final cs = Theme.of(context).colorScheme;
        return IconButton(
          icon: Icon(
              showCompleted
                  ? Icons.visibility_rounded
                  : Icons.visibility_off_rounded,
              color: cs.onSurface),
          tooltip: showCompleted ? 'Hide completed' : 'Show completed',
          onPressed: shopping.toggleShowCompleted,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        );
      },
    );
  }
}

/// Delete completed button that only rebuilds when hasCompleted changes
class _DeleteCompletedButton extends StatelessWidget {
  final VoidCallback onPressed;

  const _DeleteCompletedButton({required this.onPressed});

  @override
  Widget build(BuildContext context) {
    return Selector<ShoppingProvider, bool>(
      selector: (context, shopping) => shopping.allItems.any((i) => i.completed),
      builder: (context, hasCompleted, _) {
        final cs = Theme.of(context).colorScheme;
        return IconButton(
          icon: Icon(Icons.delete_sweep_rounded,
              color: hasCompleted
                  ? Colors.orange.shade600
                  : cs.onSurface),
          tooltip: 'Delete completed',
          onPressed: hasCompleted ? onPressed : null,
          visualDensity: VisualDensity.compact,
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
        );
      },
    );
  }
}
