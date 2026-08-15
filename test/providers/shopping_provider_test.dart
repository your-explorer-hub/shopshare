import 'package:flutter_test/flutter_test.dart';
import 'package:shopping_app/models/shopping_item.dart';
import 'package:shopping_app/utils/subscription_limits.dart';

class HistoryHelper {
  final List<ShoppingItem> items;
  final SubscriptionTier tier;
  HistoryHelper({required this.items, required this.tier});
  DateTime? get _cutoff {
    final days = SubscriptionLimits.historyDays(tier);
    if (days == -1) return null;
    final now = DateTime.now();
    return DateTime(now.year, now.month, now.day).subtract(Duration(days: days));
  }
  int get hiddenByHistoryCount {
    final cutoff = _cutoff;
    if (cutoff == null) return 0;
    return items.where((item) => item.addedAt.isBefore(cutoff)).length;
  }
  List<ShoppingItem> get visibleItems {
    final cutoff = _cutoff;
    return items.where((item) {
      if (cutoff != null && item.addedAt.isBefore(cutoff)) return false;
      return true;
    }).toList();
  }
  bool get isHistoryLimited => !SubscriptionLimits.isHistoryUnlimited(tier);
  int get historyLimitDays => SubscriptionLimits.historyDays(tier);
}

ShoppingItem makeItem({required String id, required DateTime addedAt}) {
  return ShoppingItem(
    id: id, listId: 'list-1', name: 'Item',
    categories: const ['Grocery'], addedBy: 'u1', addedByName: 'Alice',
    addedAt: addedAt,
  );
}

void main() {
  group('ShoppingProvider - historyDays / hiddenByHistoryCount logic', () {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final i0   = makeItem(id: 'today', addedAt: today);
    final i20  = makeItem(id: '20d',  addedAt: today.subtract(const Duration(days: 20)));
    final i35  = makeItem(id: '35d',  addedAt: today.subtract(const Duration(days: 35)));
    final i100 = makeItem(id: '100d', addedAt: today.subtract(const Duration(days: 100)));
    final i200 = makeItem(id: '200d', addedAt: today.subtract(const Duration(days: 200)));
    final all  = [i0, i20, i35, i100, i200];

    test('SPROV-01: free tier isHistoryLimited is true', () {
      expect(HistoryHelper(items: all, tier: SubscriptionTier.free).isHistoryLimited, isTrue);
    });
    test('SPROV-02: group tier isHistoryLimited is false', () {
      expect(HistoryHelper(items: all, tier: SubscriptionTier.group).isHistoryLimited, isFalse);
    });
    test('SPROV-03: free tier historyLimitDays equals 30', () {
      expect(HistoryHelper(items: all, tier: SubscriptionTier.free).historyLimitDays, 30);
    });
    test('SPROV-04: family tier historyLimitDays equals 90', () {
      expect(HistoryHelper(items: all, tier: SubscriptionTier.family).historyLimitDays, 90);
    });
    test('SPROV-05: group tier historyLimitDays equals -1 (unlimited)', () {
      expect(HistoryHelper(items: all, tier: SubscriptionTier.group).historyLimitDays, -1);
    });
    test('SPROV-06: free tier hides items older than 30 days', () {
      expect(HistoryHelper(items: all, tier: SubscriptionTier.free).hiddenByHistoryCount, 3);
    });
    test('SPROV-07: free tier shows only items within 30-day window', () {
      final h = HistoryHelper(items: all, tier: SubscriptionTier.free);
      expect(h.visibleItems.length, 2);
      expect(h.visibleItems.map((i) => i.id), containsAll(['today', '20d']));
    });
    test('SPROV-08: family tier hides items older than 90 days', () {
      expect(HistoryHelper(items: all, tier: SubscriptionTier.family).hiddenByHistoryCount, 2);
    });
    test('SPROV-09: family tier shows items within 90-day window', () {
      final h = HistoryHelper(items: all, tier: SubscriptionTier.family);
      expect(h.visibleItems.length, 3);
      expect(h.visibleItems.map((i) => i.id), containsAll(['today', '20d', '35d']));
    });
    test('SPROV-10: group tier hides no items (unlimited history)', () {
      expect(HistoryHelper(items: all, tier: SubscriptionTier.group).hiddenByHistoryCount, 0);
    });
    test('SPROV-11: group tier shows all items regardless of age', () {
      expect(HistoryHelper(items: all, tier: SubscriptionTier.group).visibleItems.length, all.length);
    });
    test('SPROV-12: empty item list has zero hiddenByHistoryCount', () {
      expect(HistoryHelper(items: [], tier: SubscriptionTier.free).hiddenByHistoryCount, 0);
    });
    test('SPROV-13: empty item list produces empty visibleItems', () {
      expect(HistoryHelper(items: [], tier: SubscriptionTier.free).visibleItems, isEmpty);
    });
    test('SPROV-14: hidden + visible equals total (free)', () {
      final h = HistoryHelper(items: all, tier: SubscriptionTier.free);
      expect(h.hiddenByHistoryCount + h.visibleItems.length, all.length);
    });
    test('SPROV-15: hidden + visible equals total (family)', () {
      final h = HistoryHelper(items: all, tier: SubscriptionTier.family);
      expect(h.hiddenByHistoryCount + h.visibleItems.length, all.length);
    });
  });
}
