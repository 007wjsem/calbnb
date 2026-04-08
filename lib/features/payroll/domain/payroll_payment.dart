class PayrollPayment {
  final String id;
  final String companyId;
  final String cleanerId;
  final double amount;
  final String proofPhotoUrl;
  final String payPeriodTitle;
  final String timestamp;

  const PayrollPayment({
    required this.id,
    required this.companyId,
    required this.cleanerId,
    required this.amount,
    required this.proofPhotoUrl,
    required this.payPeriodTitle,
    required this.timestamp,
  });

  factory PayrollPayment.fromJson(Map<String, dynamic> json) {
    return PayrollPayment(
      id: json['id'] as String,
      companyId: json['companyId'] as String,
      cleanerId: json['cleanerId'] as String,
      amount: (json['amount'] as num).toDouble(),
      proofPhotoUrl: json['proofPhotoUrl'] as String,
      payPeriodTitle: json['payPeriodTitle'] as String,
      timestamp: json['timestamp'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'companyId': companyId,
      'cleanerId': cleanerId,
      'amount': amount,
      'proofPhotoUrl': proofPhotoUrl,
      'payPeriodTitle': payPeriodTitle,
      'timestamp': timestamp,
    };
  }
}
