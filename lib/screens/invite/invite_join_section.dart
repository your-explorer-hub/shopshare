import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/invite_screen_provider.dart';
import '../../theme/app_theme.dart';
import 'widgets/section_label.dart';

class InviteJoinSection extends StatelessWidget {
  final TextEditingController joinController;
  final VoidCallback onJoin;

  const InviteJoinSection({
    super.key,
    required this.joinController,
    required this.onJoin,
  });

  @override
  Widget build(BuildContext context) {
    final inviteState = context.watch<InviteScreenProvider>();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const InviteSectionLabel(label: 'Join a Shared List'),
        Text("Have an invite link? Paste it here to join the shared list.",
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white60 : const Color(0xFF555555),
                height: 1.5)),
        const SizedBox(height: 10),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: TextField(
                controller: joinController,
                decoration: InputDecoration(
                  hintText: 'Paste invite link or code…',
                  prefixIcon: const Icon(Icons.link_rounded, size: 20),
                  errorText: inviteState.joinError,
                  filled: true,
                  fillColor: Theme.of(context)
                      .colorScheme
                      .surfaceContainerHighest
                      .withValues(alpha: 0.4),
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none),
                  enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                          color: Theme.of(context)
                              .colorScheme
                              .outline
                              .withValues(alpha: 0.2))),
                  focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(
                          color: AppTheme.accentTeal, width: 1.5)),
                  errorBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide:
                          const BorderSide(color: Colors.red, width: 1.5)),
                  contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 14),
                ),
                onSubmitted: (_) => onJoin(),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              height: 50,
              child: FilledButton(
                onPressed: inviteState.isJoining ? null : onJoin,
                style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.accentTeal,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                ),
                child: inviteState.isJoining
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Text('Join',
                        style: TextStyle(fontWeight: FontWeight.w600)),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
