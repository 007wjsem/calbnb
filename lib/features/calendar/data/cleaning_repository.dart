import 'dart:convert';
import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';
import '../../auth/data/auth_repository.dart';
import '../domain/cleaning_assignment.dart';

final cleaningRepositoryProvider = Provider((ref) {
  final activeCompanyId = ref.watch(authControllerProvider)?.activeCompanyId;
  return CleaningAssignmentRepository(activeCompanyId: activeCompanyId);
});

// A StreamProvider to listen to assignments for a specific date
final defaultDateFormatter = DateFormat('yyyy-MM-dd');

/// Fetches the list of company IDs without pulling the entire companies/ tree.
/// Uses Firebase REST API shallow=true to get only the keys.
Future<List<String>> _fetchCompanyIds() async {
  const projectId = 'calbnb-71137';
  const url = 'https://$projectId-default-rtdb.firebaseio.com/companies.json?shallow=true';
  try {
    final response = await http.get(Uri.parse(url));
    if (response.statusCode == 200) {
      final decoded = jsonDecode(response.body);
      if (decoded is Map) return decoded.keys.map((k) => k.toString()).toList();
    }
  } catch (_) {}
  return [];
}

final dailyCleaningAssignmentsProvider = StreamProvider.family<List<CleaningAssignment>, DateTime>((ref, date) async* {
  final repo = ref.watch(cleaningRepositoryProvider);
  final dateStr = defaultDateFormatter.format(date);

  final isSuperAdmin = repo.activeCompanyId == null;

  if (!isSuperAdmin) {
    // Non Super Admin: read single company path directly
    final stream = repo._getDbForCompany(repo.activeCompanyId!).child('cleaning_assignments/$dateStr').onValue;
    await for (final event in stream) {
      if (!event.snapshot.exists || event.snapshot.value == null) { yield []; continue; }
      final rawData = event.snapshot.value;
      
      final Iterable<MapEntry<dynamic, dynamic>> entries;
      if (rawData is Map) {
        entries = rawData.entries;
      } else if (rawData is List) {
        entries = List<dynamic>.from(rawData).asMap().entries;
      } else {
        yield [];
        continue;
      }

      final assignments = <CleaningAssignment>[];
      for (final entry in entries) {
        if (entry.value is! Map) continue;
        try { assignments.add(CleaningAssignment.fromMap(entry.key.toString(), Map<dynamic, dynamic>.from(entry.value as Map))); } catch (_) {}
      }
      yield assignments;
    }
  } else {
    // Super Admin: fetch company IDs first (shallow), then watch each individually
    final companyIds = await _fetchCompanyIds();
    if (companyIds.isEmpty) { yield []; return; }

    final Map<String, List<CleaningAssignment>> resultsMap = {};
    for (final id in companyIds) {
      resultsMap[id] = [];
    }

    yield []; // Yield initial empty

    // We don't have rxdart, so we use a StreamController to merge events natively
    final controller = StreamController<List<CleaningAssignment>>();
    final subscriptions = <StreamSubscription>[];

    void emitUpdate() {
      if (!controller.isClosed) {
        controller.add(resultsMap.values.expand((l) => l).toList());
      }
    }

    for (final id in companyIds) {
      final sub = FirebaseDatabase.instance.ref('companies/$id/cleaning_assignments/$dateStr').onValue.listen((event) {
        final assignments = <CleaningAssignment>[];
        if (event.snapshot.exists && event.snapshot.value != null) {
          final rawData = event.snapshot.value;
          final Iterable<MapEntry<dynamic, dynamic>> entries;
          if (rawData is Map) {
            entries = rawData.entries;
          } else if (rawData is List) {
            entries = List<dynamic>.from(rawData).asMap().entries;
          } else {
            resultsMap[id] = [];
            emitUpdate();
            return;
          }

          for (final entry in entries) {
            if (entry.value is! Map) continue;
            try { assignments.add(CleaningAssignment.fromMap(entry.key.toString(), Map<dynamic, dynamic>.from(entry.value as Map))); } catch (_) {}
          }
        }
        resultsMap[id] = assignments;
        emitUpdate();
      });
      subscriptions.add(sub);
    }

    ref.onDispose(() {
      for (final sub in subscriptions) {
        sub.cancel();
      }
      controller.close();
    });

    yield* controller.stream;
  }
});

