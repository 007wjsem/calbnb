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
      case SubscriptionTier.gold: return 69.99;
      case SubscriptionTier.platinum: return 199.99;
      case SubscriptionTier.diamond: return 299.99;
    }
  }

  /// Number of properties included.
  int? get includedProperties {
    switch (this) {
      case SubscriptionTier.free: return 2;
      case SubscriptionTier.bronze: return 5;
      case SubscriptionTier.silver: return 15;
      case SubscriptionTier.gold: return 30;
      case SubscriptionTier.platinum: return 60;
      case SubscriptionTier.diamond: return 100;
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
      case SubscriptionTier.bronze: return 4;
      case SubscriptionTier.silver: return 10;
      case SubscriptionTier.gold: return 18;
      case SubscriptionTier.platinum: return 39;
      case SubscriptionTier.diamond: return 106;
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
