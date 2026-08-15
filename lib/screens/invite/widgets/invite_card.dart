import 'package:flutter/material.dart';

import '../../../theme/app_theme.dart';

class PendingInviteCard extends StatelessWidget {
  final Map<String, dynamic> invite;
  final VoidCallback onAccept;
  final VoidCallback onDecline;
  final bool isLoading;

  const PendingInviteCard({
    super.key,
    required this.invite,
    required this.onAccept,
    required this.onDecline,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final listName = invite['listName'] as String? ?? 'Unknown List';
    final invitedByName = invite['invitedByName'] as String? ?? 'Someone';

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Theme.of(context)
            .colorScheme
            .surfaceContainerHighest
            .withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
            color: AppTheme.primaryPurple.withValues(alpha: 0.25), width: 1),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          const Icon(Icons.list_alt_rounded,
              size: 18, color: AppTheme.primaryPurple),
          const SizedBox(width: 8),
          Expanded(
              child: Text(listName,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700))),
        ]),
        const SizedBox(height: 4),
        Text('Invited by: $invitedByName',
            style: TextStyle(
                fontSize: 12,
                color: Theme.of(context)
                    .colorScheme
                    .onSurface
                    .withValues(alpha: 0.55))),
        const SizedBox(height: 12),
        Row(children: [
          Expanded(
              child: OutlinedButton(
            onPressed: isLoading ? null : onDecline,
            style: OutlinedButton.styleFrom(
              foregroundColor: Colors.red,
              side: const BorderSide(color: Colors.red),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text('Decline',
                style: TextStyle(fontWeight: FontWeight.w600)),
          )),
          const SizedBox(width: 10),
          Expanded(
              child: FilledButton(
            onPressed: isLoading ? null : onAccept,
            style: FilledButton.styleFrom(
              backgroundColor: AppTheme.primaryPurple,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
              padding: const EdgeInsets.symmetric(vertical: 10),
            ),
            child: const Text('Accept',
                style: TextStyle(fontWeight: FontWeight.w600)),
          )),
        ]),
      ]),
    );
  }
}