final allCleaningAssignmentsProvider = StreamProvider<List<CleaningAssignment>>((ref) async* {
  final repo = ref.watch(cleaningRepositoryProvider);
  final isSuperAdmin = repo.activeCompanyId == null;

  if (!isSuperAdmin) {
    final stream = repo._getDbForCompany(repo.activeCompanyId!).child('cleaning_assignments').onValue;
    await for (final event in stream) {
      final Object? rawData = event.snapshot.value;
      if (rawData == null) { yield []; continue; }
      final allAssignments = <CleaningAssignment>[];
      if (rawData is! Map) { yield []; continue; }
      for (final dateEntry in (rawData).entries) {
        if (dateEntry.value is! Map) continue;
        for (final entry in (dateEntry.value as Map<dynamic, dynamic>).entries) {
          if (entry.value is! Map) continue;
          try { allAssignments.add(CleaningAssignment.fromMap(entry.key.toString(), Map<dynamic, dynamic>.from(entry.value as Map))); } catch (_) {}
        }
      }
      yield allAssignments;
    }
  } else {
    final companyIds = await _fetchCompanyIds();
    if (companyIds.isEmpty) { yield []; return; }
    
    yield []; // Yield initial empty

    final controller = StreamController<List<CleaningAssignment>>();
    final Map<String, List<CleaningAssignment>> resultsPerCompany = {};
    for (final id in companyIds) {
      resultsPerCompany[id] = [];
    }

    void emitUpdate() {
      if (!controller.isClosed) {
        controller.add(resultsPerCompany.values.expand((l) => l).toList());
      }
    }

    final subscriptions = <StreamSubscription>[];
    for (final id in companyIds) {
      final sub = FirebaseDatabase.instance.ref('companies/$id/cleaning_assignments').onValue.listen((event) {
        final assignments = <CleaningAssignment>[];
        final rawData = event.snapshot.value;
        if (rawData != null) {
          final Iterable<MapEntry<dynamic, dynamic>> dateEntries;
          if (rawData is Map) {
            dateEntries = rawData.entries;
          } else if (rawData is List) {
            dateEntries = List<dynamic>.from(rawData).asMap().entries;
          } else {
            return;
          }

          for (final dateEntry in dateEntries) {
            final assignmentsValue = dateEntry.value;
            if (assignmentsValue == null) continue;
            
            final Iterable<MapEntry<dynamic, dynamic>> assignEntries;
            if (assignmentsValue is Map) {
              assignEntries = assignmentsValue.entries;
            } else if (assignmentsValue is List) {
              assignEntries = List<dynamic>.from(assignmentsValue).asMap().entries;
            } else {
              continue;
            }

            for (final entry in assignEntries) {
              final v = entry.value;
              if (v is Map) {
                try {
                  assignments.add(CleaningAssignment.fromMap(entry.key.toString(), Map<dynamic, dynamic>.from(v)));
                } catch (_) {}
              }
            }
          }
        }
        resultsPerCompany[id] = assignments;
        emitUpdate();
      });
      subscriptions.add(sub);
    }

    ref.onDispose(() {
      for (final sub in subscriptions) {
        sub.cancel();
      }
      controller.close();
    });

    yield* controller.stream;
  }
});

