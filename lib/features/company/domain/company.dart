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
  final DateTime? supportExpiresAt;
  final int majorReleasesUsed;

  Company({
    required this.id,
    required this.name,
    required this.ownerUid,
    required this.tier,
    required this.status,
    this.stripeCustomerId,
    this.stripeSubscriptionId,
    this.propertyCount = 0,
    required this.createdAt,
    this.supportExpiresAt,
    this.majorReleasesUsed = 0,
  });

  factory Company.fromMap(String id, Map<dynamic, dynamic> map) {
    return Company(
      id: id,
      name: map['name']?.toString() ?? 'Unknown Company',
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

  Company copyWith({
    String? id,
    String? name,
    String? ownerUid,
    SubscriptionTier? tier,
    SubscriptionStatus? status,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
    int? propertyCount,
    DateTime? createdAt,
    DateTime? supportExpiresAt,
    int? majorReleasesUsed,
  }) {
    return Company(
      id: id ?? this.id,
      name: name ?? this.name,
      ownerUid: ownerUid ?? this.ownerUid,
      tier: tier ?? this.tier,
      status: status ?? this.status,
      stripeCustomerId: stripeCustomerId ?? this.stripeCustomerId,
      stripeSubscriptionId: stripeSubscriptionId ?? this.stripeSubscriptionId,
      propertyCount: propertyCount ?? this.propertyCount,
      createdAt: createdAt ?? this.createdAt,
      supportExpiresAt: supportExpiresAt ?? this.supportExpiresAt,
      majorReleasesUsed: majorReleasesUsed ?? this.majorReleasesUsed,
    );
  }
}
