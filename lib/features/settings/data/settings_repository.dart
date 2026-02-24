import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';

class SettingsRepository {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('system_settings/property_order');

  Future<List<String>> fetchPropertyOrder() async {
    final snapshot = await _ref.get();
    if (snapshot.value != null) {
      final value = snapshot.value.toString();
      try {
        final List<dynamic> decoded = jsonDecode(value);
        return decoded.map((e) => e.toString()).toList();
      } catch (e) {
        // If it was previously saved as a raw CSV string, fallback to split
        if (value.contains(',')) {
          return value.split(',').map((e) => e.trim()).toList();
        }
      }
    }
    return [];
  }

  Future<void> savePropertyOrder(List<String> order) async {
    final jsonString = jsonEncode(order);
    await _ref.set(jsonString);
  }
}
