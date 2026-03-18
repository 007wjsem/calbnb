import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/company.dart';
import '../domain/subscription.dart';
import '../domain/transaction_record.dart';

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
      final value = event.snapshot.value;

      // Normalize to a Map regardless of how Firebase stored it
      Map<dynamic, dynamic> rawMap = {};
      if (value is List) {
        for (int i = 0; i < value.length; i++) {
          if (value[i] != null) rawMap[i.toString()] = value[i];
        }
      } else if (value is Map) {
        rawMap = Map<dynamic, dynamic>.from(value);
      }

      final List<Company> companies = [];
      for (final entry in rawMap.entries) {
        final entryValue = entry.value;
        // Skip any entry that isn't a Map (e.g., nested sub-nodes that were
        // accidentally hoisted, null entries, or non-company keys)
        if (entryValue is! Map) continue;
        try {
          companies.add(Company.fromMap(
            entry.key.toString(),
            Map<dynamic, dynamic>.from(entryValue),
          ));
        } catch (e) {
          // Skip malformed entries rather than crashing the whole stream
          print('Skipping malformed company entry ${entry.key}: $e');
        }
      }

      return companies;
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

  /// Renew subscription for 1 month
  Future<void> renewSubscription({
    required String companyId,
    required SubscriptionTier tier,
  }) async {
    final DateTime now = DateTime.now();
    // Set expiration to 1 month from today
    final DateTime endDate = DateTime(now.year, now.month + 1, now.day, now.hour, now.minute);
    
    final updates = <String, dynamic>{
      'subscriptionTier': tier.value,
      'subscriptionStatus': SubscriptionStatus.active.value,
      'subscriptionEndDate': endDate.millisecondsSinceEpoch,
    };
    
    await _db.ref('companies/$companyId').update(updates);
  }

  /// Securely log the transaction details for traceability
  Future<void> saveTransaction(TransactionRecord transaction) async {
    final ref = _db.ref('transactions/${transaction.companyId}').push();
    await ref.set(transaction.toMap());
  }

  /// Increment or decrement the active property count.
  Future<void> updatePropertyCount(String companyId, int delta) async {
    final snapshot = await _db.ref('companies/$companyId/propertyCount').get();
    final current = (snapshot.value as num?)?.toInt() ?? 0;
    await _db.ref('companies/$companyId/propertyCount').set(current + delta);
  }

  /// Update the company's currency settings (Platinum feature).
  Future<void> updateCurrency({
    required String companyId,
    required String baseCurrency,
    required String currencySymbol,
  }) async {
    await _db.ref('companies/$companyId').update({
      'baseCurrency': baseCurrency,
      'currencySymbol': currencySymbol,
    });
  }

  /// Update (or remove) the company's white-label logo (Diamond feature).
  /// Pass null [logoBase64] to clear the logo.
  Future<void> updateCompanyLogo({required String companyId, required String? logoBase64}) async {
    await _db.ref('companies/$companyId').update({'companyLogoBase64': logoBase64});
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
