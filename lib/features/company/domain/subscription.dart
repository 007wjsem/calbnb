enum SubscriptionTier {
  starter,
  pro,
  agency,
  enterprise;

  String get value => name;

  String get displayName {
    switch (this) {
      case SubscriptionTier.starter: return 'Starter';
      case SubscriptionTier.pro: return 'Pro';
      case SubscriptionTier.agency: return 'Agency';
      case SubscriptionTier.enterprise: return 'Enterprise';
    }
  }

  int get maxProperties {
    switch (this) {
      case SubscriptionTier.starter: return 3;
      case SubscriptionTier.pro: return 20;
      case SubscriptionTier.agency: return 100;
      case SubscriptionTier.enterprise: return 99999;
    }
  }

  static SubscriptionTier fromString(String? value) {
    switch (value) {
      case 'pro': return SubscriptionTier.pro;
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
