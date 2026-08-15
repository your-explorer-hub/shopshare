import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../models/shopping_list.dart';
import '../../../providers/shopping_provider.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/list_banner.dart';

class MyListBanner extends StatelessWidget {
  const MyListBanner({super.key});

  @override
  Widget build(BuildContext context) {
    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: Container(
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
        ),
      ),
    );
  }
}

class SharedListBanner extends StatelessWidget {
  final VoidCallback onTap;

  const SharedListBanner({
    super.key,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final shopping = context.watch<ShoppingProvider>();
    final sharedListCount = shopping.availableLists.where((l) => l.isShared).length;

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
        child: GestureDetector(
          onTap: sharedListCount > 1 ? onTap : null,
          child: Container(
            height: 56,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              gradient: ListBannerVariant.gradientForList(shopping.listId ?? ''),
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: ListBannerVariant.startColorForList(shopping.listId ?? '').withValues(alpha: 0.3),
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
                        shopping.activeListName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        '${shopping.activeList?.memberIds.length ?? 0} members',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.85),
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                // Member avatars (show 2, then +n)
                _buildMemberAvatars(shopping),
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
    final remainingCount = members.length > maxVisible ? members.length - maxVisible : 0;

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
              backgroundImage: member.photoUrl != null && member.photoUrl!.isNotEmpty
                  ? NetworkImage(member.photoUrl!)
                  : null,
              child: member.photoUrl == null || member.photoUrl!.isEmpty
                  ? Text(
                      member.displayName.isNotEmpty ? member.displayName[0].toUpperCase() : '?',
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

// ── Shared list picker bottom sheet ──────────────────────────────────────────

class SharedListPickerSheet extends StatelessWidget {
  final List<ShoppingList> lists;
  final String? activeListId;
  final ValueChanged<String> onSelect;

  const SharedListPickerSheet({
    super.key,
    required this.lists,
    required this.activeListId,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: cs.onSurface.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text('Switch Shared List',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ...lists.map((list) {
            final isActive = list.id == activeListId;
            return ListTile(
              leading: Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  gradient: ListBannerVariant.gradientForList(list.id),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.group_rounded,
                    size: 18, color: Colors.white),
              ),
              title: Text(list.name,
                  style: TextStyle(
                      fontWeight: isActive
                          ? FontWeight.w700
                          : FontWeight.w500)),
              subtitle: Text('${list.memberIds.length} members',
                  style: const TextStyle(fontSize: 12)),
              trailing: isActive
                  ? Icon(Icons.check_circle_rounded, color: cs.primary)
                  : null,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              onTap: () {
                onSelect(list.id);
                Navigator.pop(context);
              },
            );
          }),
        ],
      ),
    );
  }
}
