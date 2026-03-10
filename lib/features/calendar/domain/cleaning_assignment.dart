enum CleaningStatus {
  assigned,
  inProgress,
  pendingInspection,
  fixNeeded,
  approved,
}

// Helper to handle both List and Map representations of "lists" from Firebase
List<T> parseFirebaseList<T>(dynamic data, T Function(Map<dynamic, dynamic>) mapper) {
  if (data == null) return [];
  if (data is List) {
    return data.whereType<Map>().map((e) => mapper(e as Map<dynamic, dynamic>)).toList();
  }
  if (data is Map) {
    return data.values.whereType<Map>().map((e) => mapper(e as Map<dynamic, dynamic>)).toList();
  }
  return [];
}

List<String> parseFirebaseStringList(dynamic data) {
  if (data == null) return [];
  if (data is List) {
    return data.map((e) => e.toString()).toList();
  }
  if (data is Map) {
    return data.values.map((e) => e.toString()).toList();
  }
  return [];
}

class IncidentReport {
  final String category;
  final String text;
  final List<String> photos;
  final String timestamp;

  IncidentReport({
    required this.category, 
    required this.text, 
    this.photos = const [], 
    required this.timestamp,
  });

  factory IncidentReport.fromMap(Map<dynamic, dynamic> map) {
    return IncidentReport(
      category: map['category']?.toString() ?? 'Others',
      text: map['text']?.toString() ?? '',
      photos: parseFirebaseStringList(map['photos']),
      timestamp: map['timestamp']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'category': category,
    'text': text,
    'photos': photos,
    'timestamp': timestamp,
  };
}

class InspectionFinding {
  final String text;
  final List<String> photos;
  final String timestamp;

  InspectionFinding({required this.text, this.photos = const [], required this.timestamp});

  factory InspectionFinding.fromMap(Map<dynamic, dynamic> map) {
    return InspectionFinding(
      text: map['text']?.toString() ?? '',
      photos: parseFirebaseStringList(map['photos']),
      timestamp: map['timestamp']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'text': text,
    'photos': photos,
    'timestamp': timestamp,
  };
}

class CleaningAssignment {
  final String id;
  final String reservationId; // The ID of the Checkout reservation
  final String propertyId;
  final String cleanerId; // Employee ID
  final String cleanerName; // Employee Name (cached for easy display)
  final String? inspectorId; 
  final String? inspectorName;
  final String date; // YYYY-MM-DD
  final String assignedAt; // Added to track when the task was created
  final String observation;
  final CleaningStatus status;
  final String startTime;
  final String endTime;
  final List<IncidentReport> incidents;
  final List<InspectionFinding> findings;

  CleaningAssignment({
    required this.id,
    required this.reservationId,
    required this.propertyId,
    required this.cleanerId,
    required this.cleanerName,
    this.inspectorId,
    this.inspectorName,
    required this.date,
    required this.assignedAt,
    this.observation = '',
    this.status = CleaningStatus.assigned,
    this.startTime = '',
    this.endTime = '',
    this.incidents = const [],
    this.findings = const [],
  });

  CleaningAssignment copyWith({
    String? id,
    String? reservationId,
    String? propertyId,
    String? cleanerId,
    String? cleanerName,
    String? inspectorId,
    String? inspectorName,
    String? date,
    String? assignedAt,
    String? observation,
    CleaningStatus? status,
    String? startTime,
    String? endTime,
    List<IncidentReport>? incidents,
    List<InspectionFinding>? findings,
  }) {
    return CleaningAssignment(
      id: id ?? this.id,
      reservationId: reservationId ?? this.reservationId,
      propertyId: propertyId ?? this.propertyId,
      cleanerId: cleanerId ?? this.cleanerId,
      cleanerName: cleanerName ?? this.cleanerName,
      inspectorId: inspectorId ?? this.inspectorId,
      inspectorName: inspectorName ?? this.inspectorName,
      date: date ?? this.date,
      assignedAt: assignedAt ?? this.assignedAt,
      observation: observation ?? this.observation,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      incidents: incidents ?? this.incidents,
      findings: findings ?? this.findings,
    );
  }

  factory CleaningAssignment.fromMap(String id, Map<dynamic, dynamic> map, {String? fallbackDate}) {
    return CleaningAssignment(
      id: id,
      reservationId: map['reservationId']?.toString() ?? '',
      propertyId: map['propertyId']?.toString() ?? '',
      cleanerId: map['cleanerId']?.toString() ?? '',
      cleanerName: map['cleanerName']?.toString() ?? '',
      inspectorId: map['inspectorId']?.toString(),
      inspectorName: map['inspectorName']?.toString(),
      date: map['date']?.toString() ?? fallbackDate ?? '',
      assignedAt: map['assignedAt']?.toString() ?? DateTime.now().toIso8601String(),
      observation: map['observation']?.toString() ?? '',
      status: CleaningStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CleaningStatus.assigned,
      ),
      startTime: map['startTime']?.toString() ?? '',
      endTime: map['endTime']?.toString() ?? '',
      incidents: parseFirebaseList(map['incidents'], (m) => IncidentReport.fromMap(m)),
      findings: parseFirebaseList(map['findings'], (m) => InspectionFinding.fromMap(m)),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'reservationId': reservationId,
      'propertyId': propertyId,
      'cleanerId': cleanerId,
      'cleanerName': cleanerName,
      'inspectorId': inspectorId,
      'inspectorName': inspectorName,
      'date': date,
      'assignedAt': assignedAt,
      'observation': observation,
      'status': status.name,
      'startTime': startTime,
      'endTime': endTime,
      'incidents': incidents.map((e) => e.toMap()).toList(),
      'findings': findings.map((e) => e.toMap()).toList(),
    };
  }
}
