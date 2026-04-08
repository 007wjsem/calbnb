import 'package:flutter/foundation.dart';

@immutable
class Lead {
  final String id;
  final String name;
  final String contactPreference; // 'email' or 'whatsapp'
  final String contactInfo;
  final String? countryCode;
  final String status; // 'new', 'contacted', 'registered'
  final DateTime timestamp;

  const Lead({
    required this.id,
    required this.name,
    required this.contactPreference,
    required this.contactInfo,
    this.countryCode,
    required this.status,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'contactPreference': contactPreference,
      'contactInfo': contactInfo,
      'countryCode': countryCode,
      'status': status,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory Lead.fromMap(String id, Map<dynamic, dynamic> map) {
    return Lead(
      id: id,
      name: map['name'] ?? '',
      contactPreference: map['contactPreference'] ?? 'email',
      contactInfo: map['contactInfo'] ?? '',
      countryCode: map['countryCode'],
      status: map['status'] ?? 'new',
      timestamp: DateTime.parse(map['timestamp'] ?? DateTime.now().toIso8601String()),
    );
  }

  Lead copyWith({
    String? id,
    String? name,
    String? contactPreference,
    String? contactInfo,
    String? countryCode,
    String? status,
    DateTime? timestamp,
  }) {
    return Lead(
      id: id ?? this.id,
      name: name ?? this.name,
      contactPreference: contactPreference ?? this.contactPreference,
      contactInfo: contactInfo ?? this.contactInfo,
      countryCode: countryCode ?? this.countryCode,
      status: status ?? this.status,
      timestamp: timestamp ?? this.timestamp,
    );
  }
}
