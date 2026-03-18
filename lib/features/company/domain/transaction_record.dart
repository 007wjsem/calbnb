import 'package:equatable/equatable.dart';

class TransactionRecord extends Equatable {
  final String id;
  final String companyId;
  final String tierName;
  final double amount;
  final String currency;
  final String paymentMethod; // e.g., 'Apple Pay', 'Google Pay'
  final DateTime timestamp;
  final String status;
  final Map<String, dynamic> rawPayload;

  const TransactionRecord({
    required this.id,
    required this.companyId,
    required this.tierName,
    required this.amount,
    required this.currency,
    required this.paymentMethod,
    required this.timestamp,
    required this.status,
    required this.rawPayload,
  });

  Map<String, dynamic> toMap() {
    return {
      'companyId': companyId,
      'tierName': tierName,
      'amount': amount,
      'currency': currency,
      'paymentMethod': paymentMethod,
      'timestamp': timestamp.millisecondsSinceEpoch,
      'status': status,
      'rawPayload': rawPayload,
    };
  }

  factory TransactionRecord.fromMap(String id, Map<dynamic, dynamic> map) {
    return TransactionRecord(
      id: id,
      companyId: map['companyId'] ?? '',
      tierName: map['tierName'] ?? '',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      currency: map['currency'] ?? 'USD',
      paymentMethod: map['paymentMethod'] ?? 'Unknown',
      timestamp: DateTime.fromMillisecondsSinceEpoch(map['timestamp'] ?? 0),
      status: map['status'] ?? 'pending',
      rawPayload: Map<String, dynamic>.from(map['rawPayload'] ?? {}),
    );
  }

  @override
  List<Object?> get props => [
        id,
        companyId,
        tierName,
        amount,
        currency,
        paymentMethod,
        timestamp,
        status,
        rawPayload,
      ];
}
