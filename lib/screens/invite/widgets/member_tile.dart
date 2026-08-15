import 'package:flutter/material.dart';

import '../../../models/member.dart';
import '../../../widgets/user_avatar_widget.dart';

class InviteMemberTile extends StatelessWidget {
  final Member member;
  final bool isOwner;
  final String currentUserId;
  final String listOwnerId;
  final String listName;
  final void Function(Member) onRemove;

  const InviteMemberTile({
    super.key,
    required this.member,
    required this.isOwner,
    required this.currentUserId,
    required this.listOwnerId,
    required this.listName,
    required this.onRemove,
  });

  @override
  Widget build(BuildContext context) {
    final canRemove = isOwner && member.userId != listOwnerId;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color:
                Theme.of(context).colorScheme.outline.withValues(alpha: 0.15)),
      ),
      child: Row(children: [
        UserAvatarWidget(
            displayName: member.displayName,
            photoUrl: member.photoUrl,
            radius: 18),
        const SizedBox(width: 12),
        Expanded(
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
              Text(member.displayName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w600)),
              Text(member.email,
                  style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.5))),
            ])),
        if (canRemove)
          TextButton(
            onPressed: () => onRemove(member),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
                side: BorderSide(color: Colors.red.shade300),
              ),
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text('Remove',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
          ),
      ]),
    );
  }
}
