import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';

import '../providers/auth_provider.dart';
import '../providers/shopping_provider.dart';
import '../utils/subscription_limits.dart';
import '../screens/splash_screen.dart';
import '../screens/login_screen.dart';
import '../screens/home_screen.dart';
import '../screens/add_item_screen.dart';
import '../screens/profile_screen.dart';
import '../screens/settings_screen.dart';
import '../screens/invite_screen.dart';
import '../screens/join_via_link_screen.dart';
import '../utils/constants.dart';

/// Builds the application [GoRouter].
///
/// Pass the [authProvider] so the router can refresh on auth state changes
/// and redirect unauthenticated users to the login screen.
///
/// The [lastInitUserId] getter and [onInitUser] callback allow the router
/// to trigger [ShoppingProvider.initForUser] when the home route is built,
/// keeping that side-effect in the same place it was before extraction.
class AppRouter {
  AppRouter._();

  static GoRouter build({
    required AuthProvider authProvider,
    required String? Function() getLastInitUserId,
    required void Function(String userId, String listId) onInitUser,
    required void Function(SubscriptionTier tier) onSetUserTier,
  }) {
    return GoRouter(
      initialLocation: AppConstants.routeSplash,
      refreshListenable: authProvider,
      redirect: (context, state) {
        final isOnLogin =
            state.matchedLocation == AppConstants.routeLogin;
        final isOnSplash =
            state.matchedLocation == AppConstants.routeSplash;

        if (authProvider.status == AuthStatus.unknown) {
          return isOnSplash ? null : AppConstants.routeSplash;
        }

        if (authProvider.status == AuthStatus.unauthenticated) {
          return isOnLogin ? null : AppConstants.routeLogin;
        }

        if (isOnLogin || isOnSplash) {
          return AppConstants.routeHome;
        }

        return null;
      },
      routes: [
        GoRoute(
          path: AppConstants.routeSplash,
          builder: (_, __) => const SplashScreen(),
        ),
        GoRoute(
          path: AppConstants.routeLogin,
          builder: (_, __) => const LoginScreen(),
        ),
        GoRoute(
          path: AppConstants.routeHome,
          builder: (context, state) {
            final profile = authProvider.userProfile;
            if (profile != null && profile.listId != null) {
              context.read<ShoppingProvider>();
              if (getLastInitUserId() != profile.id) {
                onInitUser(profile.id, profile.listId!);
              }
              onSetUserTier(profile.subscriptionTier);
            }
            return const HomeScreen();
          },
        ),
        GoRoute(
          path: AppConstants.routeAddItem,
          builder: (_, __) => const AddItemScreen(),
        ),
        GoRoute(
          path: AppConstants.routeProfile,
          builder: (_, __) => const ProfileScreen(),
        ),
        GoRoute(
          path: AppConstants.routeSettings,
          builder: (_, __) => const SettingsScreen(),
        ),
        GoRoute(
          path: AppConstants.routeInvite,
          builder: (_, __) => const InviteScreen(),
        ),
        GoRoute(
          path: '/join/:shortCode',
          builder: (context, state) {
            final shortCode = state.pathParameters['shortCode'] ?? '';
            return JoinViaLinkScreen(shortCode: shortCode);
          },
        ),
      ],
    );
  }
}