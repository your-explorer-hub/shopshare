import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import '../models/member.dart';
import '../models/shopping_list.dart';
import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/shopping_provider.dart';
import '../providers/invite_screen_provider.dart';
import '../services/firestore_service.dart';
import '../services/invite_service.dart';
import '../shared/dialogs/destructive_dialog.dart';
import '../shared/dialogs/rename_list_dialog.dart';
import '../theme/app_theme.dart';
import '../utils/constants.dart';
import '../utils/subscription_limits.dart';
import '../utils/validators.dart';
import 'invite/invite_owned_section.dart';
import 'invite/invite_joined_section.dart';
import 'invite/invite_join_section.dart';
import 'invite/invite_pending_section.dart';
import 'invite/widgets/create_shared_list_dialog.dart';

class InviteScreen extends StatefulWidget {
  const InviteScreen({super.key});
  @override
  State<InviteScreen> createState() => _InviteScreenState();
}

class _InviteScreenState extends State<InviteScreen> {
  final _joinController = TextEditingController();
  final _emailInviteController = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = context.read<AuthProvider>().userProfile;
      if (user != null) {
        context.read<ShoppingProvider>().loadJoinedSharedLists(user.id);
      }
    });
  }

  @override
  void dispose() {
    _joinController.dispose();
    _emailInviteController.dispose();
    super.dispose();
  }

  Future<String?> _getOrCreateShortCode(
      BuildContext context, ShoppingList list, String inviterName) async {
    final user = context.read<AuthProvider>().userProfile;
    if (user == null) return null;
    try {
      final shortCode = await FirestoreService.instance.createLinkInvite(
        listId: list.id,
        invitedByUid: user.id,
        invitedByName: inviterName,
        ownerTier: user.subscriptionTier,
      );
      return shortCode;
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))));
      }
      return null;
    }
  }

  Future<void> _shareWhatsApp(BuildContext context, String n, ShoppingList list) async {
    final shortCode = await _getOrCreateShortCode(context, list, n);
    if (shortCode == null) return;
    final ok = await InviteService.instance.shareViaWhatsApp(
        inviterName: n, listName: list.name, shortCode: shortCode);
    if (!ok && mounted) ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('WhatsApp not available on this device.')));
  }

  Future<void> _shareEmail(BuildContext context, String n, ShoppingList list) async {
    final shortCode = await _getOrCreateShortCode(context, list, n);
    if (shortCode == null) return;
    final ok = await InviteService.instance.shareViaEmail(
        inviterName: n, listName: list.name, shortCode: shortCode);
    if (!ok && mounted) ScaffoldMessenger.of(context)
        .showSnackBar(const SnackBar(content: Text('No email app available.')));
  }

  Future<void> _shareSystem(BuildContext context, String n, ShoppingList list) async {
    final shortCode = await _getOrCreateShortCode(context, list, n);
    if (shortCode == null) return;
    await InviteService.instance.shareViaSystem(
        inviterName: n, listName: list.name, shortCode: shortCode);
  }

  Future<void> _copyInviteLink(BuildContext context, ShoppingList list, String n) async {
    final shortCode = await _getOrCreateShortCode(context, list, n);
    if (shortCode == null) return;
    final link = InviteService.instance.buildShortLink(shortCode);
    await Clipboard.setData(ClipboardData(text: link));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(children: [
            const Icon(Icons.check_circle_rounded, color: Colors.white, size: 16),
            const SizedBox(width: 8),
            Expanded(child: Text('Invite link copied! ($shortCode)')),
          ]),
          backgroundColor: AppTheme.accentTeal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.fromLTRB(12, 0, 12, 20),
        ),
      );
    }
  }

  Future<void> _sendEmailInvite(BuildContext context, {required String listId}) async {
    final inviteState = context.read<InviteScreenProvider>();
    final email = _emailInviteController.text.trim();
    if (!Validators.isValidEmail(email)) {
      inviteState.setEmailInviteError('Please enter a valid email address.');
      return;
    }
    final user = context.read<AuthProvider>().userProfile;
    if (user == null) return;
    final shopping = context.read<ShoppingProvider>();
    inviteState.setSendingInvite(true);
    final error = await shopping.sendEmailInvite(
      listId: listId,
      invitedByUid: user.id,
      invitedByName: user.displayName,
      invitedByEmail: user.email ?? '',
      recipientEmail: email,
      ownerTier: user.subscriptionTier,
    );
    if (!mounted) return;
    inviteState.setSendingInvite(false);
    if (error != null) {
      inviteState.setEmailInviteError(error);
    } else {
      _emailInviteController.clear();
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text('Invite sent to $email')));
    }
  }

  /// Extracts the 6-char short code from either a full invite URL or a raw code.
  String? _extractShortCode(String input) {
    final trimmed = input.trim();
    if (trimmed.isEmpty) return null;
    // Try to parse as URL and extract last path segment
    try {
      final uri = Uri.parse(trimmed);
      if (uri.pathSegments.isNotEmpty) {
        final last = uri.pathSegments.last;
        if (last.isNotEmpty) return last.toUpperCase();
      }
    } catch (_) {}
    // Otherwise treat as raw code
    return trimmed.toUpperCase();
  }

  Future<void> _joinByLink(BuildContext context) async {
    final inviteState = context.read<InviteScreenProvider>();
    final input = _joinController.text.trim();
    if (input.isEmpty) {
      inviteState.setJoinError('Please enter an invite link or code.');
      return;
    }
    final shortCode = _extractShortCode(input);
    if (shortCode == null) {
      inviteState.setJoinError('Invalid invite link or code.');
      return;
    }
    final user = context.read<AuthProvider>().userProfile;
    if (user == null) return;
    inviteState.setJoining(true);

    try {
      // Resolve short code → invite data
      final inviteData = await FirestoreService.instance.getInviteByShortCode(shortCode);
      if (!mounted) return;
      if (inviteData == null) {
        inviteState.setJoinError('Invite link is invalid or has expired.');
        return;
      }
      final listId = inviteData['listId'] as String? ?? '';
      if (listId.isEmpty) {
        inviteState.setJoinError('Could not find the list for this invite.');
        return;
      }
      // Join the list
      final shopping = context.read<ShoppingProvider>();
      final error = await shopping.joinListById(listId,
          userId: user.id, displayName: user.displayName,
          email: user.email ?? '', photoUrl: user.photoUrl,
          joinerTier: user.subscriptionTier);
      if (!mounted) return;
      inviteState.setJoining(false);
      if (error != null) {
        inviteState.setJoinError(error);
      } else {
        _joinController.clear();
        shopping.loadJoinedSharedLists(user.id);
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Joined list successfully!')));
      }
    } catch (e) {
      if (!mounted) return;
      inviteState.setJoinError(e.toString().replaceFirst('Exception: ', ''));
    }
  }

  Future<void> _acceptInvite(BuildContext context, Map<String, dynamic> invite) async {
    final user = context.read<AuthProvider>().userProfile;
    if (user == null) return;
    final shopping = context.read<ShoppingProvider>();
    final maxJoined = SubscriptionLimits.maxJoinedSharedLists(user.subscriptionTier);
    if (shopping.joinedSharedLists.length >= maxJoined) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          'You have already joined $maxJoined shared list(s) '
          '(${SubscriptionLimits.tierDisplayName(user.subscriptionTier)} limit). '
          'Upgrade to join more.')));
      return;
    }
    final inviteId = invite['id'] as String;
    final listName = invite['listName'] as String? ?? 'the list';
    final error = await shopping.acceptInvite(
        inviteCode: inviteId, userId: user.id,
        displayName: user.displayName, photoUrl: user.photoUrl);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      shopping.loadJoinedSharedLists(user.id);
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("You've joined $listName!")));
    }
  }

  Future<void> _declineInvite(BuildContext context, Map<String, dynamic> invite) async {
    final shopping = context.read<ShoppingProvider>();
    final inviteId = invite['id'] as String;
    final error = await shopping.declineInvite(inviteId);
    if (!mounted) return;
    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(error)));
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Invitation declined.')));
    }
  }

  Future<void> _confirmRemoveMember(
      BuildContext context, Member member, String listName) async {
    final confirmed = await DestructiveDialog.show(
      context: context,
      title: 'Remove Member',
      message: 'Remove ${member.displayName} from "$listName"?\n\n'
          'They will lose access to this shared list.',
      confirmText: 'Remove',
    );

    if (confirmed != true || !mounted) return;
    await context.read<ShoppingProvider>().removeMember(member);
  }

  Future<void> _deleteList(ShoppingList list) async {
    final shopping = context.read<ShoppingProvider>();
    final userProfile = context.read<AuthProvider>().userProfile;

    if (userProfile == null) return;

    // Show confirmation dialog
    final confirmed = await DestructiveDialog.show(
      context: context,
      title: 'Delete "${list.name}"?',
      message:
          'This list and all its items will be permanently deleted for all ${list.memberIds.length} member${list.memberIds.length != 1 ? 's' : ''}. This action cannot be undone.',
      confirmText: 'Delete List',
      cancelText: 'Cancel',
    );

    if (confirmed != true) return;

    // Collapse the card immediately for better UX
    context.read<InviteScreenProvider>().toggleExpandedList(null);

    // Perform deletion
    final error = await shopping.deleteSharedList(
      listId: list.id,
      userId: userProfile.id,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete list: $error'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('List "${list.name}" deleted successfully'),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _renameList(ShoppingList list) async {
    final shopping = context.read<ShoppingProvider>();
    final userProfile = context.read<AuthProvider>().userProfile;

    if (userProfile == null) return;

    // Show rename dialog
    final newName = await RenameListDialog.show(
      context: context,
      currentName: list.name,
      listType: list.type,
    );

    if (newName == null || !mounted) return; // User cancelled or no change

    // Perform rename
    final error = await shopping.renameList(
      listId: list.id,
      newName: newName,
      userId: userProfile.id,
    );

    if (!mounted) return;

    if (error != null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to rename list: $error'),
          backgroundColor: Colors.red.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, size: 20, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(child: Text('List renamed to "$newName"')),
            ],
          ),
          backgroundColor: Colors.green.shade700,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Selector<AuthProvider, (UserProfile?, SubscriptionTier)>(
      selector: (_, auth) => (
        auth.userProfile,
        auth.userProfile?.subscriptionTier ?? SubscriptionTier.free,
      ),
      builder: (_, authData, __) {
        final userProfile = authData.$1;
        final tier = authData.$2;
        final shopping = context.watch<ShoppingProvider>();

        if (userProfile == null) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('Manage Lists',
                style: TextStyle(fontWeight: FontWeight.w700)),
          ),
          body: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
            children: [
              // Section 1: Owned Lists
              InviteOwnedSection(
                userProfile: userProfile,
                tier: tier,
                emailInviteController: _emailInviteController,
                onShareWhatsApp: (list) => _shareWhatsApp(context, userProfile.displayName, list),
                onShareEmail: (list) => _shareEmail(context, userProfile.displayName, list),
                onShareSystem: (list) => _shareSystem(context, userProfile.displayName, list),
                onCopyInviteLink: (list) => _copyInviteLink(context, list, userProfile.displayName),
                onSendInvite: (listId) => _sendEmailInvite(context, listId: listId),
                onRemoveMember: (m, listName) => _confirmRemoveMember(context, m, listName),
                onDeleteList: _deleteList,
                onRenameList: _renameList,
                onCreateList: () => CreateSharedListDialog.show(context),
              ),

              const SizedBox(height: 8),

              // Section 2: Joined Lists
              InviteJoinedSection(
                currentUserId: userProfile.id,
                activeListId: shopping.listId,
                onSwitchToList: (list) {
                  if (shopping.listId != list.id) {
                    shopping.switchList(list.id, userProfile.id);
                  }
                  Navigator.of(context).pop();
                },
              ),

              const SizedBox(height: 28),

              // Section 3: Join by Link
              InviteJoinSection(
                joinController: _joinController,
                onJoin: () => _joinByLink(context),
              ),

              const SizedBox(height: 28),

              // Section 4: Pending Invites
              InvitePendingSection(
                onAccept: (invite) => _acceptInvite(context, invite),
                onDecline: (invite) => _declineInvite(context, invite),
              ),
            ],
          ),
        );
      },
    );
  }
}
