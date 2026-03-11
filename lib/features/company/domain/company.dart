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

  // Tier 4 Enterprise-specific fields
  final DateTime? supportExpiresAt;   // When dedicated support period ends
  final int majorReleasesUsed;        // Releases claimed without active support (max 2)

  const Company({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.tier,
    required this.status,
    required this.propertyCount,
    required this.createdAt,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.supportExpiresAt,
    this.majorReleasesUsed = 0,
  });

  int? get includedProperties => tier.includedProperties;
  double? get overageRate => tier.overageRate;
  bool get isActive => status == SubscriptionStatus.active || status == SubscriptionStatus.trialing;

  /// Enterprise: true if support contract is currently active
  bool get hasSupportActive =>
      tier == SubscriptionTier.enterprise &&
      supportExpiresAt != null &&
      supportExpiresAt!.isAfter(DateTime.now());

  /// Enterprise: true if company can access next major release for free
  bool get canAccessNextMajorRelease =>
      tier == SubscriptionTier.enterprise &&
      (hasSupportActive || majorReleasesUsed < 2);

  Company copyWith({
    String? name,
    SubscriptionTier? tier,
    SubscriptionStatus? status,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
    int? propertyCount,
    DateTime? supportExpiresAt,
    int? majorReleasesUsed,
  }) {
    return Company(
      id: id,
      name: name ?? this.name,
      ownerUid: ownerUid,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      propertyCount: propertyCount ?? this.propertyCount,
      createdAt: createdAt,
      supportExpiresAt: supportExpiresAt ?? this.supportExpiresAt,
      majorReleasesUsed: majorReleasesUsed ?? this.majorReleasesUsed,
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
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'] as int)
          : DateTime.now(),
      supportExpiresAt: map['supportExpiresAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['supportExpiresAt'] as int)
          : null,
      majorReleasesUsed: (map['majorReleasesUsed'] as num?)?.toInt() ?? 0,
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
      'supportExpiresAt': supportExpiresAt?.millisecondsSinceEpoch,
      'majorReleasesUsed': majorReleasesUsed,
    };
  }
}
