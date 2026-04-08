enum PaymentMethod {
  transfer,
  yape,
  plin
}

class PaymentSettings {
  final String userId;
  final PaymentMethod method;
  final String? bankName;
  final String? savingsNumber;
  final String? cci;

  const PaymentSettings({
    required this.userId,
    required this.method,
    this.bankName,
    this.savingsNumber,
    this.cci,
  });

  factory PaymentSettings.fromJson(Map<String, dynamic> json) {
    return PaymentSettings(
      userId: json['userId'] as String,
      method: PaymentMethod.values.firstWhere(
        (e) => e.name == json['method'],
        orElse: () => PaymentMethod.transfer,
      ),
      bankName: json['bankName'] as String?,
      savingsNumber: json['savingsNumber'] as String?,
      cci: json['cci'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'method': method.name,
      'bankName': bankName,
      'savingsNumber': savingsNumber,
      'cci': cci,
    };
  }
}
