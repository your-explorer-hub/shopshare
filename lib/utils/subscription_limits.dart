enum SubscriptionTier { free, family, group }

class SubscriptionLimits {
  SubscriptionLimits._();

  static int maxOwnedSharedLists(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.family:
        return 5;
      case SubscriptionTier.group:
        return 10;
      case SubscriptionTier.free:
        return 3;
    }
  }

  static int maxMembersPerList(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.family:
        return 10;
      case SubscriptionTier.group:
        return 25;
      case SubscriptionTier.free:
        return 5;
    }
  }

  static int maxJoinedSharedLists(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.family:
        return 5;
      case SubscriptionTier.group:
        return 10;
      case SubscriptionTier.free:
        return 3;
    }
  }

  static int historyDays(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.family:
        return 90;
      case SubscriptionTier.group:
        return -1;
      case SubscriptionTier.free:
        return 30;
    }
  }

  static bool isHistoryUnlimited(SubscriptionTier tier) =>
      historyDays(tier) == -1;

  /// Maximum number of categories that can be assigned to a single item.
  /// Free tier is limited to 1 (single category — current behaviour).
  /// Paid tiers unlock multi-category support.
  static int maxCategoriesPerItem(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.family:
        return 3;
      case SubscriptionTier.group:
        return 5;
      case SubscriptionTier.free:
        return 1;
    }
  }

  /// Returns true if the tier supports assigning multiple categories to one item.
  static bool supportsMultiCategory(SubscriptionTier tier) =>
      maxCategoriesPerItem(tier) > 1;

  static String tierDisplayName(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.family:
        return 'Family Plan';
      case SubscriptionTier.group:
        return 'Group Plan';
      case SubscriptionTier.free:
        return 'Free Plan';
    }
  }

  static String tierBadgeLabel(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.family:
        return 'FAMILY';
      case SubscriptionTier.group:
        return 'GROUP';
      case SubscriptionTier.free:
        return 'FREE';
    }
  }

  static SubscriptionTier fromString(String? value) {
    switch (value) {
      case 'family':
        return SubscriptionTier.family;
      case 'group':
        return SubscriptionTier.group;
      default:
        return SubscriptionTier.free;
    }
  }

  static String tierToString(SubscriptionTier tier) {
    switch (tier) {
      case SubscriptionTier.family:
        return 'family';
      case SubscriptionTier.group:
        return 'group';
      case SubscriptionTier.free:
        return 'free';
    }
  }
}