import '../models/shopping_item.dart';

/// Utility class for formatting shopping lists as shareable text
class ListFormatter {
  ListFormatter._();

  /// Formats shopping items as shareable text with emojis and formatting
  ///
  /// Example output:
  /// ```
  /// 🛒 My Personal List - 3 items
  /// (1 completed)
  ///
  /// ✓ Milk (2 L) - Grocery
  /// ○ Bread (1 pcs) - Grocery
  /// ○ Toothpaste (1 tube) - Health & Beauty
  /// ```
  static String formatItemsAsText({
    required List<ShoppingItem> items,
    required String listName,
    bool includeCompletedStatus = true,
    bool includeCategories = true,
  }) {
    final buffer = StringBuffer();
    buffer.writeln('🛒 $listName');
    buffer.writeln();

    for (final item in items) {
      // Bullet point
      buffer.write('• ${item.name}');

      // Category
      if (includeCategories && item.category.isNotEmpty) {
        buffer.write(' (${item.category})');
      }

      // Quantity and unit
      if (item.quantity != null &&
          item.quantity! > 0 &&
          item.unit != null &&
          item.unit!.isNotEmpty) {
        buffer.write(' – ${item.quantity} ${item.unit}');
      } else if (item.quantity != null && item.quantity! > 0) {
        buffer.write(' – x${item.quantity}');
      }

      // Completion checkmark
      if (includeCompletedStatus && item.completed) {
        buffer.write(' ✓');
      }

      buffer.writeln();
    }

    return buffer.toString().trim();
  }
}
