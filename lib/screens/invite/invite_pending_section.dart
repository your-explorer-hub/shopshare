import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/shopping_provider.dart';
import 'widgets/invite_card.dart';
import 'widgets/section_label.dart';

class InvitePendingSection extends StatelessWidget {
  final Function(Map<String, dynamic>) onAccept;
  final Function(Map<String, dynamic>) onDecline;

  const InvitePendingSection({
    super.key,
    required this.onAccept,
    required this.onDecline,
  });

  @override
  Widget build(BuildContext context) {
    final shopping = context.watch<ShoppingProvider>();
    final pendingInvites = shopping.pendingInvites;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: [
          const InviteSectionLabel(label: 'Pending Invitations'),
          if (pendingInvites.isNotEmpty) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                  color: Colors.red, borderRadius: BorderRadius.circular(10)),
              child: Text('${pendingInvites.length}',
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w700)),
            ),
          ],
        ]),
        if (pendingInvites.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text(
              'No pending invitations. When someone invites you to a shared list, it will appear here.',
              style: TextStyle(
                  fontSize: 13,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white54 : const Color(0xFF555555),
                  height: 1.5),
            ),
          )
        else ...[
          const SizedBox(height: 4),
          ...pendingInvites.map((invite) => PendingInviteCard(
                invite: invite,
                onAccept: () => onAccept(invite),
                onDecline: () => onDecline(invite),
                isLoading: shopping.invitesLoading,
              )),
          const SizedBox(height: 20),
        ],
      ],
    );
  }
}
