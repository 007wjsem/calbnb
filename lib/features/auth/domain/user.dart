import '../../../core/constants/roles.dart';

class User {
  final String id;
  final String username;
  final AppRole role;
  final String? email;
  final String? phone;
  final String? phoneCountryCode;
  final String? address;
  final String? emergencyContact;
  final bool isActive;
  final List<String> companyIds;
  final String? activeCompanyId;
  final String? language;

  const User({
    required this.id,
    required this.username,
    required this.role,
    this.isActive = true,
    this.email,
    this.phone,
    this.phoneCountryCode,
    this.address,
    this.emergencyContact,
    this.companyIds = const [],
    this.activeCompanyId,
    this.language,
  });

  User copyWith({
    String? username,
    AppRole? role,
    bool? isActive,
    String? email,
    String? phone,
    String? phoneCountryCode,
    String? address,
    String? emergencyContact,
    List<String>? companyIds,
    String? activeCompanyId,
    String? language,
  }) {
    return User(
      id: id,
      username: username ?? this.username,
      role: role ?? this.role,
      isActive: isActive ?? this.isActive,
      email: email ?? this.email,
      phone: phone ?? this.phone,
      phoneCountryCode: phoneCountryCode ?? this.phoneCountryCode,
      address: address ?? this.address,
      emergencyContact: emergencyContact ?? this.emergencyContact,
      companyIds: companyIds ?? this.companyIds,
      activeCompanyId: activeCompanyId ?? this.activeCompanyId,
      language: language ?? this.language,
    );
  }
}
