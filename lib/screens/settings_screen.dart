import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../models/user_profile.dart';
import '../providers/auth_provider.dart';
import '../providers/home_screen_provider.dart';
import '../theme/app_theme.dart';
import '../utils/app_dialogs.dart';
import '../utils/constants.dart';
import 'settings/widgets/delete_account_dialog.dart';
import 'settings/widgets/feedback_tile.dart';
import 'settings/widgets/notification_tile.dart';
import 'settings/widgets/theme_tile.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings',
            style: TextStyle(fontWeight: FontWeight.w700)),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ── Account ──
          const _SectionHeader(label: 'Account'),
          Selector<AuthProvider, (String, String)>(
            selector: (_, auth) => (
              auth.userProfile?.displayName ?? 'User',
              auth.userProfile?.email ?? '',
            ),
            builder: (_, userData, __) => _SettingsTile(
              icon: Icons.person_rounded,
              iconColor: AppTheme.primaryPurple,
              title: userData.$1,
              subtitle: userData.$2,
            ),
          ),
          const SizedBox(height: 4),
          _SettingsTile(
            icon: Icons.logout_rounded,
            iconColor: Colors.red.shade400,
            title: 'Sign Out',
            subtitle: 'Sign out of your account',
            onTap: () {
              final auth = context.read<AuthProvider>();
              AppDialogs.confirmSignOut(context, auth);
            },
          ),
          const SizedBox(height: 4),
          _SettingsTile(
            icon: Icons.delete_forever_rounded,
            iconColor: Colors.red.shade700,
            title: 'Delete Account',
            subtitle: 'Permanently delete your account and all data',
            trailing: Icon(Icons.chevron_right_rounded,
                size: 18, color: Colors.red.shade300),
            onTap: () {
              final auth = context.read<AuthProvider>();
              _confirmDeleteAccount(context, auth);
            },
          ),
          const SizedBox(height: 24),

          // ── View Preferences ──
          const _SectionHeader(label: 'VIEW PREFERENCES'),
          Consumer<HomeScreenProvider>(
            builder: (context, homeState, _) {
              final currentTab = homeState.defaultTab;
              final label = currentTab == MenuTab.myList ? 'My List' : 'Shared';

              return _SettingsTile(
                icon: Icons.home_rounded,
                iconColor: AppTheme.primaryPurple,
                title: 'Default List',
                subtitle: label,
                onTap: () => _showDefaultListPicker(context, homeState),
              );
            },
          ),
          const SizedBox(height: 4),
          Consumer<HomeScreenProvider>(
            builder: (context, homeState, _) {
              String viewLabel;
              switch (homeState.defaultView) {
                case ViewMode.list:
                  viewLabel = 'List';
                  break;
                case ViewMode.categorised:
                  viewLabel = 'Category';
                  break;
                case ViewMode.timeline:
                  viewLabel = 'Timeline';
                  break;
              }

              return _SettingsTile(
                icon: Icons.view_list_rounded,
                iconColor: AppTheme.primaryPurple,
                title: 'Default View',
                subtitle: viewLabel,
                onTap: () => _showDefaultViewPicker(context, homeState),
              );
            },
          ),
          const SizedBox(height: 24),

          // ── Categories ──
          const _SectionHeader(label: 'CATEGORIES'),
          _SettingsTile(
            icon: Icons.category_rounded,
            iconColor: AppTheme.accentTeal,
            title: 'Manage Categories',
            subtitle: 'Create and manage custom shopping categories',
            trailing: const Icon(Icons.chevron_right_rounded, size: 18),
            onTap: () => context.push(AppConstants.routeManageCategories),
          ),
          const SizedBox(height: 24),

          // ── Appearance ──
          const _SectionHeader(label: 'Appearance'),
          const ThemeTile(),
          const SizedBox(height: 24),

          // ── Notifications ──
          const _SectionHeader(label: 'Notifications'),
          const NotificationTile(),
          const SizedBox(height: 24),

          // ── Data ──
          const _SectionHeader(label: 'Data'),
          _SettingsTile(
            icon: Icons.sync_rounded,
            iconColor: AppTheme.accentTeal,
            title: 'Sync',
            subtitle: 'Data syncs in real time via Firebase',
            isInfo: true,
            statusLabel: 'Live',
            statusColor: AppTheme.accentTeal,
          ),
          const SizedBox(height: 4),
          _SettingsTile(
            icon: Icons.storage_rounded,
            iconColor: Colors.grey.shade600,
            title: 'Local Cache',
            subtitle: 'SQLite local storage enabled',
            isInfo: true,
            statusLabel: 'Enabled',
            statusColor: Colors.grey,
          ),
          const SizedBox(height: 24),

          // ── About ──
          const _SectionHeader(label: 'About'),
          _SettingsTile(
            icon: Icons.info_outline_rounded,
            iconColor: AppTheme.primaryPurple,
            title: AppConstants.appName,
            subtitle: 'Tap to learn more about ShopShare',
            trailing: const Icon(Icons.open_in_new_rounded, size: 16),
            onTap: () => launchUrl(
              Uri.parse('https://your-explorer-hub.github.io/shopshare/'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: 4),
          _SettingsTile(
            icon: Icons.policy_rounded,
            iconColor: Colors.grey.shade500,
            title: 'Privacy Policy',
            subtitle: 'View our privacy policy',
            trailing: const Icon(Icons.open_in_new_rounded, size: 16),
            onTap: () => launchUrl(
              Uri.parse(
                  'https://your-explorer-hub.github.io/shopshare/privacy.html'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: 4),
          _SettingsTile(
            icon: Icons.article_rounded,
            iconColor: Colors.grey.shade500,
            title: 'Terms of Service',
            subtitle: 'View terms and conditions',
            trailing: const Icon(Icons.open_in_new_rounded, size: 16),
            onTap: () => launchUrl(
              Uri.parse(
                  'https://your-explorer-hub.github.io/shopshare/terms.html'),
              mode: LaunchMode.externalApplication,
            ),
          ),
          const SizedBox(height: 24),

          // ── Support ──
          const _SectionHeader(label: 'Support'),
          Selector<AuthProvider, UserProfile?>(
            selector: (_, auth) => auth.userProfile,
            builder: (_, userProfile, __) => FeedbackTile(userProfile: userProfile),
          ),
          const SizedBox(height: 40),

          Center(
            child: Text(
              '${AppConstants.appName} v${AppConstants.appVersion}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white54
                    : const Color(0xFF666666),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _confirmDeleteAccount(BuildContext context, AuthProvider auth) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => DeleteAccountDialog(auth: auth),
    );
  }

  void _showDefaultListPicker(BuildContext context, HomeScreenProvider homeState) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              'Default List',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.person_rounded),
              title: const Text('My List'),
              trailing: homeState.defaultTab == MenuTab.myList
                  ? const Icon(Icons.check_rounded, color: AppTheme.primaryPurple)
                  : null,
              onTap: () {
                homeState.setDefaultTab(MenuTab.myList);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_rounded),
              title: const Text('Shared'),
              trailing: homeState.defaultTab == MenuTab.sharedList
                  ? const Icon(Icons.check_rounded, color: AppTheme.primaryPurple)
                  : null,
              onTap: () {
                homeState.setDefaultTab(MenuTab.sharedList);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  void _showDefaultViewPicker(BuildContext context, HomeScreenProvider homeState) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 16),
            Text(
              'Default View',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
            ),
            const SizedBox(height: 8),
            ListTile(
              leading: const Icon(Icons.list_rounded),
              title: const Text('List'),
              trailing: homeState.defaultView == ViewMode.list
                  ? const Icon(Icons.check_rounded, color: AppTheme.primaryPurple)
                  : null,
              onTap: () {
                homeState.setDefaultView(ViewMode.list);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.category_rounded),
              title: const Text('Category'),
              trailing: homeState.defaultView == ViewMode.categorised
                  ? const Icon(Icons.check_rounded, color: AppTheme.primaryPurple)
                  : null,
              onTap: () {
                homeState.setDefaultView(ViewMode.categorised);
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.timeline_rounded),
              title: const Text('Timeline'),
              trailing: homeState.defaultView == ViewMode.timeline
                  ? const Icon(Icons.check_rounded, color: AppTheme.primaryPurple)
                  : null,
              onTap: () {
                homeState.setDefaultView(ViewMode.timeline);
                Navigator.pop(context);
              },
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

// ── Section header ────────────────────────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w800,
          letterSpacing: 1.1,
          color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
        ),
      ),
    );
  }
}

