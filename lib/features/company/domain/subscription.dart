enum SubscriptionTier {
  free,
  bronze,
  silver,
  gold,
  platinum,
  diamond;

  String get value => name;

  /// Flat monthly base price in USD.
  double get basePrice {
    switch (this) {
      case SubscriptionTier.free: return 0.0;
      case SubscriptionTier.bronze: return 9.99;
      case SubscriptionTier.silver: return 29.99;
      case SubscriptionTier.gold: return 79.99;
      case SubscriptionTier.platinum: return 149.99;
      case SubscriptionTier.diamond: return 299.99;
    }
  }

  /// Number of properties included.
  int? get includedProperties {
    switch (this) {
      case SubscriptionTier.free: return 1;
      case SubscriptionTier.bronze: return 5;
      case SubscriptionTier.silver: return 15;
      case SubscriptionTier.gold: return 40;
      case SubscriptionTier.platinum: return 100;
      case SubscriptionTier.diamond: return 9999; // Unlimited
    }
  }

  /// USD per additional property beyond the included count. null = no overage allowed.
  double? get overageRate {
    switch (this) {
      case SubscriptionTier.free: return null;
      case SubscriptionTier.bronze: return 2.0;
      case SubscriptionTier.silver: return 1.50;
      case SubscriptionTier.gold: return 1.25;
      case SubscriptionTier.platinum: return 1.0;
      case SubscriptionTier.diamond: return 0.75;
    }
  }

  /// Max number of total users allowed in the company.
  int get maxUsers {
    switch (this) {
      case SubscriptionTier.free: return 1;
      case SubscriptionTier.bronze: return 2;
      case SubscriptionTier.silver: return 5;
      case SubscriptionTier.gold: return 12;
      case SubscriptionTier.platinum: return 50;
      case SubscriptionTier.diamond: return 9999; // Unlimited
    }
  }

  String get displayName {
    switch (this) {
      case SubscriptionTier.free: return 'Free';
      case SubscriptionTier.bronze: return 'Bronze';
      case SubscriptionTier.silver: return 'Silver';
      case SubscriptionTier.gold: return 'Gold';
      case SubscriptionTier.platinum: return 'Platinum';
      case SubscriptionTier.diamond: return 'Diamond';
    }
  }

  /// Unique Product ID in App Store Connect / Google Play Console.
  String? get productId {
    switch (this) {
      case SubscriptionTier.free: return null;
      case SubscriptionTier.bronze: return 'com.calbnb.bronze_monthly';
      case SubscriptionTier.silver: return 'com.calbnb.silver_monthly';
      case SubscriptionTier.gold: return 'com.calbnb.gold_monthly';
      case SubscriptionTier.platinum: return 'com.calbnb.platinum_monthly';
      case SubscriptionTier.diamond: return 'com.calbnb.diamond_monthly';
    }
  }

  static SubscriptionTier fromString(String? value) {
    switch (value) {
      case 'bronze': return SubscriptionTier.bronze;
      case 'silver': return SubscriptionTier.silver;
      case 'gold': return SubscriptionTier.gold;
      case 'platinum': return SubscriptionTier.platinum;
      case 'diamond': return SubscriptionTier.diamond;
      default: return SubscriptionTier.free;
    }
  }
}

enum SubscriptionStatus {
  trialing,
  active,
  pastDue,
  canceled,
  incomplete;

  String get value => name;

  String get displayName {
    switch (this) {
      case SubscriptionStatus.trialing: return 'Free Trial';
      case SubscriptionStatus.active: return 'Active';
      case SubscriptionStatus.pastDue: return 'Past Due';
      case SubscriptionStatus.canceled: return 'Canceled';
      case SubscriptionStatus.incomplete: return 'Incomplete';
    }
  }

  static SubscriptionStatus fromString(String? value) {
    switch (value) {
      case 'active': return SubscriptionStatus.active;
      case 'pastDue': return SubscriptionStatus.pastDue;
      case 'canceled': return SubscriptionStatus.canceled;
      case 'incomplete': return SubscriptionStatus.incomplete;
      default: return SubscriptionStatus.trialing;
    }
  }
}
