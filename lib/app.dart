import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:app_links/app_links.dart';

import 'dart:async';

import 'providers/auth_provider.dart';
import 'providers/shopping_provider.dart';
import 'providers/theme_provider.dart';
import 'routing/app_router.dart';
import 'services/review_service.dart';
import 'services/web_allowlist_service.dart';
import 'theme/app_theme.dart';
import 'utils/constants.dart';

class ShopShareApp extends StatefulWidget {
  const ShopShareApp({super.key});

  @override
  State<ShopShareApp> createState() => _ShopShareAppState();
}

class _ShopShareAppState extends State<ShopShareApp> {
  late final AuthProvider _authProvider;
  late final GoRouter _router;
  late final AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;

  String? _lastInitUserId;
  bool _reviewScheduled = false;
  String? _lastInviteEmail;
  String? _pendingDeepLink;

  @override
  void initState() {
    super.initState();
    _authProvider = context.read<AuthProvider>();
    _router = AppRouter.build(
      authProvider: _authProvider,
      getLastInitUserId: () => _lastInitUserId,
      onInitUser: (userId, listId) {
        _lastInitUserId = userId;
        context.read<ShoppingProvider>().initForUser(userId, listId);
        _handlePendingDeepLink();
      },
      onSetUserTier: (tier) {
        context.read<ShoppingProvider>().setUserTier(tier);
      },
    );
    _authProvider.addListener(_onAuthChanged);
    _appLinks = AppLinks();
    _initDeepLinks();
  }

  void _initDeepLinks() {
    // Listen for deep links while app is running
    _linkSubscription = _appLinks.uriLinkStream.listen(
      (Uri? uri) {
        if (uri != null && mounted) {
          _handleDeepLink(uri);
        }
      },
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );

    // Check for initial link (app opened via deep link)
    _checkInitialLink();
  }

  Future<void> _checkInitialLink() async {
    try {
      final Uri? initialLink = await _appLinks.getInitialLink();
      if (initialLink != null && mounted) {
        debugPrint('Initial deep link: $initialLink');
        // Delay navigation until after first frame
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _handleDeepLink(initialLink);
        });
      }
    } catch (e) {
      debugPrint('Error checking initial link: $e');
    }
  }

  void _handleDeepLink(Uri uri) {
    final path = uri.path; // e.g., "/join/PC9ZW5"
    debugPrint('Handling deep link: $path');

    if (path.startsWith('/join/') && path.length > 6) {
      // Check if user is authenticated
      if (_authProvider.userProfile != null) {
        // Navigate immediately
        _router.go(path);
      } else {
        // Store for later navigation after auth
        _pendingDeepLink = path;
        debugPrint('Stored pending deep link: $path');
      }
    }
  }

  void _handlePendingDeepLink() {
    if (_pendingDeepLink != null && mounted) {
      final path = _pendingDeepLink!;
      _pendingDeepLink = null;
      debugPrint('Navigating to pending deep link: $path');
      // Use post-frame callback to ensure navigation happens after init
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          _router.go(path);
        }
      });
    }
  }

  void _onAuthChanged() async {
    final profile = _authProvider.userProfile;
    if (profile != null && profile.listId != null) {
      final allowed = await WebAllowlistService.instance
          .isEmailAllowed(profile.email);
      if (!allowed) {
        _authProvider.signOut();
        return;
      }

      if (!mounted) return;
      final shopping = context.read<ShoppingProvider>();
      if (_lastInitUserId != profile.id) {
        _lastInitUserId = profile.id;
        shopping.initForUser(profile.id, profile.listId!);
        if (!_reviewScheduled) {
          _reviewScheduled = true;
          Timer(const Duration(seconds: 10), () {
            ReviewService.instance.maybeRequestReview();
          });
        }
      }
      final email = profile.email;
      if (email != null && email.isNotEmpty && _lastInviteEmail != email) {
        _lastInviteEmail = email;
        shopping.initInviteStream(email);
      }
      shopping.setUserTier(profile.subscriptionTier);
    } else if (_authProvider.userProfile == null) {
      context.read<ShoppingProvider>().disposeInviteStream();
      _lastInitUserId = null;
      _lastInviteEmail = null;
    }
  }

  @override
  void dispose() {
    _authProvider.removeListener(_onAuthChanged);
    _linkSubscription?.cancel();
    _router.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        final ThemeData lightT;
        final ThemeData darkT;
        final ThemeMode mode;

        switch (themeProvider.choice) {
          case AppThemeChoice.soothing:
            lightT = AppTheme.soothingTheme();
            darkT = AppTheme.soothingTheme();
            mode = ThemeMode.light;
          case AppThemeChoice.vibrantDark:
            lightT = AppTheme.vibrantDarkTheme();
            darkT = AppTheme.vibrantDarkTheme();
            mode = ThemeMode.dark;
          case AppThemeChoice.system:
            lightT = AppTheme.lightTheme();
            darkT = AppTheme.darkTheme();
            mode = ThemeMode.system;
        }

        return MaterialApp.router(
          title: AppConstants.appName,
          debugShowCheckedModeBanner: false,
          theme: lightT,
          darkTheme: darkT,
          themeMode: mode,
          routerConfig: _router,
        );
      },
    );
  }
}