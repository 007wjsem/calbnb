import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:intl/intl.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/cleaning_assignment.dart';

final cleaningRepositoryProvider = Provider((ref) {
  final activeCompanyId = ref.watch(authControllerProvider)?.activeCompanyId;
  return CleaningAssignmentRepository(activeCompanyId: activeCompanyId);
});

// A StreamProvider to listen to assignments for a specific date
final defaultDateFormatter = DateFormat('yyyy-MM-dd');

final dailyCleaningAssignmentsProvider = StreamProvider.family<List<CleaningAssignment>, DateTime>((ref, date) async* {
  final repo = ref.watch(cleaningRepositoryProvider);
  final dateStr = defaultDateFormatter.format(date);
  
  final isSuperAdmin = repo.activeCompanyId == null;
  final stream = isSuperAdmin 
      ? FirebaseDatabase.instance.ref('companies').onValue 
      : repo._db.child('cleaning_assignments/$dateStr').onValue;
  
  await for (final event in stream) {
    if (!event.snapshot.exists) {
      yield [];
      continue;
    }
    final Object? rawData = event.snapshot.value;
    if (rawData == null) {
      yield [];
      continue;
    }
    
    final List<CleaningAssignment> allAssignments = [];

    void processAssignmentsMap(Map<dynamic, dynamic> data) {
      final assignments = data.entries.map((e) {
        final id = e.key.toString();
        final map = e.value as Map<dynamic, dynamic>;
        return CleaningAssignment.fromMap(id, map);
      }).toList();
      allAssignments.addAll(assignments);
    }

    if (isSuperAdmin) {
      final companiesMap = rawData as Map<dynamic, dynamic>;
      for (final company in companiesMap.values) {
        if (company is Map && company['cleaning_assignments'] != null) {
          final cleanings = company['cleaning_assignments'];
          if (cleanings is Map && cleanings[dateStr] != null) {
            processAssignmentsMap(cleanings[dateStr] as Map<dynamic, dynamic>);
          }
        }
      }
    } else {
      processAssignmentsMap(rawData as Map<dynamic, dynamic>);
    }
    
    yield allAssignments;
  }
});

// A StreamProvider to listen to ALL assignments across ALL dates
final allCleaningAssignmentsProvider = StreamProvider<List<CleaningAssignment>>((ref) async* {
  final repo = ref.watch(cleaningRepositoryProvider);
  
  final isSuperAdmin = repo.activeCompanyId == null;
  final stream = isSuperAdmin
      ? FirebaseDatabase.instance.ref('companies').onValue
      : repo._db.child('cleaning_assignments').onValue;
  
  await for (final event in stream) {
    final Object? rawData = event.snapshot.value;
    if (rawData == null) {
      yield [];
      continue;
    }
    
    final List<CleaningAssignment> allAssignments = [];
    
    void processAllAssignmentsMap(Map<dynamic, dynamic> data) {
      for (var dateEntry in data.entries) {
        final dateMap = dateEntry.value as Map<dynamic, dynamic>;
        for (var assignmentEntry in dateMap.entries) {
          final id = assignmentEntry.key.toString();
          final map = assignmentEntry.value as Map<dynamic, dynamic>;
          allAssignments.add(CleaningAssignment.fromMap(id, map));
        }
      }
    }

    if (isSuperAdmin) {
      final companiesMap = rawData as Map<dynamic, dynamic>;
      for (final company in companiesMap.values) {
        if (company is Map && company['cleaning_assignments'] != null) {
          processAllAssignmentsMap(company['cleaning_assignments'] as Map<dynamic, dynamic>);
        }
      }
    } else {
      processAllAssignmentsMap(rawData as Map<dynamic, dynamic>);
    }
    
    yield allAssignments;
  }
});

class CleaningAssignmentRepository {
  final String? activeCompanyId;
  CleaningAssignmentRepository({this.activeCompanyId});

  DatabaseReference _getDbForCompany(String targetCompanyId) {
    if (activeCompanyId != null) return FirebaseDatabase.instance.ref('companies/$activeCompanyId');
    if (targetCompanyId.isNotEmpty) return FirebaseDatabase.instance.ref('companies/$targetCompanyId');
    return FirebaseDatabase.instance.ref();
  }
  
  Future<void> saveAssignment(CleaningAssignment assignment) async {
    // We store assignments grouped by date, and then keyed by the Reservation ID
    // That means one checkout event = one cleaning assignment
    final dateStr = assignment.date;
    final path = 'cleaning_assignments/$dateStr/${assignment.reservationId}';
    
    await _getDbForCompany(assignment.companyId).child(path).set(assignment.toMap());
  }
  
  Future<void> deleteAssignment(String dateStr, String reservationId, String companyId) async {
    final path = 'cleaning_assignments/$dateStr/$reservationId';
    await _getDbForCompany(companyId).child(path).remove();
  }
}
