import '../utils/constants.dart';
import 'categories/grocery_items.dart';
import 'categories/wearables_items.dart';
import 'categories/health_beauty_items.dart';
import 'categories/home_living_items.dart';
import 'categories/electronics_items.dart';
import 'categories/education_items.dart';
import 'categories/physical_items.dart';
import 'categories/online_items.dart';

// ── Item suggestion + category detection database ─────────────────────────────

class ItemSuggestions {
  ItemSuggestions._();

  // Merge all category catalogs
  static const Map<String, String> _catalog = {
    ...groceryItems,
    ...wearablesItems,
    ...healthBeautyItems,
    ...homeLivingItems,
    ...electronicsItems,
    ...educationItems,
    ...physicalItems,
    ...onlineItems,
  };

  static List<String> getSuggestions(String query) {
    final q = query.toLowerCase().trim();
    if (q.length < 3) return const [];

    final results = _catalog.keys
        .where((item) => item.toLowerCase().contains(q))
        .toList();

    results.sort((a, b) {
      final al = a.toLowerCase();
      final bl = b.toLowerCase();
      final aStart = al.startsWith(q) ? 0 : 1;
      final bStart = bl.startsWith(q) ? 0 : 1;
      if (aStart != bStart) return aStart.compareTo(bStart);
      return al.compareTo(bl);
    });

    return results.take(8).toList();
  }

  /// All catalog keys for fuzzy matching in voice input.
  static List<String> get allKeys => _catalog.keys.toList();

  static String detectCategory(String name) {
    final lower = name.toLowerCase().trim();
    if (lower.isEmpty) return ItemCategory.other;

    final exact = _catalog[_capitalize(lower)] ??
        _catalog.entries
            .where((e) => e.key.toLowerCase() == lower)
            .map((e) => e.value)
            .firstOrNull;
    if (exact != null) return exact;

    String? bestCat;
    int bestLen = 0;
    for (final entry in _catalog.entries) {
      final key = entry.key.toLowerCase();
      if (lower.contains(key) || key.contains(lower)) {
        if (key.length > bestLen) {
          bestLen = key.length;
          bestCat = entry.value;
        }
      }
    }
    if (bestCat != null) return bestCat;

    for (final kw in _groceryKw) {
      if (lower.contains(kw)) return ItemCategory.grocery;
    }
    for (final kw in _electronicsKw) {
      if (lower.contains(kw)) return ItemCategory.electronics;
    }
    for (final kw in _wearablesKw) {
      if (lower.contains(kw)) return ItemCategory.wearables;
    }
    for (final kw in _homeKw) {
      if (lower.contains(kw)) return 'Home & Living';
    }
    for (final kw in _healthKw) {
      if (lower.contains(kw)) return 'Health & Beauty';
    }
    for (final kw in _eduKw) {
      if (lower.contains(kw)) return ItemCategory.education;
    }

    return ItemCategory.other;
  }

  static String _capitalize(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  static const _groceryKw = [
    'milk', 'bread', 'egg', 'fruit', 'vegetable', 'meat', 'fish', 'sauce',
    'oil', 'spice', 'cereal', 'juice', 'water', 'rice', 'pasta', 'flour',
    'sugar', 'salt', 'coffee', 'tea', 'chocolate', 'soup', 'bean', 'atta',
    'dal', 'masala', 'sabzi', 'sabji', 'chawal', 'doodh', 'ghee', 'paneer',
  ];

  static const _electronicsKw = [
    'phone', 'laptop', 'tablet', 'cable', 'charger', 'device', 'smart',
    'digital', 'electronic', 'computer', 'keyboard', 'mouse', 'screen',
    'monitor', 'speaker', 'headphone', 'earphone', 'battery', 'camera',
  ];

  static const _wearablesKw = [
    'shirt', 'pant', 'dress', 'shoe', 'wear', 'cloth', 'fabric', 'jacket',
    'trouser', 'saree', 'kurta', 'jeans', 'skirt', 'sock', 'hat', 'cap',
    'scarf', 'glove', 'underwear', 'frock', 'blazer', 'coat', 'hoodie',
    'dupatta', 'salwar', 'kameez', 'dhoti', 'sherwani', 'lehenga', 'churidar',
  ];

  static const _homeKw = [
    'soap', 'clean', 'wash', 'towel', 'pillow', 'sheet', 'home', 'kitchen',
    'pan', 'pot', 'cup', 'plate', 'bowl', 'lamp', 'candle', 'mat', 'rug',
    'curtain', 'broom', 'mop', 'detergent', 'furniture', 'chair', 'table',
    'jhadu', 'pocha', 'bartan',
  ];

  static const _healthKw = [
    'shampoo', 'tooth', 'cream', 'lotion', 'medicine', 'vitamin', 'beauty',
    'health', 'care', 'gel', 'serum', 'moistur', 'deodor', 'perfume',
    'sanitizer', 'bandage', 'razor', 'comb', 'brush', 'dawai', 'dawa',
    'tablet', 'capsule',
  ];

  static const _eduKw = [
    'book', 'pen', 'pencil', 'note', 'study', 'school', 'paper', 'folder',
    'backpack', 'stapler', 'scissor', 'crayon', 'paint', 'eraser', 'ruler',
    'kitaab', 'copy',
  ];
}
