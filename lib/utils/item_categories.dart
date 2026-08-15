/// Item category constants and emoji mapping.
/// Extracted from constants.dart for single-responsibility.
class ItemCategory {
  ItemCategory._();

  static const String grocery = 'Grocery';
  static const String online = 'Online';
  static const String physical = 'Physical';
  static const String wearables = 'Wearables';
  static const String home = 'Home & Living';
  static const String health = 'Health & Beauty';
  static const String electronics = 'Electronics';
  static const String education = 'Education';
  static const String other = 'Other';

  static const List<String> all = [
    grocery,
    online,
    physical,
    wearables,
    home,
    health,
    electronics,
    education,
    other,
  ];

  static const List<String> allWithAll = [
    'All',
    grocery,
    online,
    physical,
    wearables,
    home,
    health,
    electronics,
    education,
    other,
  ];

  static String emoji(String category) {
    switch (category) {
      case grocery:
        return '🛒';
      case online:
        return '💻';
      case physical:
        return '🏪';
      case wearables:
        return '👕';
      case home:
        return '🏠';
      case health:
        return '💊';
      case electronics:
        return '🎮';
      case education:
        return '📚';
      default:
        return '📦';
    }
  }
}