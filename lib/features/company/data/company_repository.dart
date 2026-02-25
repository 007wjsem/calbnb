import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/company.dart';
import '../domain/subscription.dart';

class CompanyRepository {
  final FirebaseDatabase _db;

  CompanyRepository({FirebaseDatabase? db})
      : _db = db ?? FirebaseDatabase.instance;

  DatabaseReference _ref(String companyId) =>
      _db.ref('companies/$companyId');

  /// Fetch a company once by ID.
  Future<Company?> getCompany(String companyId) async {
    final snapshot = await _ref(companyId).get();
    if (!snapshot.exists) return null;
    return Company.fromMap(companyId, snapshot.value as Map<dynamic, dynamic>);
  }

  /// Stream a company record in real time.
  Stream<Company?> watchCompany(String companyId) {
    return _ref(companyId).onValue.map((event) {
      if (!event.snapshot.exists) return null;
      return Company.fromMap(
          companyId, event.snapshot.value as Map<dynamic, dynamic>);
    });
  }

  /// Create a brand-new company (called during registration).
  Future<String> createCompany({
    required String name,
    required String ownerUid,
    SubscriptionTier tier = SubscriptionTier.starter,
  }) async {
    final newRef = _db.ref('companies').push();
    final company = Company(
      id: newRef.key!,
      name: name,
      ownerUid: ownerUid,
      tier: tier,
      status: SubscriptionStatus.trialing,
      propertyCount: 0,
      createdAt: DateTime.now(),
    );
    await newRef.set(company.toMap());
    return newRef.key!;
  }

  /// Update subscription tier and status (called from Stripe webhook Cloud Function
  /// via a direct DB write, but also callable from admin screens).
  Future<void> updateSubscription({
    required String companyId,
    SubscriptionTier? tier,
    SubscriptionStatus? status,
    String? stripeCustomerId,
    String? stripeSubscriptionId,
  }) async {
    final updates = <String, dynamic>{};
    if (tier != null) updates['subscriptionTier'] = tier.value;
    if (status != null) updates['subscriptionStatus'] = status.value;
    if (stripeCustomerId != null) updates['stripeCustomerId'] = stripeCustomerId;
    if (stripeSubscriptionId != null) updates['stripeSubscriptionId'] = stripeSubscriptionId;
    await _ref(companyId).update(updates);
  }

  /// Increment or decrement the active property count.
  Future<void> updatePropertyCount(String companyId, int delta) async {
    final snapshot = await _ref(companyId).child('propertyCount').get();
    final current = (snapshot.value as num?)?.toInt() ?? 0;
    await _ref(companyId).child('propertyCount').set(current + delta);
  }

  /// Update company display name.
  Future<void> updateName(String companyId, String name) async {
    await _ref(companyId).update({'name': name});
  }

  /// Fetch ALL companies (Super Admin only).
  Future<List<Company>> fetchAllCompanies() async {
    final snapshot = await _db.ref('companies').get();
    if (!snapshot.exists) return [];
    
    final map = snapshot.value as Map<dynamic, dynamic>;
    return map.entries.map((e) {
      return Company.fromMap(e.key.toString(), e.value as Map<dynamic, dynamic>);
    }).toList();
  }

  /// Watch ALL companies in real time (Super Admin only).
  Stream<List<Company>> watchAllCompanies() {
    return _db.ref('companies').onValue.map((event) {
      if (!event.snapshot.exists) return [];
      final map = event.snapshot.value as Map<dynamic, dynamic>;
      return map.entries.map((e) {
        return Company.fromMap(e.key.toString(), e.value as Map<dynamic, dynamic>);
      }).toList();
    });
  }
}

// ─── Providers ────────────────────────────────────────────────────────────────

final companyRepositoryProvider = Provider<CompanyRepository>((ref) {
  return CompanyRepository();
});

final companyProvider = StreamProvider.family<Company?, String>((ref, companyId) {
  return ref.watch(companyRepositoryProvider).watchCompany(companyId);
});

final globalCompaniesProvider = StreamProvider<List<Company>>((ref) {
  return ref.watch(companyRepositoryProvider).watchAllCompanies();
});
