import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/user_profile.dart';
import '../../../providers/home_screen_provider.dart';
import '../../../providers/shopping_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/list_banner.dart';

/// Combined sticky header with tab selector + list banner
/// This widget stays pinned at the top while scrolling, showing:
/// - Tab selector (My List / Shared)
/// - Current list banner (with list name and context)
class HomeStickyNavigation extends StatelessWidget {
  final MenuTab activeTab;
  final Function(MenuTab) onSelectTab;
  final VoidCallback onSharedBannerTap;

  const HomeStickyNavigation({
    super.key,
    required this.activeTab,
    required this.onSelectTab,
    required this.onSharedBannerTap,
  });

  @override
  Widget build(BuildContext context) {
    return SliverPersistentHeader(
      pinned: true,
      delegate: _StickyNavigationDelegate(
        activeTab: activeTab,
        onSelectTab: onSelectTab,
        onSharedBannerTap: onSharedBannerTap,
      ),
    );
  }
}

// ── Persistent header delegate ───────────────────────────────────────────────

class _StickyNavigationDelegate extends SliverPersistentHeaderDelegate {
  final MenuTab activeTab;
  final Function(MenuTab) onSelectTab;
  final VoidCallback onSharedBannerTap;

  _StickyNavigationDelegate({
    required this.activeTab,
    required this.onSelectTab,
    required this.onSharedBannerTap,
  });

  @override
  double get minExtent => 122.0; // Tab selector (50px) + Banner (64px) + spacing (8px)

  @override
  double get maxExtent => 122.0;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final cs = Theme.of(context).colorScheme;

    return Container(
      color: cs.surface,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tab Selector Row
          Padding(
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

          // List Banner (conditional based on active tab)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: activeTab == MenuTab.myList
                ? const _MyListBannerContent()
                : _SharedListBannerContent(onTap: onSharedBannerTap),
          ),
        ],
      ),
    );
  }

  @override
  bool shouldRebuild(_StickyNavigationDelegate oldDelegate) {
    return activeTab != oldDelegate.activeTab;
  }
}

// ── Tab chip widgets ─────────────────────────────────────────────────────────

class _TabChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _TabChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
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
                  fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                  color: selected ? cs.onPrimaryContainer : cs.onSurface,
                )),
          ],
        ),
      ),
    );
  }
}

class _SharedTabChip extends StatelessWidget {
  final VoidCallback onTap;
  final bool selected;

  const _SharedTabChip({
    required this.onTap,
    required this.selected,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Selector<ShoppingProvider, int>(
      selector: (context, shopping) => shopping.pendingInviteCount,
      builder: (context, pendingCount, _) => GestureDetector(
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
              Icon(Icons.group_rounded,
                  size: 14,
                  color: selected ? cs.onPrimaryContainer : cs.onSurface),
              const SizedBox(width: 5),
              Text('Shared',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: selected ? FontWeight.w700 : FontWeight.w400,
                    color: selected ? cs.onPrimaryContainer : cs.onSurface,
                  )),
              if (pendingCount > 0) ...[
                const SizedBox(width: 5),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                  decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(10)),
                  child: Text('$pendingCount',
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w700)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

// ── List banner content widgets ──────────────────────────────────────────────

class _MyListBannerContent extends StatelessWidget {
  const _MyListBannerContent();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 56,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryPurple,
            const Color(0xFF9C27B0),
            AppTheme.accentTeal,
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryPurple.withValues(alpha: 0.3),
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
            child: const Icon(Icons.person_rounded,
                size: 22, color: Colors.white),
          ),
          const SizedBox(width: 12),
          const Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'My Personal List',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  'Private shopping list',
                  style: TextStyle(
                    color: Color(0xFFE3E3E3),
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SharedListBannerContent extends StatelessWidget {
  final VoidCallback onTap;

  const _SharedListBannerContent({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shopping = context.watch<ShoppingProvider>();
    final sharedListCount = shopping.availableLists.where((l) => l.isShared).length;

    // Check if we're in loading state (list ID set but data not loaded yet)
    final isLoading = shopping.listId != null && shopping.activeList == null;

    return GestureDetector(
      onTap: sharedListCount > 1 ? onTap : null,
      child: Container(
        height: 56,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          gradient: ListBannerVariant.gradientForList(shopping.listId ?? ''),
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: ListBannerVariant.startColorForList(shopping.listId ?? '')
                  .withValues(alpha: 0.3),
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
              child: const Icon(Icons.group_rounded,
                  size: 22, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    isLoading ? 'Loading...' : shopping.activeListName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    isLoading
                        ? 'Loading members...'
                        : '${shopping.activeList?.memberIds.length ?? 0} members',
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.85),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            // Member avatars (show 2, then +n) - hide during loading
            if (!isLoading) _buildMemberAvatars(shopping),
            const SizedBox(width: 8),
            if (sharedListCount > 1)
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.swap_horiz_rounded,
                    size: 20, color: Colors.white),
              ),
          ],
        ),
      ),
    );
  }

  /// Build member avatar circles - show 2, then +n for remaining
  Widget _buildMemberAvatars(ShoppingProvider shopping) {
    final members = shopping.members;
    if (members.isEmpty) return const SizedBox.shrink();

    const maxVisible = 2;
    final visibleMembers = members.take(maxVisible).toList();
    final remainingCount =
        members.length > maxVisible ? members.length - maxVisible : 0;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Show first 2 member avatars
        ...visibleMembers.map((member) {
          return Container(
            margin: const EdgeInsets.only(left: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              backgroundImage:
                  member.photoUrl != null && member.photoUrl!.isNotEmpty
                      ? NetworkImage(member.photoUrl!)
                      : null,
              child: member.photoUrl == null || member.photoUrl!.isEmpty
                  ? Text(
                      member.displayName.isNotEmpty
                          ? member.displayName[0].toUpperCase()
                          : '?',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                      ),
                    )
                  : null,
            ),
          );
        }),
        // Show +n for remaining members
        if (remainingCount > 0)
          Container(
            margin: const EdgeInsets.only(left: 4),
            child: CircleAvatar(
              radius: 16,
              backgroundColor: Colors.white.withValues(alpha: 0.3),
              child: Text(
                '+$remainingCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
