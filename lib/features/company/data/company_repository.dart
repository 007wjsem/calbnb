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
  Future<void> createCompany(Company company) async {
    final newRef = company.id.isEmpty ? _db.ref('companies').push() : _db.ref('companies/${company.id}');
    
    // Ensure we save the generated ID back to the object if it was empty
    final companyToSave = company.id.isEmpty ? company.copyWith(id: newRef.key!) : company;
    
    
    await newRef.set(companyToSave.toMap());
  }

  Future<void> updateCompany(Company company) async {
    await _db.ref('companies/${company.id}').update(company.toMap());
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
