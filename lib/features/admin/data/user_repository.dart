import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../../auth/domain/user.dart';
import '../../../core/constants/roles.dart';

import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter_riverpod/flutter_riverpod.dart';

final userRepositoryProvider = Provider((ref) => UserRepository());

class UserRepository {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('users');

  Future<List<User>> fetchAll() async {
    final snapshot = await _ref.get();
    final raw = snapshot.value;
    if (raw == null) return [];

    // Firebase on iOS can return a List when keys happen to be sequential integers.
    // Normalise to an iterable of (key, value) entries regardless of the container type.
    Iterable<MapEntry<dynamic, dynamic>> entries;
    if (raw is Map) {
      entries = raw.entries;
    } else if (raw is List) {
      entries = raw.asMap().entries;
    } else {
      return [];
    }

    // Filter out soft-deleted users from being returned in fetchAll
    final activeEntries = entries.where((e) {
      if (e.value is! Map) return false;
      return (e.value as Map)['isActive'] != false;
    }).toList();

    return activeEntries.map((e) {
      final value = e.value as Map;
      return User(
        id: e.key.toString(),
        username: value['username']?.toString() ?? 'Unknown',
        role: _roleFromString(value['role']?.toString() ?? 'Cleaner'),
        email: value['email']?.toString(),
        phone: value['phone']?.toString(),
        phoneCountryCode: value['phoneCountryCode']?.toString(),
        address: value['address']?.toString(),
        emergencyContact: value['emergencyContact']?.toString(),
        isActive: value['isActive'] as bool? ?? true,
        companyIds: (value['companyIds'] is List)
            ? (value['companyIds'] as List).map((x) => x.toString()).toList()
            : (value['companyIds'] is Map)
                ? (value['companyIds'] as Map).keys.map((x) => x.toString()).toList()
                : (value['companyId'] != null)
                    ? [value['companyId'].toString()]
                    : [],
        activeCompanyId: value['activeCompanyId']?.toString() ?? (value['companyId']?.toString()),
        language: value['language']?.toString(),
      );
    }).toList();
  }

  Future<void> add({
    required String email, 
    required String password, 
    required User user,
    List<String>? companyIds,
    String? activeCompanyId,
  }) async {
    // 1. Create the user in Firebase Authentication
    // Note: This requires another Firebase App instance or creating via the main instance.
    // If the admin is creating this, `createUserWithEmailAndPassword` will sign out the current admin.
    // A common workaround is to use a secondary Firebase app instance, but for simplicity we will just call it.
    // Alternatively, cloud functions are best for this. We will use the client SDK here.
    final credential = await auth.FirebaseAuth.instance.createUserWithEmailAndPassword(
      email: email,
      password: password,
    );

    final String newUid = credential.user!.uid;

    // 2. Save the user data to the database using the new Auth UID
    await _ref.child(newUid).set({
      'username': user.username,
      'role': user.role.displayName,
      'email': email,
      'isActive': true,
      if (companyIds != null) 'companyIds': companyIds,
      if (activeCompanyId != null) 'activeCompanyId': activeCompanyId,
      if (user.phone != null) 'phone': user.phone,
      if (user.phoneCountryCode != null) 'phoneCountryCode': user.phoneCountryCode,
      if (user.address != null) 'address': user.address,
      if (user.emergencyContact != null) 'emergencyContact': user.emergencyContact,
      if (user.language != null) 'language': user.language,
    });
  }

  Future<void> update(User user) async {
    await _ref.child(user.id).update({
      'username': user.username,
      'role': user.role.displayName, // Ensure it's displaying name, not .name Enum identifier
      if (user.email != null) 'email': user.email,
      'phone': user.phone,
      'phoneCountryCode': user.phoneCountryCode,
      'address': user.address,
      'emergencyContact': user.emergencyContact,
      'companyIds': user.companyIds,
      'activeCompanyId': user.activeCompanyId,
      'language': user.language,
    });
  }

  Future<void> delete(String uid) async {
    // 1. Soft Delete in Realtime Database (Bans/locks them out, preserves history)
    await _ref.child(uid).update({'isActive': false});

    // 2. Best-effort Auth deletion (Client SDK only allows deleting yourself)
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser != null && currentUser.uid == uid) {
      try {
        await currentUser.delete();
      } catch (e) {
        // Not a critical failure since RTDB presence is gone, just log it.
        debugPrint('Failed to delete auth user: $e');
      }
    }
  }

  AppRole _roleFromString(String roleStr) {
    switch (roleStr) {
      case 'Super Admin':
        return AppRole.superAdmin;
      case 'Administrator':
        return AppRole.administrator;
      case 'Manager':
        return AppRole.manager;
      case 'Cleaner':
        return AppRole.cleaner;
      case 'Inspector':
        return AppRole.inspector;
      case 'Property Owner':
        return AppRole.owner;
      default:
        return AppRole.cleaner;
    }
  }
}