/// A StreamProvider to listen to assignments within a date range (Board / Timeline views)
final dateRangeCleaningAssignmentsProvider = StreamProvider.family<List<CleaningAssignment>, (DateTime, DateTime)>((ref, range) async* {
  final startDate = range.$1;
  final endDate = range.$2;
  final repo = ref.watch(cleaningRepositoryProvider);

  final startStr = defaultDateFormatter.format(startDate);
  final endStr = defaultDateFormatter.format(endDate);

  final isSuperAdmin = repo.activeCompanyId == null;

  void processDateRange(dynamic cleaningsValue, List<CleaningAssignment> out) {
    if (cleaningsValue == null) return;
    
    final Iterable<MapEntry<dynamic, dynamic>> dateEntries;
    if (cleaningsValue is Map) {
      dateEntries = cleaningsValue.entries;
    } else if (cleaningsValue is List) {
      dateEntries = List<dynamic>.from(cleaningsValue).asMap().entries;
    } else {
      return;
    }

    for (final dateEntry in dateEntries) {
      final dateKey = dateEntry.key.toString();
      if (dateKey.compareTo(startStr) >= 0 && dateKey.compareTo(endStr) <= 0) {
        final assignmentsValue = dateEntry.value;
        if (assignmentsValue == null) continue;
        
        final Iterable<MapEntry<dynamic, dynamic>> assignEntries;
        if (assignmentsValue is Map) {
          assignEntries = assignmentsValue.entries;
        } else if (assignmentsValue is List) {
          assignEntries = List<dynamic>.from(assignmentsValue).asMap().entries;
        } else {
          continue;
        }

        for (final entry in assignEntries) {
          final v = entry.value;
          if (v is Map) {
            try {
              out.add(CleaningAssignment.fromMap(entry.key.toString(), Map<dynamic, dynamic>.from(v)));
            } catch (_) {}
          }
        }
      }
    }
  }

  if (!isSuperAdmin) {
    final stream = repo._getDbForCompany(repo.activeCompanyId!).child('cleaning_assignments').onValue;
    await for (final event in stream) {
      if (!event.snapshot.exists || event.snapshot.value == null) { yield []; continue; }
      final assignments = <CleaningAssignment>[];
      processDateRange(event.snapshot.value, assignments);
      yield assignments;
    }
  } else {
    final companyIds = await _fetchCompanyIds();
    if (companyIds.isEmpty) { yield []; return; }
    
    yield []; // Yield initial empty

    final controller = StreamController<List<CleaningAssignment>>();
    final Map<String, List<CleaningAssignment>> resultsPerCompany = {};
    for (final id in companyIds) {
      resultsPerCompany[id] = [];
    }

    void emitUpdate() {
      if (!controller.isClosed) {
        controller.add(resultsPerCompany.values.expand((l) => l).toList());
      }
    }

    final subscriptions = <StreamSubscription>[];

    for (final id in companyIds) {
      final sub = FirebaseDatabase.instance.ref('companies/$id/cleaning_assignments').onValue.listen((event) {
        final assignments = <CleaningAssignment>[];
        processDateRange(event.snapshot.value, assignments);
        resultsPerCompany[id] = assignments;
        emitUpdate();
      });
      subscriptions.add(sub);
    }

    ref.onDispose(() {
      for (final sub in subscriptions) {
        sub.cancel();
      }
      controller.close();
    });

    yield* controller.stream;
  }
});


/// A StreamProvider to listen to ALL assignments for a given company (useful for filtering locally)
final monthlyCleaningAssignmentsProvider = StreamProvider.family<List<CleaningAssignment>, String>((ref, companyId) async* {
  final repo = ref.watch(cleaningRepositoryProvider);
  
  // Realtime Database structure: companies/{companyId}/cleaning_assignments/{date}/{id}
  final stream = repo._getDbForCompany(companyId).child('cleaning_assignments').onValue;
  
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
    // Firebase on iOS may return a List when keys are sequential integers.
    final Iterable<MapEntry<dynamic, dynamic>> dateEntries;
    if (rawData is Map) {
      dateEntries = rawData.entries;
    } else if (rawData is List) {
      dateEntries = List<dynamic>.from(rawData as List).asMap().entries;
    } else {
      yield [];
      continue;
    }
    
    for (final dateEntry in dateEntries) {
      if (dateEntry.value is! Map) continue;
      final dailyCleanings = dateEntry.value as Map;
      final assignments = dailyCleanings.entries
          .where((e) => e.value is Map)
          .map((e) => CleaningAssignment.fromMap(e.key.toString(), Map<dynamic, dynamic>.from(e.value as Map)))
          .toList();
      allAssignments.addAll(assignments);
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
