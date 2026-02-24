import '../../../core/constants/roles.dart';

class User {
  final String id;
  final String username;
  final AppRole role;
  final String? email;
  final String? phone;
  final String? address;
  final String? emergencyContact;
  final double? payRate; // Optional, useful for cleaners or inspectors
  final bool isActive;

  const User({
    required this.id,
    required this.username,
    required this.role,
    this.isActive = true,
    this.email,
    this.phone,
    this.address,
    this.emergencyContact,
    this.payRate,
  });
}
