import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/company.dart';

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
