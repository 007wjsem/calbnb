enum SubscriptionTier {
  starter,
  growth,
  agency;

  String get value => name;

  /// Flat monthly base price in USD
  double get basePrice {
    switch (this) {
      case SubscriptionTier.starter: return 29.0;
      case SubscriptionTier.growth: return 99.0;
      case SubscriptionTier.agency: return 249.0;
    }
  }

  /// Number of properties included in the base price
  int get includedProperties {
    switch (this) {
      case SubscriptionTier.starter: return 5;
      case SubscriptionTier.growth: return 20;
      case SubscriptionTier.agency: return 50;
    }
  }

  /// USD per additional property beyond the included count
  double get overageRate {
    switch (this) {
      case SubscriptionTier.starter: return 5.0;
      case SubscriptionTier.growth: return 4.0;
      case SubscriptionTier.agency: return 3.0;
    }
  }

  String get displayName {
    switch (this) {
      case SubscriptionTier.starter: return 'Starter';
      case SubscriptionTier.growth: return 'Growth';
      case SubscriptionTier.agency: return 'Agency';
    }
  }

  static SubscriptionTier fromString(String? value) {
    switch (value) {
      case 'growth': return SubscriptionTier.growth;
      case 'agency': return SubscriptionTier.agency;
      default: return SubscriptionTier.starter;
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
