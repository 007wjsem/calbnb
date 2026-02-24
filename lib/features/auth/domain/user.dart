import '../../../core/constants/roles.dart';

class User {
  final String id;
  final String username;
  final AppRole role;
  final String? email;
  final String? phone;
  final String? address;
  final String? emergencyContact;
  final double? payRate;
  final bool isActive;
  final String? companyId; // Which company this user belongs to

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
    this.companyId,
  });

  User copyWith({String? companyId}) {
    return User(
      id: id,
      username: username,
      role: role,
      isActive: isActive,
      email: email,
      phone: phone,
      address: address,
      emergencyContact: emergencyContact,
      payRate: payRate,
      companyId: companyId ?? this.companyId,
    );
  }
}