// ── Settings tile ─────────────────────────────────────────────────────────────

class _SettingsTile extends StatelessWidget {
  final IconData? icon;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;
  final bool isInfo;
  final String? statusLabel;
  final Color? statusColor;

  const _SettingsTile({
    this.icon,
    this.iconColor,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
    this.isInfo = false,
    this.statusLabel,
    this.statusColor,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;

    // For info tiles, use a non-interactive Container
    if (isInfo) {
      return Container(
        margin: const EdgeInsets.only(bottom: 4),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.surfaceContainerHighest.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: cs.outline.withValues(alpha: 0.08),
            style: BorderStyle.solid,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: (iconColor ?? cs.primary).withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, size: 19, color: iconColor ?? cs.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Theme.of(context).brightness == Brightness.dark
                          ? Colors.white60
                          : const Color(0xFF555555),
                    ),
                  ),
                ],
              ),
            ),
            if (statusLabel != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: (statusColor ?? Colors.grey).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  statusLabel!,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: statusColor ?? Colors.grey,
                  ),
                ),
              ),
          ],
        ),
      );
    }

    // For interactive tiles, use ListTile
    return Container(
      margin: const EdgeInsets.only(bottom: 4),
      decoration: BoxDecoration(
        color: cs.surfaceContainerHighest.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cs.outline.withValues(alpha: 0.12)),
      ),
      child: ListTile(
        leading: icon != null
            ? Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: (iconColor ?? cs.primary).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, size: 19, color: iconColor ?? cs.primary),
              )
            : null,
        title: Text(title,
            style:
                const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
        subtitle: Text(subtitle,
            style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white60
                    : const Color(0xFF555555))),
        trailing: trailing,
        onTap: onTap,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      ),
    );
  }
}
