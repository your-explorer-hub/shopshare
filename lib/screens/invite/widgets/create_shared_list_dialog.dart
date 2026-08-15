import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/auth_provider.dart';
import '../../../providers/shopping_provider.dart';
import '../../../theme/app_theme.dart';

class CreateSharedListDialog {
  static Future<void> show(BuildContext context) async {
    final shopping = context.read<ShoppingProvider>();
    final profile = context.read<AuthProvider>().userProfile;
    if (profile == null) return;

    final ownedShared = shopping.availableLists
        .where((l) => l.isShared && l.ownerId == profile.id)
        .toList();

    final controller = TextEditingController();
    String? error;

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setLocal) => AlertDialog(
          title: const Text('Create Shared List',
              style: TextStyle(fontWeight: FontWeight.w800)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                  'Create a new shared list. Invite others after it is created.',
                  style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(ctx)
                          .colorScheme
                          .onSurface
                          .withValues(alpha: 0.6),
                      height: 1.5)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                autofocus: true,
                textCapitalization: TextCapitalization.words,
                decoration: InputDecoration(
                  labelText: 'List name',
                  hintText: 'e.g. Smith Family, Holidays, Kitchen',
                  errorText: error,
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx),
                child: const Text('Cancel')),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: AppTheme.primaryPurple),
              onPressed: () async {
                final rawName = controller.text.trim();
                if (rawName.isEmpty) {
                  setLocal(() => error = 'Please enter a name.');
                  return;
                }
                final name = rawName.replaceAll(' ', '_');

                // ── Mutual exclusivity check ──────────────────────────
                // The new list will start with exactly {ownerId} as its
                // only accepted member. If any existing owned shared list
                // also has exactly that same single-member set, block it.
                for (final existing in ownedShared) {
                  final existingMembers =
                      (existing.memberIds.toList()..sort());
                  final newMembers = [profile.id]..sort();
                  if (existingMembers.length == newMembers.length &&
                      existingMembers.join(',') == newMembers.join(',')) {
                    setLocal(() => error =
                        'A list with these exact members already exists: '
                        '"${existing.name}". '
                        'Please use a different member combination.');
                    return;
                  }
                }

                Navigator.pop(ctx);
                final err = await shopping.createSharedList(
                    customName: name,
                    ownerId: profile.id,
                    ownerName: profile.displayName,
                    ownerEmail: profile.email ?? '',
                    ownerTier: profile.subscriptionTier);
                if (err != null && context.mounted) {
                  ScaffoldMessenger.of(context)
                      .showSnackBar(SnackBar(content: Text(err)));
                }
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
    controller.dispose();
  }
}