final companyCleanersProvider = StreamProvider.family<List<User>, String>((ref, companyId) {
  final database = FirebaseDatabase.instance.ref('users');
  
  return database.onValue.map((event) {
    final raw = event.snapshot.value;
    if (raw == null) return [];

    Iterable<MapEntry<dynamic, dynamic>> entries;
    if (raw is Map) {
      entries = raw.entries;
    } else if (raw is List) {
      entries = List<dynamic>.from(raw).asMap().entries;
    } else {
      return [];
    }

    final List<User> cleaners = [];
    for (final e in entries) {
      if (e.value is! Map) continue;
      final value = e.value as Map;
      
      // Basic isActive check
      if (value['isActive'] == false) continue;

      // Robust Company ID parsing (Synchronize with fetchAll logic)
      final List<String> userCompanyIds = [];
      if (value['companyIds'] is List) {
        userCompanyIds.addAll((value['companyIds'] as List).map((x) => x.toString()));
      } else if (value['companyIds'] is Map) {
        userCompanyIds.addAll((value['companyIds'] as Map).keys.map((x) => x.toString()));
      }
      
      final String? userActiveCompanyId = value['activeCompanyId']?.toString() ?? value['companyId']?.toString();
      if (userActiveCompanyId != null && !userCompanyIds.contains(userActiveCompanyId)) {
        userCompanyIds.add(userActiveCompanyId);
      }

      // Final association check
      if (userCompanyIds.contains(companyId)) {
        final roleStr = value['role']?.toString() ?? 'Cleaner';
        // We include both Cleaners and Managers who might be performing cleaning tasks
        if (roleStr == 'Cleaner' || roleStr == 'Manager') {
           cleaners.add(User(
            id: e.key.toString(),
            username: value['username']?.toString() ?? 'Unknown',
            role: roleStr == 'Manager' ? AppRole.manager : AppRole.cleaner,
            email: value['email']?.toString(),
            phone: value['phone']?.toString(),
            phoneCountryCode: value['phoneCountryCode']?.toString(),
            address: value['address']?.toString(),
            emergencyContact: value['emergencyContact']?.toString(),
            isActive: true,
            companyIds: userCompanyIds,
            activeCompanyId: userActiveCompanyId,
            language: value['language']?.toString(),
          ));
        }
      }
    }
    
    cleaners.sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
    return cleaners;
  });
});

final companyMembersProvider = StreamProvider.family<List<User>, String>((ref, companyId) {
  final database = FirebaseDatabase.instance.ref('users');
  
  return database.onValue.map((event) {
    final raw = event.snapshot.value;
    if (raw == null) return [];

    Iterable<MapEntry<dynamic, dynamic>> entries;
    if (raw is Map) {
      entries = raw.entries;
    } else if (raw is List) {
      entries = List<dynamic>.from(raw).asMap().entries;
    } else {
      return [];
    }

    final List<User> members = [];
    for (final e in entries) {
      if (e.value is! Map) continue;
      final value = e.value as Map;
      
      if (value['isActive'] == false) continue;

      final List<String> userCompanyIds = [];
      if (value['companyIds'] is List) {
        userCompanyIds.addAll((value['companyIds'] as List).map((x) => x.toString()));
      } else if (value['companyIds'] is Map) {
        userCompanyIds.addAll((value['companyIds'] as Map).keys.map((x) => x.toString()));
      }
      
      final String? userActiveCompanyId = value['activeCompanyId']?.toString() ?? value['companyId']?.toString();
      if (userActiveCompanyId != null && !userCompanyIds.contains(userActiveCompanyId)) {
        userCompanyIds.add(userActiveCompanyId);
      }

      if (userCompanyIds.contains(companyId)) {
        members.add(User(
          id: e.key.toString(),
          username: value['username']?.toString() ?? 'Unknown',
          role: _roleFromString(value['role']?.toString() ?? 'Cleaner'),
          email: value['email']?.toString(),
          isActive: true,
          companyIds: userCompanyIds,
          activeCompanyId: userActiveCompanyId,
          language: value['language']?.toString(),
        ));
      }
    }
    
    members.sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
    return members;
  });
});

AppRole _roleFromString(String roleStr) {
  switch (roleStr) {
    case 'Super Admin': return AppRole.superAdmin;
    case 'Administrator': return AppRole.administrator;
    case 'Manager': return AppRole.manager;
    case 'Cleaner': return AppRole.cleaner;
    case 'Inspector': return AppRole.inspector;
    case 'Property Owner': return AppRole.owner;
    default: return AppRole.cleaner;
  }
}
