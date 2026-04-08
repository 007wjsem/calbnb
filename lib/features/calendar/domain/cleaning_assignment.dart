import 'package:calbnb/l10n/app_localizations.dart';

enum CleaningStatus {
  assigned,
  inProgress,
  pendingInspection,
  fixNeeded,
  approved,
}

extension CleaningStatusExtension on CleaningStatus {
  String localizedName(AppLocalizations l10n) {
    switch (this) {
      case CleaningStatus.assigned:
        return l10n.statusAssigned;
      case CleaningStatus.inProgress:
        return l10n.statusInProgress;
      case CleaningStatus.pendingInspection:
        return l10n.statusPendingInspection;
      case CleaningStatus.fixNeeded:
        return l10n.statusFixNeeded;
      case CleaningStatus.approved:
        return l10n.statusApprovedCompleted;
    }
  }
}

class IncidentReport {
  final String text;
  final List<String> photos;
  final String timestamp;

  IncidentReport({required this.text, this.photos = const [], required this.timestamp});

  factory IncidentReport.fromMap(Map<dynamic, dynamic> map) {
    return IncidentReport(
      text: map['text']?.toString() ?? '',
      photos: (map['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      timestamp: map['timestamp']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
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
      photos: (map['photos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      timestamp: map['timestamp']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toMap() => {
    'text': text,
    'photos': photos,
    'timestamp': timestamp,
  };
}

class CleanerWithFee {
  final String id;
  final String name;
  final double fee;

  CleanerWithFee({required this.id, required this.name, required this.fee});

  factory CleanerWithFee.fromMap(Map<dynamic, dynamic> map) {
    return CleanerWithFee(
      id: map['id']?.toString() ?? '',
      name: map['name']?.toString() ?? '',
      fee: double.tryParse(map['fee']?.toString() ?? '0') ?? 0.0,
    );
  }

  Map<String, dynamic> toMap() => {
    'id': id,
    'name': name,
    'fee': fee,
  };
}

class CleaningAssignment {
  final String id;
  final String companyId;
  final String reservationId; // The ID of the Checkout reservation
  final String propertyId;
  final List<CleanerWithFee> cleaners;
  final String mainCleanerId;
  final String? inspectorId; 
  final String? inspectorName;
  final String date; // YYYY-MM-DD
  final String assignedAt; // Added to track when the task was created
  final String observation;
  final CleaningStatus status;
  final String startTime;
  final String endTime;
  final double propertyCleaningFee; // Amount charged to the owner
  final List<String> proofPhotos;
  final List<IncidentReport> incidents;
  final List<InspectionFinding> findings;

  CleaningAssignment({
    required this.id,
    required this.companyId,
    required this.reservationId,
    required this.propertyId,
    required this.cleaners,
    required this.mainCleanerId,
    this.inspectorId,
    this.inspectorName,
    required this.date,
    required this.assignedAt,
    this.observation = '',
    this.status = CleaningStatus.assigned,
    this.startTime = '',
    this.endTime = '',
    this.propertyCleaningFee = 0.0,
    this.proofPhotos = const [],
    this.incidents = const [],
    this.findings = const [],
  });

  CleaningAssignment copyWith({
    String? id,
    String? companyId,
    String? reservationId,
    String? propertyId,
    List<CleanerWithFee>? cleaners,
    String? mainCleanerId,
    String? inspectorId,
    String? inspectorName,
    String? date,
    String? assignedAt,
    String? observation,
    CleaningStatus? status,
    String? startTime,
    String? endTime,
    double? propertyCleaningFee,
    List<String>? proofPhotos,
    List<IncidentReport>? incidents,
    List<InspectionFinding>? findings,
  }) {
    return CleaningAssignment(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      reservationId: reservationId ?? this.reservationId,
      propertyId: propertyId ?? this.propertyId,
      cleaners: cleaners ?? this.cleaners,
      mainCleanerId: mainCleanerId ?? this.mainCleanerId,
      inspectorId: inspectorId ?? this.inspectorId,
      inspectorName: inspectorName ?? this.inspectorName,
      date: date ?? this.date,
      assignedAt: assignedAt ?? this.assignedAt,
      observation: observation ?? this.observation,
      status: status ?? this.status,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      propertyCleaningFee: propertyCleaningFee ?? this.propertyCleaningFee,
      proofPhotos: proofPhotos ?? this.proofPhotos,
      incidents: incidents ?? this.incidents,
      findings: findings ?? this.findings,
    );
  }

  factory CleaningAssignment.fromMap(String id, Map<dynamic, dynamic> map) {
    // Migration logic for multiple cleaners
    List<CleanerWithFee> cleanersList = [];
    if (map['cleaners'] != null) {
      final List<dynamic> cleanersRaw = map['cleaners'] as List<dynamic>;
      cleanersList = cleanersRaw.map((e) => CleanerWithFee.fromMap(e as Map<dynamic, dynamic>)).toList();
    } else if (map['cleanerId'] != null) {
      // Legacy single cleaner data
      cleanersList = [
        CleanerWithFee(
          id: map['cleanerId'].toString(),
          name: map['cleanerName']?.toString() ?? '',
          fee: double.tryParse(map['cleanerFee']?.toString() ?? '0') ?? 0.0,
        )
      ];
    }

    return CleaningAssignment(
      id: id,
      companyId: map['companyId']?.toString() ?? '',
      reservationId: map['reservationId']?.toString() ?? '',
      propertyId: map['propertyId']?.toString() ?? '',
      cleaners: cleanersList,
      mainCleanerId: map['mainCleanerId']?.toString() ?? (cleanersList.isNotEmpty ? cleanersList.first.id : ''),
      inspectorId: map['inspectorId']?.toString(),
      inspectorName: map['inspectorName']?.toString(),
      date: map['date']?.toString() ?? '',
      assignedAt: map['assignedAt'] as String? ?? DateTime.now().toIso8601String(),
      observation: map['observation']?.toString() ?? '',
      status: CleaningStatus.values.firstWhere(
        (e) => e.name == map['status'],
        orElse: () => CleaningStatus.assigned,
      ),
      startTime: map['startTime']?.toString() ?? '',
      endTime: map['endTime']?.toString() ?? '',
      propertyCleaningFee: double.tryParse(map['propertyCleaningFee']?.toString() ?? '0') ?? 0.0,
      proofPhotos: (map['proofPhotos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      incidents: (map['incidents'] as List<dynamic>?)?.map((e) => IncidentReport.fromMap(e as Map<dynamic, dynamic>)).toList() ?? [],
      findings: (map['findings'] as List<dynamic>?)?.map((e) => InspectionFinding.fromMap(e as Map<dynamic, dynamic>)).toList() ?? [],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'reservationId': reservationId,
      'propertyId': propertyId,
      'cleaners': cleaners.map((e) => e.toMap()).toList(),
      'mainCleanerId': mainCleanerId,
      'inspectorId': inspectorId,
      'inspectorName': inspectorName,
      'date': date,
      'assignedAt': assignedAt,
      'observation': observation,
      'status': status.name,
      'startTime': startTime,
      'endTime': endTime,
      'propertyCleaningFee': propertyCleaningFee,
      'proofPhotos': proofPhotos,
      'incidents': incidents.map((e) => e.toMap()).toList(),
      'findings': findings.map((e) => e.toMap()).toList(),
    };
  }
}
