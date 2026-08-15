import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../models/shopping_list.dart';
import '../../providers/shopping_provider.dart';
import 'widgets/joined_list_tile.dart';
import 'widgets/section_label.dart';

class InviteJoinedSection extends StatelessWidget {
  final String currentUserId;
  final String? activeListId;
  final Function(ShoppingList) onSwitchToList;

  const InviteJoinedSection({
    super.key,
    required this.currentUserId,
    required this.activeListId,
    required this.onSwitchToList,
  });

  @override
  Widget build(BuildContext context) {
    final shopping = context.watch<ShoppingProvider>();
    final joinedLists = shopping.joinedSharedLists;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InviteSectionLabel(label: "Lists I've Joined"),
        if (joinedLists.isEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 20),
            child: Text("You haven't joined any shared lists yet.",
                style: TextStyle(fontSize: 13,
                    color: Theme.of(context).brightness == Brightness.dark
                        ? Colors.white54 : const Color(0xFF555555))),
          )
        else
          ...joinedLists.map((list) => JoinedListTile(
            list: list,
            isActive: activeListId == list.id,
            onTap: () => onSwitchToList(list),
          )),
      ],
    );
  }
}
