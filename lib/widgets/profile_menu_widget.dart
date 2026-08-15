import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/shopping_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_dialogs.dart';
import '../utils/constants.dart';
import 'user_avatar_widget.dart';

class ProfileMenuWidget extends StatelessWidget {
  const ProfileMenuWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final user = auth.userProfile;
    if (user == null) return const SizedBox.shrink();

    return PopupMenuButton<_MenuAction>(
      offset: const Offset(0, 48),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      onSelected: (action) => _handleAction(context, action, auth),
      itemBuilder: (_) => [
        // ── User header (non-interactive) ──
        PopupMenuItem<_MenuAction>(
          enabled: false,
          child: _UserHeader(
            displayName: user.displayName,
            email: user.email ?? '',
            photoUrl: user.photoUrl,
            gender: user.gender,
          ),
        ),
        const PopupMenuDivider(),
        _menuItem(
          action: _MenuAction.profile,
          icon: Icons.person_rounded,
          label: 'My Profile',
        ),
        _menuItem(
          action: _MenuAction.invite,
          icon: Icons.group_rounded,
          label: 'Manage Lists',
          color: AppTheme.accentTeal,
        ),
        _menuItem(
          action: _MenuAction.settings,
          icon: Icons.settings_rounded,
          label: 'Settings',
        ),
        const PopupMenuDivider(),
        _menuItem(
          action: _MenuAction.signOut,
          icon: Icons.logout_rounded,
          label: 'Sign Out',
          color: Colors.red.shade400,
        ),
      ],
      // Use UserAvatarWidget — handles network errors + gender fallback
      child: UserAvatarWidget(
        displayName: user.displayName,
        photoUrl: user.photoUrl,
        gender: user.gender,
        radius: 18,
      ),
    );
  }

  PopupMenuItem<_MenuAction> _menuItem({
    required _MenuAction action,
    required IconData icon,
    required String label,
    Color? color,
  }) {
    return PopupMenuItem<_MenuAction>(
      value: action,
      child: Row(
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 12),
          Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  void _handleAction(
    BuildContext context,
    _MenuAction action,
    AuthProvider auth,
  ) {
    switch (action) {
      case _MenuAction.profile:
        context.push(AppConstants.routeProfile);
        break;
      case _MenuAction.invite:
        // Remember the personal list to restore on return, then push.
        final sp = context.read<ShoppingProvider>();
        final uid = context.read<AuthProvider>().userProfile?.id ?? '';
        final personalListId = sp.availableLists
            .where((l) => !l.isShared)
            .map((l) => l.id)
            .firstOrNull;
        context.push(AppConstants.routeInvite).then((_) {
          // Cancel the InviteScreen members subscription so _members reverts
          // to the active list's members (prevents global state pollution).
          sp.cancelInviteScreenMembersSubscription();
          // Restore the personal list when returning from InviteScreen.
          if (personalListId != null && sp.listId != personalListId) {
            sp.switchList(personalListId, uid);
          }
        });
        break;
      case _MenuAction.settings:
        context.push(AppConstants.routeSettings);
        break;
      case _MenuAction.signOut:
        AppDialogs.confirmSignOut(context, auth);
        break;
    }
  }

}

enum _MenuAction { profile, invite, settings, signOut }

class _UserHeader extends StatelessWidget {
  final String displayName;
  final String email;
  final String? photoUrl;
  final String? gender;

  const _UserHeader({
    required this.displayName,
    required this.email,
    this.photoUrl,
    this.gender,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          UserAvatarWidget(
            displayName: displayName,
            photoUrl: photoUrl,
            gender: gender,
            radius: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  displayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  email,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}