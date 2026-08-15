import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../utils/date_utils.dart';
import '../utils/subscription_limits.dart';
import '../providers/shopping_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/user_avatar_widget.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late TextEditingController _nameController;
  bool _isEditing = false;
  bool _isSaving = false;
  String? _selectedGender;

  static const _genderLabels = {'male': 'Male', 'female': 'Female', 'other': 'Other'};
  static const _genderIcons = {
    'male': Icons.face_rounded,
    'female': Icons.face_3_rounded,
    'other': Icons.person_rounded,
  };
  static const _genderColors = {
    'male': AppTheme.maleBlue,
    'female': AppTheme.femalePink,
    'other': AppTheme.primaryPurple,
  };

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().userProfile;
    _nameController = TextEditingController(text: user?.displayName ?? '');
    _selectedGender = user?.gender;
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final newName = _nameController.text.trim();
    if (newName.isEmpty) return;
    setState(() => _isSaving = true);

    await context
        .read<AuthProvider>()
        .updateProfile(displayName: newName, gender: _selectedGender);

    if (!mounted) return;
    setState(() {
      _isSaving = false;
      _isEditing = false;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Profile updated!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AuthProvider>(
      builder: (context, auth, _) {
        final user = auth.userProfile;

        if (user == null) {
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        return Scaffold(
          appBar: AppBar(
            title: const Text('My Profile',
                style: TextStyle(fontWeight: FontWeight.w700)),
            actions: [
              Padding(
                padding: const EdgeInsets.only(right: 12),
                child: _isEditing
                    ? FilledButton.icon(
                        onPressed: _isSaving ? null : _save,
                        icon: _isSaving
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.check_rounded, size: 18),
                        label: Text(_isSaving ? 'Saving…' : 'Save'),
                        style: FilledButton.styleFrom(
                          backgroundColor: AppTheme.primaryPurple,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      )
                    : OutlinedButton.icon(
                        onPressed: () => setState(() => _isEditing = true),
                        icon: const Icon(Icons.edit_rounded, size: 18),
                        label: const Text('Edit'),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: AppTheme.primaryPurple,
                          side: const BorderSide(
                              color: AppTheme.primaryPurple, width: 1.5),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 8),
                          textStyle: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
              ),
            ],
          ),
          body: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              // ── Avatar ──
              Center(
                child: Stack(
                  children: [
                    UserAvatarWidget(
                      displayName: user.displayName,
                      photoUrl: user.photoUrl,
                      gender: _isEditing ? _selectedGender : user.gender,
                      radius: 52,
                    ),
                    Positioned(
                      bottom: 0,
                      right: 0,
                      child: GestureDetector(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text(
                                '📸 Custom photo upload coming soon!\n'
                                'Your Google profile photo is used automatically.',
                              ),
                              backgroundColor: AppTheme.primaryPurple,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          duration: const Duration(seconds: 3),
                        ),
                      );
                    },
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: AppTheme.primaryPurple,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.camera_alt_rounded,
                        size: 16,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ── Display name ──
          _SectionCard(
            title: 'Display Name',
            child: _isEditing
                ? TextField(
                    controller: _nameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: InputDecoration(
                      hintText: 'Your name',
                      suffixIcon: IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => _nameController.clear(),
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(10),
                        borderSide: const BorderSide(
                          color: AppTheme.primaryPurple,
                          width: 1.5,
                        ),
                      ),
                    ),
                  )
                : _InfoRow(
                    icon: Icons.person_rounded,
                    label: user.displayName,
                  ),
          ),
          const SizedBox(height: 12),

          // ── Gender ──
          _SectionCard(
            title: 'Gender',
            child: _isEditing
                ? _GenderSelector(
                    selected: _selectedGender,
                    onChanged: (g) => setState(() => _selectedGender = g),
                  )
                : _InfoRow(
                    icon: _genderIcons[user.gender] ?? Icons.person_rounded,
                    label: _genderLabels[user.gender] ?? 'Not specified',
                    color: _genderColors[user.gender],
                  ),
          ),
          const SizedBox(height: 12),

          // ── Email ──
          _SectionCard(
            title: 'Email',
            child: _InfoRow(
              icon: Icons.email_rounded,
              label: user.email ?? '',
            ),
          ),
          const SizedBox(height: 12),

          // ── Subscription plan ──
          _SectionCard(
            title: 'Plan',
            child: _PlanRow(tier: user.subscriptionTier),
          ),
          const SizedBox(height: 24),

          // ── Stats ──
          Selector<ShoppingProvider, (int, int, int, int)>(
            selector: (_, shopping) => (
              shopping.allItems.where((i) => i.addedBy == user.id).length,
              shopping.completedCount,
              shopping.pendingCount,
              shopping.members.length,
            ),
            builder: (_, stats, __) {
              return Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Items Added',
                          value: stats.$1.toString(),
                          icon: Icons.add_shopping_cart_rounded,
                          color: AppTheme.primaryPurple,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Completed',
                          value: stats.$2.toString(),
                          icon: Icons.check_circle_rounded,
                          color: AppTheme.accentTeal,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: _StatCard(
                          label: 'Pending',
                          value: stats.$3.toString(),
                          icon: Icons.radio_button_unchecked_rounded,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _StatCard(
                          label: 'Members',
                          value: stats.$4.toString(),
                          icon: Icons.group_rounded,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 32),

          // ── Member since ──
          Center(
            child: Text(
              'Member since ${AppDateUtils.formatMonthYear(user.createdAt)}',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: Theme.of(context).brightness == Brightness.dark
                    ? Colors.white54 : const Color(0xFF666666),
              ),
            ),
          ),
        ],
      ),
    );
      },
    );
  }
}

// ── Gender selector widget ──
class _GenderSelector extends StatelessWidget {
  final String? selected;
  final ValueChanged<String?> onChanged;

  static const _options = [
    ('male', 'Male', Icons.face_rounded, AppTheme.maleBlue, AppTheme.maleBlueBg),
    ('female', 'Female', Icons.face_3_rounded, AppTheme.femalePink, AppTheme.femalePinkBg),
    ('other', 'Other', Icons.person_rounded, AppTheme.primaryPurple, Color(0xFFEDE7F6)),
  ];

  const _GenderSelector({required this.selected, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: _options.map((opt) {
        final (value, label, icon, fgColor, bgColor) = opt;
        final isSelected = selected == value;
        return Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 3),
            child: GestureDetector(
              onTap: () => onChanged(isSelected ? null : value),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: isSelected ? bgColor : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: isSelected
                        ? fgColor.withValues(alpha: 0.5)
                        : Colors.grey.withValues(alpha: 0.3),
                    width: isSelected ? 1.5 : 1,
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(icon, size: 22, color: isSelected ? fgColor : Colors.grey),
                    const SizedBox(height: 4),
                    Text(
                      label,
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: isSelected
                            ? FontWeight.w700
                            : FontWeight.w400,
                        color: isSelected ? fgColor : Colors.grey,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _SectionCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title.toUpperCase(),
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w800,
            letterSpacing: 1.2,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest
                .withValues(alpha: 0.4),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.15),
            ),
          ),
          child: child,
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;
  const _InfoRow({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: color ?? AppTheme.primaryPurple),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}

class _PlanRow extends StatelessWidget {
  final SubscriptionTier tier;
  const _PlanRow({required this.tier});

  @override
  Widget build(BuildContext context) {
    final label = SubscriptionLimits.tierBadgeLabel(tier);
    final name = SubscriptionLimits.tierDisplayName(tier);
    final maxOwned = SubscriptionLimits.maxOwnedSharedLists(tier);
    final maxMembers = SubscriptionLimits.maxMembersPerList(tier);
    final histDays = SubscriptionLimits.historyDays(tier);
    final histLabel = histDays == -1 ? 'Unlimited history' : '$histDays days history';

    // Tier-specific colours
    final Color badgeColor;
    final Color bgColor;
    switch (tier) {
      case SubscriptionTier.family:
        badgeColor = const Color(0xFF1565C0);
        bgColor = const Color(0xFFE3F2FD);
      case SubscriptionTier.group:
        badgeColor = const Color(0xFF2E7D32);
        bgColor = const Color(0xFFE8F5E9);
      case SubscriptionTier.free:
        badgeColor = const Color(0xFF5C5C8A);
        bgColor = const Color(0xFFEDE7F6);
    }

    return Row(
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: bgColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: badgeColor.withValues(alpha: 0.4)),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: badgeColor,
              letterSpacing: 0.5,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                name,
                style: const TextStyle(
                    fontSize: 15, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 2),
              Text(
                '$maxOwned shared list · $maxMembers members · $histLabel',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).brightness == Brightness.dark
                      ? Colors.white60 : const Color(0xFF555555),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  const _StatCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color.withValues(alpha: 0.75),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}