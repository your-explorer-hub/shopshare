// App-wide constants
// ItemCategory and Validators are now in their own files but re-exported here
// so all existing `import '../utils/constants.dart'` imports continue to work.

export 'item_categories.dart';
export 'validators.dart';

class AppConstants {
  AppConstants._();

  static const String appName = 'ShopShare';
  static const String appVersion = '1.0.0';

  // Firestore collections
  static const String usersCollection = 'users';
  static const String shoppingListsCollection = 'shopping_lists';
  static const String itemsSubCollection = 'items';
  static const String invitationsCollection = 'invitations';

  // SharedPreferences keys
  static const String prefUserId = 'user_id';
  static const String prefListId = 'list_id';
  static const String prefThemeMode = 'theme_mode';
  static const String prefNotifications = 'notifications_enabled';

  // Routes
  static const String routeSplash = '/';
  static const String routeLogin = '/login';
  static const String routeHome = '/home';
  static const String routeAddItem = '/add-item';
  static const String routeProfile = '/profile';
  static const String routeSettings = '/settings';
  static const String routeInvite = '/invite';
  static const String routeJoin = '/join/:shortCode';

  // Invite / deep-link
  static const String inviteBaseUrl = 'https://shopshare-f0719.web.app/invite';
  static const String joinBaseUrl = 'https://shopshare-f0719.web.app/join';

  // WhatsApp scheme
  static const String whatsAppScheme = 'https://wa.me/?text=';

  // Gmail compose
  static const String gmailScheme = 'mailto:';

  // Validation limits
  static const int listIdLength = 20;
  static const int maxItemNameLength = 100;
  static const int maxNotesLength = 300;
  static const int maxDisplayNameLength = 50;
  static const int maxListNameLength = 50;

  // Item quantity units — single source of truth used by AddItemScreen and ItemCardWidget
  static const List<String> itemUnits = [
    'pcs', 'kg', 'g', 'L', 'ml', 'dozen',
    'box', 'pack', 'bunch', 'pair', 'bag',
    'bottle', 'can', 'strip',
  ];
}

class MemberStatus {
  MemberStatus._();

  static const String pending = 'pending';
  static const String accepted = 'accepted';
  static const String rejected = 'rejected';
  static const String declined = 'declined';
}