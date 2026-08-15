import 'package:flutter/foundation.dart';

class InviteScreenProvider extends ChangeNotifier {
  // UI State
  String? _expandedListId;

  // Join Operation State
  bool _isJoining = false;
  String? _joinError;

  // Email Invite State
  bool _isSendingInvite = false;
  String? _emailInviteError;

  // Getters
  String? get expandedListId => _expandedListId;
  bool get isJoining => _isJoining;
  String? get joinError => _joinError;
  bool get isSendingInvite => _isSendingInvite;
  String? get emailInviteError => _emailInviteError;

  // Methods
  void toggleExpandedList(String? listId) {
    _expandedListId = _expandedListId == listId ? null : listId;
    notifyListeners();
  }

  void setJoining(bool joining) {
    _isJoining = joining;
    if (joining) _joinError = null;
    notifyListeners();
  }

  void setJoinError(String? error) {
    _joinError = error;
    _isJoining = false;
    notifyListeners();
  }

  void clearJoinError() {
    _joinError = null;
    notifyListeners();
  }

  void setSendingInvite(bool sending) {
    _isSendingInvite = sending;
    if (sending) _emailInviteError = null;
    notifyListeners();
  }

  void setEmailInviteError(String? error) {
    _emailInviteError = error;
    _isSendingInvite = false;
    notifyListeners();
  }

  void clearEmailInviteError() {
    _emailInviteError = null;
    notifyListeners();
  }

  void reset() {
    _expandedListId = null;
    _isJoining = false;
    _joinError = null;
    _isSendingInvite = false;
    _emailInviteError = null;
    notifyListeners();
  }
}
