import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../providers/notification_provider.dart';
import 'theme_tile.dart';

class NotificationTile extends StatelessWidget {
  const NotificationTile({super.key});

  @override
  Widget build(BuildContext context) {
    final notifProv = context.watch<NotificationProvider>();

    return TileShell(
      icon: notifProv.isMuted
          ? Icons.notifications_off_rounded
          : Icons.notifications_active_rounded,
      iconColor: notifProv.isMuted ? Colors.grey : Colors.blue,
      title: 'Notifications',
      subtitle: notifProv.statusLabel,
      child: Padding(
        padding: const EdgeInsets.only(top: 12, bottom: 4),
        child: Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            MuteChip(
              label: 'Always on',
              icon: Icons.notifications_active_rounded,
              selected: !notifProv.isMuted,
              color: Colors.green.shade600,
              onTap: notifProv.setAlwaysAllow,
            ),
            MuteChip(
              label: 'Mute 8 h',
              icon: Icons.access_time_rounded,
              selected: notifProv.isMuted &&
                  _approxHours(notifProv.muteUntil, 8),
              color: Colors.orange.shade600,
              onTap: () => notifProv.muteFor(const Duration(hours: 8)),
            ),
            MuteChip(
              label: 'Mute 24 h',
              icon: Icons.bedtime_rounded,
              selected: notifProv.isMuted &&
                  _approxHours(notifProv.muteUntil, 24),
              color: Colors.deepOrange.shade600,
              onTap: () => notifProv.muteFor(const Duration(hours: 24)),
            ),
            MuteChip(
              label: 'Custom…',
              icon: Icons.tune_rounded,
              selected: false,
              color: Colors.purple.shade400,
              onTap: () => _pickCustomDays(context, notifProv),
            ),
          ],
        ),
      ),
    );
  }

  static bool _approxHours(DateTime? until, int hours) {
    if (until == null) return false;
    final diff = until.difference(DateTime.now());
    return (diff - Duration(hours: hours)).abs() < const Duration(minutes: 5);
  }

  void _pickCustomDays(BuildContext context, NotificationProvider notifProv) {
    int days = 1;
    showDialog<void>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSt) => AlertDialog(
          title: const Text('Mute for how many days?'),
          content: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              IconButton(
                icon: const Icon(Icons.remove_circle_outline_rounded),
                onPressed: () {
                  if (days > 1) setSt(() => days--);
                },
              ),
              Text(
                '$days',
                style: const TextStyle(
                    fontSize: 28, fontWeight: FontWeight.w700),
              ),
              IconButton(
                icon: const Icon(Icons.add_circle_outline_rounded),
                onPressed: () {
                  if (days < 30) setSt(() => days++);
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () {
                notifProv.muteForDays(days);
                Navigator.pop(ctx);
              },
              child: Text('Mute $days day${days > 1 ? 's' : ''}'),
            ),
          ],
        ),
      ),
    );
  }
}
