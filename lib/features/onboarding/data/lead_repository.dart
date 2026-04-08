import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../domain/lead.dart';

class LeadRepository {
  final FirebaseDatabase _db = FirebaseDatabase.instance;

  Future<void> createLead(Lead lead) async {
    final ref = _db.ref('leads').push();
    await ref.set(lead.copyWith(id: ref.key!).toMap());
  }

  Stream<List<Lead>> watchLeads() {
    return _db.ref('leads').onValue.map((event) {
      final snap = event.snapshot;
      final raw = snap.value;
      if (!snap.exists || raw == null) return [];
      
      Iterable<MapEntry<dynamic, dynamic>> entries;
      if (raw is Map) {
        entries = raw.entries;
      } else if (raw is List) {
        entries = raw.asMap().entries;
      } else {
        return [];
      }

      final leads = <Lead>[];
      for (final e in entries) {
        if (e.value == null) continue;
        try {
          leads.add(Lead.fromMap(e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map)));
        } catch (err) {
          // Log parsing error but skip this record
          print('Error parsing lead ${e.key}: $err');
        }
      }
      
      // Sort by timestamp descending (newest first)
      leads.sort((a, b) => b.timestamp.compareTo(a.timestamp));
      return leads;
    });
  }

  Future<void> updateLeadStatus(String leadId, String status) async {
    await _db.ref('leads/$leadId').update({'status': status});
  }

  Future<void> deleteLead(String leadId) async {
    await _db.ref('leads/$leadId').remove();
  }

}

final leadRepositoryProvider = Provider((ref) => LeadRepository());

final allLeadsProvider = StreamProvider<List<Lead>>((ref) {
  return ref.watch(leadRepositoryProvider).watchLeads();
});

final newLeadsCountProvider = Provider<AsyncValue<int>>((ref) {
  final leadsAsync = ref.watch(allLeadsProvider);
  return leadsAsync.whenData((leads) => leads.where((l) => l.status == 'new').length);
});
