import 'package:flutter/material.dart';

import '../../../models/shopping_list.dart';
import '../../../utils/list_banner.dart';

class JoinedListTile extends StatelessWidget {
  final ShoppingList list;
  final bool isActive;
  final VoidCallback onTap;

  const JoinedListTile({
    super.key,
    required this.list,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accentColor = ListBannerVariant.startColorForList(list.id);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          // Joined lists: per-list accent left border
          color: isActive
              ? accentColor.withValues(alpha: 0.08)
              : Theme.of(context)
                  .colorScheme
                  .surfaceContainerHighest
                  .withValues(alpha: 0.30),
          borderRadius: BorderRadius.circular(12),
          border: Border(
            left: BorderSide(color: accentColor, width: 4),
            top: BorderSide(
                color: isActive
                    ? accentColor.withValues(alpha: 0.4)
                    : Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.15),
                width: isActive ? 1.5 : 1),
            right: BorderSide(
                color: isActive
                    ? accentColor.withValues(alpha: 0.4)
                    : Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.15),
                width: isActive ? 1.5 : 1),
            bottom: BorderSide(
                color: isActive
                    ? accentColor.withValues(alpha: 0.4)
                    : Theme.of(context)
                        .colorScheme
                        .outline
                        .withValues(alpha: 0.15),
                width: isActive ? 1.5 : 1),
          ),
        ),
        child: Row(children: [
          Icon(Icons.list_alt_rounded,
              size: 20,
              color: isActive
                  ? accentColor
                  : Theme.of(context)
                      .colorScheme
                      .onSurface
                      .withValues(alpha: 0.5)),
          const SizedBox(width: 12),
          Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
            Text(list.name,
                style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: isActive ? accentColor : null)),
            Text('Owner: ${list.ownerName}',
                style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context)
                        .colorScheme
                        .onSurface
                        .withValues(alpha: 0.5))),
          ])),
          if (isActive)
            Icon(Icons.check_circle_rounded,
                size: 18, color: accentColor),
        ]),
      ),
    );
  }
}
