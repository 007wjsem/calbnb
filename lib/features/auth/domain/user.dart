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
  final List<String> companyIds;
  final String? activeCompanyId;

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
    this.companyIds = const [],
    this.activeCompanyId,
  });

  User copyWith({
    String? username,
    AppRole? role,
    bool? isActive,
    String? email,
    String? phone,
    String? address,
    String? emergencyContact,
    double? payRate,
    List<String>? companyIds,
    String? activeCompanyId,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      payRate: payRate ?? this.payRate,
      companyIds: companyIds ?? this.companyIds,
      activeCompanyId: activeCompanyId ?? this.activeCompanyId,
    );
  }
}
