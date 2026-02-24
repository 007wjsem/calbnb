import 'package:firebase_database/firebase_database.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../domain/cleaning_assignment.dart';

final cleaningRepositoryProvider = Provider((ref) => CleaningAssignmentRepository());

// A StreamProvider to listen to assignments for a specific date
final defaultDateFormatter = DateFormat('yyyy-MM-dd');

final dailyCleaningAssignmentsProvider = StreamProvider.family<List<CleaningAssignment>, DateTime>((ref, date) async* {
  final repo = ref.watch(cleaningRepositoryProvider);
  final dateStr = defaultDateFormatter.format(date);
  
  // Listen to the node for this specific date
  // Data structure: cleaning_assignments / YYYY-MM-DD / reservationId -> CleaningAssignment
  final stream = repo._db.child('cleaning_assignments/$dateStr').onValue;
  
  await for (final event in stream) {
    final Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) {
      yield [];
      continue;
    }
    
    final assignments = data.entries.map((e) {
      final id = e.key.toString();
      final map = e.value as Map<dynamic, dynamic>;
      return CleaningAssignment.fromMap(id, map);
    }).toList();
    
    yield assignments;
  }
});

// A StreamProvider to listen to ALL assignments across ALL dates
final allCleaningAssignmentsProvider = StreamProvider<List<CleaningAssignment>>((ref) async* {
  final repo = ref.watch(cleaningRepositoryProvider);
  
  // Listen to the root node of all cleaning assignments
  final stream = repo._db.child('cleaning_assignments').onValue;
  
  await for (final event in stream) {
    final Map<dynamic, dynamic>? data = event.snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) {
      yield [];
      continue;
    }
    
    // Data structure is: cleaning_assignments -> YYYY-MM-DD -> reservationId -> CleaningAssignment
    final List<CleaningAssignment> allAssignments = [];
    
    for (var dateEntry in data.entries) {
      final dateMap = dateEntry.value as Map<dynamic, dynamic>;
      
      for (var assignmentEntry in dateMap.entries) {
        final id = assignmentEntry.key.toString();
        final map = assignmentEntry.value as Map<dynamic, dynamic>;
        allAssignments.add(CleaningAssignment.fromMap(id, map));
      }
    }
    
    yield allAssignments;
  }
});

class CleaningAssignmentRepository {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  
  Future<void> saveAssignment(CleaningAssignment assignment) async {
    // We store assignments grouped by date, and then keyed by the Reservation ID
    // That means one checkout event = one cleaning assignment
    final dateStr = assignment.date;
    final path = 'cleaning_assignments/$dateStr/${assignment.reservationId}';
    
    await _db.child(path).set(assignment.toMap());
  }
  
  Future<void> deleteAssignment(String dateStr, String reservationId) async {
    final path = 'cleaning_assignments/$dateStr/$reservationId';
    await _db.child(path).remove();
  }
}
