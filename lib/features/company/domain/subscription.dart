enum SubscriptionTier {
  starter,
  growth,
  agency,
  enterprise;

  String get value => name;

  /// Flat monthly base price in USD. Enterprise is a one-time custom quote.
  double get basePrice {
    switch (this) {
      case SubscriptionTier.starter: return 29.0;
      case SubscriptionTier.growth: return 99.0;
      case SubscriptionTier.agency: return 249.0;
      case SubscriptionTier.enterprise: return 0.0; // One-time custom quote
    }
  }

  /// Number of properties included. Enterprise is unlimited.
  int? get includedProperties {
    switch (this) {
      case SubscriptionTier.starter: return 5;
      case SubscriptionTier.growth: return 20;
      case SubscriptionTier.agency: return 50;
      case SubscriptionTier.enterprise: return null; // Unlimited
    }
  }

  /// USD per additional property beyond the included count. null = no overage.
  double? get overageRate {
    switch (this) {
      case SubscriptionTier.starter: return 5.0;
      case SubscriptionTier.growth: return 4.0;
      case SubscriptionTier.agency: return 3.0;
      case SubscriptionTier.enterprise: return null;
    }
  }

  String get displayName {
    switch (this) {
      case SubscriptionTier.starter: return 'Starter';
      case SubscriptionTier.growth: return 'Growth';
      case SubscriptionTier.agency: return 'Agency';
      case SubscriptionTier.enterprise: return 'Enterprise';
    }
  }

  static SubscriptionTier fromString(String? value) {
    switch (value) {
      case 'growth': return SubscriptionTier.growth;
      case 'agency': return SubscriptionTier.agency;
      case 'enterprise': return SubscriptionTier.enterprise;
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
