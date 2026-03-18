import 'subscription.dart';

class Company {
  final String id;
  final String name;
  final String ownerUid;
  final SubscriptionTier tier;
  final SubscriptionStatus status;
  final String? stripeCustomerId;
  final String? stripeSubscriptionId;
  final int propertyCount;
  final DateTime createdAt;
  final DateTime? subscriptionEndDate;

  // Platinum-specific fields
  final String baseCurrency;   // ISO currency code e.g. 'USD', 'EUR'
  final String currencySymbol; // Display symbol e.g. '$', '€'

  // Diamond-specific fields
  final DateTime? supportExpiresAt;   // When dedicated support period ends
  final int majorReleasesUsed;        // Releases claimed without active support (max 2)
  final String? companyLogoBase64;    // White-label logo stored as base64 string

  const Company({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.tier,
    required this.status,
    required this.propertyCount,
    required this.createdAt,
    this.subscriptionEndDate,
    this.baseCurrency = 'USD',
    this.currencySymbol = '\$',
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.supportExpiresAt,
    this.majorReleasesUsed = 0,
    this.companyLogoBase64,
  });

  int? get includedProperties => tier.includedProperties;
  double? get overageRate => tier.overageRate;
  bool get isActive {
    if (status != SubscriptionStatus.active && status != SubscriptionStatus.trialing) {
      return false;
    }
    // If there is an end date, check that we haven't passed it
    if (subscriptionEndDate != null) {
      return subscriptionEndDate!.isAfter(DateTime.now());
    }
    return true; // Active with no defined end date (e.g. legacy or lifetime)
  }

  /// Diamond: true if support contract is currently active
  bool get hasSupportActive =>
      tier == SubscriptionTier.diamond &&
      supportExpiresAt != null &&
      supportExpiresAt!.isAfter(DateTime.now());

  /// Diamond: true if company can access next major release for free
  bool get canAccessNextMajorRelease =>
      tier == SubscriptionTier.diamond &&
      (hasSupportActive || majorReleasesUsed < 2);

  Company copyWith({
    String? id,
    String? name,
    SubscriptionTier? tier,
    SubscriptionStatus? status,
    String? baseCurrency,
    String? currencySymbol,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
    int? propertyCount,
    DateTime? subscriptionEndDate,
    DateTime? supportExpiresAt,
    int? majorReleasesUsed,
    String? companyLogoBase64,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerUid: ownerUid,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      baseCurrency: baseCurrency ?? this.baseCurrency,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      propertyCount: propertyCount ?? this.propertyCount,
      createdAt: createdAt,
      subscriptionEndDate: subscriptionEndDate ?? this.subscriptionEndDate,
      supportExpiresAt: supportExpiresAt ?? this.supportExpiresAt,
      majorReleasesUsed: majorReleasesUsed ?? this.majorReleasesUsed,
      companyLogoBase64: companyLogoBase64 ?? this.companyLogoBase64,
    );
  }

  factory Company.fromMap(String id, Map<dynamic, dynamic> map) {
    return Company(
      id: id,
      name: map['name']?.toString() ?? '',
      ownerUid: map['ownerUid']?.toString() ?? '',
      tier: SubscriptionTier.fromString(map['subscriptionTier']?.toString()),
      status: SubscriptionStatus.fromString(map['subscriptionStatus']?.toString()),
      stripeCustomerId: map['stripeCustomerId']?.toString(),
      stripeSubscriptionId: map['stripeSubscriptionId']?.toString(),
      propertyCount: (map['propertyCount'] as num?)?.toInt() ?? 0,
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(int.tryParse(map['createdAt'].toString()) ?? DateTime.now().millisecondsSinceEpoch)
          : DateTime.now(),
      subscriptionEndDate: map['subscriptionEndDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(int.tryParse(map['subscriptionEndDate'].toString()) ?? 0)
          : null,
      supportExpiresAt: map['supportExpiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(int.tryParse(map['supportExpiresAt'].toString()) ?? 0)
          : null,
      majorReleasesUsed: (map['majorReleasesUsed'] as num?)?.toInt() ?? 0,
      baseCurrency: map['baseCurrency']?.toString() ?? 'USD',
      currencySymbol: map['currencySymbol']?.toString() ?? '\$',
      companyLogoBase64: map['companyLogoBase64']?.toString(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'ownerUid': ownerUid,
      'subscriptionTier': tier.value,
      'subscriptionStatus': status.value,
      'stripeCustomerId': stripeCustomerId,
      'stripeSubscriptionId': stripeSubscriptionId,
      'propertyCount': propertyCount,
      'createdAt': createdAt.millisecondsSinceEpoch,
      'subscriptionEndDate': subscriptionEndDate?.millisecondsSinceEpoch,
      'supportExpiresAt': supportExpiresAt?.millisecondsSinceEpoch,
      'majorReleasesUsed': majorReleasesUsed,
      'baseCurrency': baseCurrency,
      'currencySymbol': currencySymbol,
      if (companyLogoBase64 != null) 'companyLogoBase64': companyLogoBase64,
    };
  }
}
