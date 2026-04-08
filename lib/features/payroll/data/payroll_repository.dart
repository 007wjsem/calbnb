import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'dart:typed_data';

import '../domain/payment_settings.dart';
import '../domain/payroll_payment.dart';

part 'payroll_repository.g.dart';

class PayrollRepository {
  final DatabaseReference _db = FirebaseDatabase.instance.ref();
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<PaymentSettings?> getPaymentSettings(String userId) async {
    final snap = await _db.child('payment_settings').child(userId).get();
    if (snap.exists && snap.value != null) {
      return PaymentSettings.fromJson(Map<String, dynamic>.from(snap.value as Map));
    }
    return null;
  }

  Future<void> savePaymentSettings(PaymentSettings settings) async {
    await _db.child('payment_settings').child(settings.userId).set(settings.toJson());
  }

  Future<String> uploadProofOfPayment(String companyId, String cleanerId, String filename, Uint8List imageBytes, String contentType) async {
    final ref = _storage.ref().child('payroll_proofs').child(companyId).child(cleanerId).child(filename);
    final metadata = SettableMetadata(contentType: contentType);
    final uploadTask = await ref.putData(imageBytes, metadata);
    return await ref.getDownloadURL();
  }

  Future<void> savePayrollPayment(PayrollPayment payment) async {
    await _db.child('payroll_payments').child(payment.companyId).child(payment.cleanerId).child(payment.id).set(payment.toJson());
  }

  Stream<List<PayrollPayment>> watchCleanerPayments(String companyId, String cleanerId) {
    return _db.child('payroll_payments').child(companyId).child(cleanerId).onValue.map((event) {
      if (!event.snapshot.exists || event.snapshot.value == null) return [];
      final map = event.snapshot.value as Map<dynamic, dynamic>;
      return map.entries.map((e) => PayrollPayment.fromJson(Map<String, dynamic>.from(e.value as Map))).toList()
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
    });
  }
}

@riverpod
PayrollRepository payrollRepository(Ref ref) {
  return PayrollRepository();
}

@riverpod
Stream<List<PayrollPayment>> cleanerPaymentsStream(Ref ref, String companyId, String cleanerId) {
  return ref.watch(payrollRepositoryProvider).watchCleanerPayments(companyId, cleanerId);
}
