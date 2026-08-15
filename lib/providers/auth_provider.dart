import 'package:flutter/foundation.dart';

import 'package:firebase_auth/firebase_auth.dart';

import '../core/utils/app_logger.dart';
import '../models/user_profile.dart';
import '../services/auth_service.dart';

enum AuthStatus { unknown, authenticated, unauthenticated }

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  AuthStatus _status = AuthStatus.unknown;
  UserProfile? _userProfile;
  String? _errorMessage;
  bool _isLoading = false;

  AuthStatus get status => _status;
  UserProfile? get userProfile => _userProfile;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _status == AuthStatus.authenticated;

  AuthProvider() {
    _init();
  }

  void _init() {
    AppLogger.info('AuthProvider initializing');

    // Resolve immediately from the synchronous cached state so the splash
    // screen never spins while waiting for the first stream event.
    final cachedUser = _authService.currentUser;
    if (cachedUser != null) {
      _status = AuthStatus.authenticated;
      _userProfile = _minimalProfile(cachedUser);
      AppLogger.debug('Auth initialized with cached user', {'userId': cachedUser.uid});

      // Load full profile in the background; don't block navigation.
      _authService.getCurrentUserProfile().then((profile) {
        if (profile != null) {
          _userProfile = profile;
          AppLogger.debug('Full profile loaded', {'userId': profile.id});
        }
        notifyListeners();
      }).catchError((e) {
        _errorMessage = 'Could not load profile: $e';
        AppLogger.warning('Failed to load user profile', {'error': e.toString()});
        notifyListeners();
      });
      notifyListeners(); // ← navigate away from splash right now with minimal profile
    }

    _authService.authStateChanges.listen(_onAuthStateChanged);

    // Safety net: if Firebase doesn't emit within 3 seconds (e.g. offline or
    // initialisation race), default to unauthenticated so the login screen shows.
    Future.delayed(const Duration(seconds: 3), () {
      if (_status == AuthStatus.unknown) {
        _status = AuthStatus.unauthenticated;
        AppLogger.warning('Auth state timeout - defaulting to unauthenticated');
        notifyListeners();
      }
    });
  }

  Future<void> _onAuthStateChanged(User? user) async {
    if (user == null) {
      _status = AuthStatus.unauthenticated;
      _userProfile = null;
      notifyListeners(); // navigate to login immediately
    } else {
      _status = AuthStatus.authenticated;
      // Set a minimal profile immediately so downstream widgets (add-item,
      // shopping provider init) never see a null profile while Firestore loads.
      _userProfile ??= _minimalProfile(user);
      notifyListeners(); // ← navigate away from splash immediately
      try {
        final full = await _authService.getCurrentUserProfile();
        if (full != null) _userProfile = full;
      } catch (e) {
        // Firestore may be unavailable (e.g. not yet created). Keep minimal
        // profile so the user isn't bounced back to login.
        _errorMessage = 'Could not load profile. Check Firestore is enabled: $e';
      }
      notifyListeners(); // update UI with full profile
    }
  }

  /// Builds a minimal [UserProfile] from the Firebase Auth [User] so that
  /// downstream code always has a non-null profile while Firestore loads.
  UserProfile _minimalProfile(User user) {
    return UserProfile(
      id: user.uid,
      email: user.email ?? '',
      displayName: user.displayName ?? 'User',
      photoUrl: user.photoURL,
      listId: 'list_${user.uid}',
      createdAt: DateTime.now(),
    );
  }

  // ─── Sign In ─────────────────────────────────────────────────────────────────

  Future<bool> signInWithGoogle() async {
    _setLoading(true);
    _clearError();
    AppLogger.info('Attempting Google sign-in');

    try {
      final profile = await _authService.signInWithGoogle();
      if (profile != null) {
        _userProfile = profile;
        _status = AuthStatus.authenticated;
        AppLogger.info('Google sign-in successful', {'userId': profile.id});
        notifyListeners();
        return true;
      }
      AppLogger.warning('Google sign-in returned null profile');
      return false;
    } on AuthException catch (e) {
      _errorMessage = e.message;
      AppLogger.error('Google sign-in failed - AuthException', {
        'error': e.message,
      });
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'An unexpected error occurred. Please try again.';
      AppLogger.error('Google sign-in failed - unexpected error', {
        'error': e.toString(),
      });
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Delete Account ──────────────────────────────────────────────────────────

  Future<void> deleteAccount() async {
    _setLoading(true);
    _clearError();
    AppLogger.info('Attempting account deletion');

    try {
      await _authService.deleteAccount();
      _userProfile = null;
      _status = AuthStatus.unauthenticated;
      AppLogger.info('Account deleted successfully');
      notifyListeners();
    } on AuthException catch (e) {
      _errorMessage = e.message;
      AppLogger.error('Account deletion failed - AuthException', {
        'error': e.message,
      });
      notifyListeners();
      rethrow;
    } catch (e) {
      _errorMessage = 'Account deletion failed. Please try again.';
      AppLogger.error('Account deletion failed - unexpected error', {
        'error': e.toString(),
      });
      notifyListeners();
      rethrow;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Sign Out ─────────────────────────────────────────────────────────────────

  Future<void> signOut() async {
    _setLoading(true);
    _clearError();
    AppLogger.info('Attempting sign out');

    try {
      await _authService.signOut();
      _userProfile = null;
      _status = AuthStatus.unauthenticated;
      AppLogger.info('Sign out successful');
      notifyListeners();
    } on AuthException catch (e) {
      _errorMessage = e.message;
      AppLogger.error('Sign out failed - AuthException', {
        'error': e.message,
      });
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // ─── Update Profile ───────────────────────────────────────────────────────────

  Future<bool> updateProfile({
    String? displayName,
    String? photoUrl,
    String? gender,
  }) async {
    if (_userProfile == null) return false;
    _setLoading(true);
    _clearError();
    AppLogger.debug('Updating user profile');

    try {
      final updated = await _authService.updateUserProfile(
        userId: _userProfile!.id,
        displayName: displayName,
        photoUrl: photoUrl,
        gender: gender,
      );
      _userProfile = updated;
      AppLogger.info('Profile updated successfully');
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update profile.';
      AppLogger.error('Profile update failed', {'error': e.toString()});
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Helpers ──────────────────────────────────────────────────────────────────

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
  }

  void clearError() {
    _clearError();
    notifyListeners();
  }
}