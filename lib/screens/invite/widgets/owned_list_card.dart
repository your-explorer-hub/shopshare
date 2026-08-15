import 'package:flutter/material.dart';

import '../../../models/member.dart';
import '../../../models/shopping_list.dart';
import '../../../theme/app_theme.dart';
import '../../../utils/list_banner.dart';
import '../../../widgets/user_avatar_widget.dart';
import 'member_tile.dart';
import 'share_button.dart';

class OwnedListCard extends StatelessWidget {
  final ShoppingList list;
  final bool isExpanded;
  final int memberCount;
  final int maxMembers;
  final bool atMemberLimit;
  final String inviterName;
  final bool isOwner;
  final TextEditingController emailInviteController;
  final String? emailInviteError;
  final bool isSendingInvite;
  final VoidCallback onToggleExpand;
  final VoidCallback onShareWhatsApp;
  final VoidCallback onShareEmail;
  final VoidCallback onShareSystem;
  final VoidCallback onCopyInviteLink;
  final VoidCallback onSendInvite;
  final void Function(Member) onRemoveMember;
  final VoidCallback? onDeleteList;
  final VoidCallback? onRenameList;
  final List<Member> members;
  final String currentUserId;

  const OwnedListCard({
    super.key,
    required this.list,
    required this.isExpanded,
    required this.memberCount,
    required this.maxMembers,
    required this.atMemberLimit,
    required this.inviterName,
    required this.isOwner,
    required this.emailInviteController,
    required this.emailInviteError,
    required this.isSendingInvite,
    required this.onToggleExpand,
    required this.onShareWhatsApp,
    required this.onShareEmail,
    required this.onShareSystem,
    required this.onCopyInviteLink,
    required this.onSendInvite,
    required this.onRemoveMember,
    this.onDeleteList,
    this.onRenameList,
    required this.members,
    required this.currentUserId,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Container(
        decoration: BoxDecoration(
          // Owned lists: purple tint background
          color: isExpanded
              ? AppTheme.primaryPurple.withValues(alpha: 0.08)
              : AppTheme.primaryPurple.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isExpanded
                  ? AppTheme.primaryPurple.withValues(alpha: 0.45)
                  : AppTheme.primaryPurple.withValues(alpha: 0.2),
              width: isExpanded ? 1.5 : 1),
        ),
        child: Column(
          children: [
            // ── Card header ──────────────────────────────────────────────
            InkWell(
              borderRadius: BorderRadius.vertical(
                  top: const Radius.circular(16),
                  bottom: isExpanded ? Radius.zero : const Radius.circular(16)),
              onTap: onToggleExpand,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                child: Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        gradient: ListBannerVariant.gradientForList(list.id),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(Icons.group_rounded,
                          size: 20, color: Colors.white),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // List name with edit button
                          Row(
                            children: [
                              Expanded(
                                child: Text(list.name,
                                    style: const TextStyle(
                                        fontSize: 14, fontWeight: FontWeight.w700),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              if (isOwner && onRenameList != null) ...[
                                const SizedBox(width: 8),
                                IconButton(
                                  onPressed: onRenameList,
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  tooltip: 'Rename list',
                                  style: IconButton.styleFrom(
                                    foregroundColor: cs.primary,
                                    padding: const EdgeInsets.all(4),
                                    minimumSize: const Size(28, 28),
                                    tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                  ),
                                ),
                              ],
                            ],
                          ),
                           Text('$memberCount / $maxMembers members',
                               style: TextStyle(
                                   fontSize: 12,
                                   fontWeight: FontWeight.w500,
                                   color: atMemberLimit
                                       ? Colors.red.shade600
                                       : (Theme.of(context).brightness == Brightness.dark
                                           ? Colors.white60 : const Color(0xFF555555)))),
                        ],
                      ),
                    ),
                    // Stacked mini-avatars (up to 3)
                    ...members.take(3).toList().asMap().entries.map((e) =>
                        Transform.translate(
                          offset: Offset(-e.key * 8.0, 0),
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(color: cs.surface, width: 1.5),
                            ),
                            child: UserAvatarWidget(
                                displayName: e.value.displayName,
                                photoUrl: e.value.photoUrl,
                                radius: 12),
                          ),
                        )),
                    const SizedBox(width: 4),
                    Icon(
                      isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 20,
                      color: cs.onSurface.withValues(alpha: 0.5),
                    ),
                  ],
                ),
              ),
            ),

            // ── Expanded management panel ────────────────────────────────
            if (isExpanded) ...[
              Divider(height: 1, color: cs.outline.withValues(alpha: 0.15)),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Share buttons
                    if (isOwner) ...[
                      Row(children: [
                        Expanded(
                          child: InviteShareButton(
                            icon: Icons.chat_rounded,
                            label: 'WhatsApp',
                            color: const Color(0xFF25D366),
                            onTap: atMemberLimit ? null : onShareWhatsApp,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: InviteShareButton(
                            icon: Icons.email_rounded,
                            label: 'Email',
                            color: Colors.blue.shade600,
                            onTap: atMemberLimit ? null : onShareEmail,
                          ),
                        ),
                      ]),
                      const SizedBox(height: 8),
                      // Copy invite link button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: atMemberLimit ? null : onCopyInviteLink,
                          icon: const Icon(Icons.link_rounded, size: 16),
                          label: const Text('Copy Invite Link',
                              style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppTheme.accentTeal,
                            side: BorderSide(
                                color: atMemberLimit
                                    ? Colors.grey.shade300
                                    : AppTheme.accentTeal.withValues(alpha: 0.5)),
                            shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
                        ),
                      ),
                      const SizedBox(height: 10),
                      // Direct email invite
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: TextField(
                              controller: emailInviteController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: InputDecoration(
                                hintText: 'Invite by email…',
                                prefixIcon:
                                    const Icon(Icons.email_outlined, size: 18),
                                errorText: emailInviteError,
                                filled: true,
                                fillColor: cs.surfaceContainerHighest
                                    .withValues(alpha: 0.4),
                                border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide.none),
                                enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: BorderSide(
                                        color: cs.outline
                                            .withValues(alpha: 0.2))),
                                focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(10),
                                    borderSide: const BorderSide(
                                        color: AppTheme.primaryPurple,
                                        width: 1.5)),
                                contentPadding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 10),
                                isDense: true,
                              ),
                              onSubmitted:
                                  atMemberLimit ? null : (_) => onSendInvite(),
                            ),
                          ),
                          const SizedBox(width: 8),
                          SizedBox(
                            height: 42,
                            child: FilledButton(
                              onPressed: atMemberLimit || isSendingInvite
                                  ? null
                                  : onSendInvite,
                              style: FilledButton.styleFrom(
                                backgroundColor: AppTheme.primaryPurple,
                                shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(10)),
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 14),
                              ),
                              child: isSendingInvite
                                  ? const SizedBox(
                                      width: 16,
                                      height: 16,
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: Colors.white))
                                  : const Text('Invite',
                                      style: TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 13)),
                            ),
                          ),
                        ],
                      ),
                      if (atMemberLimit)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                              'Member limit reached. Upgrade to add more.',
                              style: TextStyle(
                                  fontSize: 11,
                                  color: Colors.orange.shade700)),
                        ),
                      const SizedBox(height: 12),
                    ],

                    // Members list
                    if (members.isEmpty)
                      Text('No members yet.',
                          style: TextStyle(
                              fontSize: 12,
                              color: cs.onSurface.withValues(alpha: 0.4)))
                    else
                      ...members.map((m) => InviteMemberTile(
                            member: m,
                            isOwner: isOwner,
                            currentUserId: currentUserId,
                            listOwnerId: list.ownerId,
                            listName: list.name,
                            onRemove: onRemoveMember,
                          )),

                    // Delete list section (owner-only, shared lists only)
                    if (isOwner && list.type == 'shared' && onDeleteList != null) ...[
                      const SizedBox(height: 16),
                      Divider(
                          height: 1,
                          color: cs.outline.withValues(alpha: 0.15)),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: onDeleteList,
                          icon: const Icon(Icons.delete_outline_rounded,
                              size: 18),
                          label: const Text(
                            'Delete List',
                            style: TextStyle(
                                fontSize: 13, fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.red.shade600,
                            side: BorderSide(
                                color: Colors.red.shade300, width: 1.5),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 12),
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'This will permanently delete the list for all $memberCount member${memberCount != 1 ? 's' : ''}.',
                        style: TextStyle(
                          fontSize: 11,
                          color: cs.onSurface.withValues(alpha: 0.5),
                          height: 1.3,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
