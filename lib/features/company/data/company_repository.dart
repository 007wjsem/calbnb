import 'package:firebase_database/firebase_database.dart';
import '../domain/company.dart';
import '../domain/subscription.dart';

class CompanyRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Stream<Company?> watchCompany(String companyId) {
    return _db.ref('companies/$companyId').onValue.map((event) {
      if (!event.snapshot.exists) return null;
      return Company.fromMap(companyId, event.snapshot.value as Map<dynamic, dynamic>);
    });
  }

  Stream<List<Company>> watchAllCompanies() {
    return _db.ref('companies').onValue.map((event) {
      if (!event.snapshot.exists) return [];
      final map = event.snapshot.value as Map<dynamic, dynamic>;
      return map.entries.map((e) {
        return Company.fromMap(e.key.toString(), e.value as Map<dynamic, dynamic>);
      }).toList();
    });
  }
  Future<void> createCompany(Company company) async {
    final newRef = company.id.isEmpty ? _db.ref('companies').push() : _db.ref('companies/${company.id}');
    
    // Ensure we save the generated ID back to the object if it was empty
    final companyToSave = company.id.isEmpty ? company.copyWith(id: newRef.key!) : company;
    
    
    await newRef.set(companyToSave.toMap());
  }

  Future<void> updateCompany(Company company) async {
    await _db.ref('companies/${company.id}').update(company.toMap());
  }

  /// Update subscription tier and status
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
    await _db.ref('companies/$companyId').update(updates);
  }

  /// Increment or decrement the active property count.
  Future<void> updatePropertyCount(String companyId, int delta) async {
    final snapshot = await _db.ref('companies/$companyId/propertyCount').get();
    final current = (snapshot.value as num?)?.toInt() ?? 0;
    await _db.ref('companies/$companyId/propertyCount').set(current + delta);
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
