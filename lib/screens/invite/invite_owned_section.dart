import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/member.dart';
import '../../models/shopping_list.dart';
import '../../models/user_profile.dart';
import '../../providers/invite_screen_provider.dart';
import '../../providers/shopping_provider.dart';
import '../../theme/app_theme.dart';
import '../../utils/subscription_limits.dart';
import 'widgets/owned_list_card.dart';
import 'widgets/section_label.dart';

class InviteOwnedSection extends StatelessWidget {
  final UserProfile userProfile;
  final SubscriptionTier tier;
  final TextEditingController emailInviteController;
  final Function(ShoppingList) onShareWhatsApp;
  final Function(ShoppingList) onShareEmail;
  final Function(ShoppingList) onShareSystem;
  final Function(ShoppingList) onCopyInviteLink;
  final Function(String) onSendInvite;
  final Function(Member, String) onRemoveMember;
  final Function(ShoppingList) onDeleteList;
  final Function(ShoppingList) onRenameList;
  final VoidCallback onCreateList;

  const InviteOwnedSection({
    super.key,
    required this.userProfile,
    required this.tier,
    required this.emailInviteController,
    required this.onShareWhatsApp,
    required this.onShareEmail,
    required this.onShareSystem,
    required this.onCopyInviteLink,
    required this.onSendInvite,
    required this.onRemoveMember,
    required this.onDeleteList,
    required this.onRenameList,
    required this.onCreateList,
  });

  @override
  Widget build(BuildContext context) {
    final shopping = context.watch<ShoppingProvider>();
    final inviteState = context.watch<InviteScreenProvider>();
    final cs = Theme.of(context).colorScheme;

    final ownedSharedLists = shopping.availableLists
        .where((l) => l.isShared && l.ownerId == userProfile.id)
        .toList();

    final maxOwned = SubscriptionLimits.maxOwnedSharedLists(tier);
    final atOwnedLimit = ownedSharedLists.length >= maxOwned;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header with count and "New" button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const InviteSectionLabel(label: 'Your Shared Lists'),
                Text(
                  '${ownedSharedLists.length} of $maxOwned used',
                  style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white70
                          : const Color(0xFF444444)),
                ),
              ],
            ),
            FilledButton.icon(
              onPressed: atOwnedLimit ? null : onCreateList,
              icon: const Icon(Icons.add_rounded, size: 16),
              label: const Text('New',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              style: FilledButton.styleFrom(
                backgroundColor: AppTheme.primaryPurple,
                foregroundColor: Colors.white,
                disabledBackgroundColor: cs.onSurface.withValues(alpha: 0.12),
                minimumSize: Size.zero,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ],
        ),

        if (atOwnedLimit)
          Padding(
            padding: const EdgeInsets.only(top: 6),
            child: Text(
                'Limit reached for ${SubscriptionLimits.tierDisplayName(tier)}. Upgrade to create more.',
                style: TextStyle(fontSize: 12, color: Colors.orange.shade700, height: 1.4)),
          ),

        const SizedBox(height: 12),

        // Empty state
        if (ownedSharedLists.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 20),
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: cs.outline.withValues(alpha: 0.15)),
              ),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Icon(Icons.group_add_rounded, size: 40,
                    color: cs.onSurface.withValues(alpha: 0.3)),
                const SizedBox(height: 12),
                 Text("You haven't created any shared lists yet.",
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600,
                        color: Theme.of(context).brightness == Brightness.dark
                            ? Colors.white70 : const Color(0xFF333333))),
                 const SizedBox(height: 6),
                 Text("Tap 'New' to create one and invite family or friends.",
                     textAlign: TextAlign.center,
                     style: TextStyle(fontSize: 12,
                         color: Theme.of(context).brightness == Brightness.dark
                             ? Colors.white54 : const Color(0xFF555555))),
              ]),
            ),
          )
        else
          // List of owned cards
          ...ownedSharedLists.map((list) {
            final memberCount = list.memberIds.length;
            final maxMembers = SubscriptionLimits.maxMembersPerList(tier);
            final atMemberLimit = memberCount >= maxMembers;
            final inviterName = userProfile.displayName;
            final isOwner = list.ownerId == userProfile.id;

            return OwnedListCard(
              list: list,
              isExpanded: inviteState.expandedListId == list.id,
              memberCount: memberCount,
              maxMembers: maxMembers,
              atMemberLimit: atMemberLimit,
              inviterName: inviterName,
              isOwner: isOwner,
              emailInviteController: emailInviteController,
              emailInviteError: inviteState.emailInviteError,
              isSendingInvite: inviteState.isSendingInvite,
              onToggleExpand: () {
                final wasExpanded = inviteState.expandedListId == list.id;
                context.read<InviteScreenProvider>().toggleExpandedList(wasExpanded ? null : list.id);
                if (!wasExpanded) {
                  context.read<ShoppingProvider>().subscribeToMembersForList(list.id);
                }
              },
              onShareWhatsApp: () => onShareWhatsApp(list),
              onShareEmail: () => onShareEmail(list),
              onShareSystem: () => onShareSystem(list),
              onCopyInviteLink: () => onCopyInviteLink(list),
              onSendInvite: () => onSendInvite(list.id),
              onRemoveMember: (m) => onRemoveMember(m, list.name),
              onDeleteList: () => onDeleteList(list),
              onRenameList: () => onRenameList(list),
              members: shopping.members.where((m) => list.memberIds.contains(m.userId)).toList(),
              currentUserId: userProfile.id,
            );
          }),
      ],
    );
  }
}
