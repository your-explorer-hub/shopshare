import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/home_screen_provider.dart';
import '../../../providers/shopping_provider.dart';

class HomeTabBar extends StatelessWidget {
  final MenuTab activeTab;
  final Function(MenuTab) onSelectTab;

  const HomeTabBar({
    super.key,
    required this.activeTab,
    required this.onSelectTab,
  });

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _TabChip(
              label: 'My List',
              icon: Icons.person_rounded,
              selected: activeTab == MenuTab.myList,
              onTap: () => onSelectTab(MenuTab.myList),
            ),
            const SizedBox(width: 8),
            _SharedTabChip(
              selected: activeTab == MenuTab.sharedList,
              onTap: () => onSelectTab(MenuTab.sharedList),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Tab chip ──────────────────────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final int? badge;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
    this.badge,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
        decoration: BoxDecoration(
          color: selected ? cs.primaryContainer : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: selected
                ? cs.primary.withValues(alpha: 0.6)
                : cs.outline.withValues(alpha: 0.3),
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon,
                size: 14,
                color: selected ? cs.onPrimaryContainer : cs.onSurface),
            const SizedBox(width: 5),
            Text(label,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight:
                      selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? cs.onPrimaryContainer : cs.onSurface,
                )),
            if (badge != null && badge! > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.circular(10)),
                child: Text('$badge',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

/// Shared tab chip with badge that only rebuilds when pendingInviteCount changes
class _SharedTabChip extends StatelessWidget {
  final VoidCallback onTap;
  final bool selected;

  const _SharedTabChip({
    required this.onTap,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    return Selector<ShoppingProvider, int>(
      selector: (context, shopping) => shopping.pendingInviteCount,
      builder: (context, pendingCount, _) => _TabChip(
        label: 'Shared',
        icon: Icons.group_rounded,
        selected: selected,
        badge: pendingCount > 0 ? pendingCount : null,
        onTap: onTap,
      ),
    );
  }
}
