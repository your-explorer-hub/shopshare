import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationProvider extends ChangeNotifier {
  static const _keyMuted = 'notif_muted';
  static const _keyMuteUntil = 'notif_mute_until';

  bool _muted = false;
  DateTime? _muteUntil; // null = indefinite when muted

  bool get isMuted {
    if (!_muted) return false;
    if (_muteUntil != null && DateTime.now().isAfter(_muteUntil!)) {
      // Mute period expired — reset silently
      _muted = false;
      _muteUntil = null;
      _save();
      return false;
    }
    return true;
  }

  DateTime? get muteUntil => _muteUntil;

  String get statusLabel {
    if (!isMuted) return 'Always allow';
    if (_muteUntil == null) return 'Muted indefinitely';
    final diff = _muteUntil!.difference(DateTime.now());
    if (diff.inHours < 1) return 'Muted (${diff.inMinutes}m left)';
    if (diff.inDays < 1) return 'Muted (${diff.inHours}h left)';
    return 'Muted (${diff.inDays}d left)';
  }

  NotificationProvider() {
    _load();
  }

  Future<void> _load() async {
    final prefs = await SharedPreferences.getInstance();
    _muted = prefs.getBool(_keyMuted) ?? false;
    final ms = prefs.getInt(_keyMuteUntil);
    _muteUntil = ms != null ? DateTime.fromMillisecondsSinceEpoch(ms) : null;
    notifyListeners();
  }

  Future<void> _save() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyMuted, _muted);
    if (_muteUntil != null) {
      await prefs.setInt(_keyMuteUntil, _muteUntil!.millisecondsSinceEpoch);
    } else {
      await prefs.remove(_keyMuteUntil);
    }
  }

  Future<void> setAlwaysAllow() async {
    _muted = false;
    _muteUntil = null;
    notifyListeners();
    await _save();
  }

  Future<void> muteFor(Duration duration) async {
    _muted = true;
    _muteUntil = DateTime.now().add(duration);
    notifyListeners();
    await _save();
  }

  Future<void> muteForDays(int days) => muteFor(Duration(days: days));
}