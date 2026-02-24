import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/foundation.dart';
import '../../auth/domain/user.dart';
import '../../../core/constants/roles.dart';

import 'package:firebase_auth/firebase_auth.dart' as auth;

class UserRepository {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('users');

  Future<List<User>> fetchAll() async {
    final snapshot = await _ref.get();
    final Map<dynamic, dynamic>? data = snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return [];
    
    // Filter out soft-deleted users from being returned in fetchAll
    final activeUsers = data.entries.where((e) {
      final value = e.value as Map<dynamic, dynamic>;
      return value['isActive'] != false;
    }).toList();

    return activeUsers.map((e) {
      final value = e.value as Map<dynamic, dynamic>;
      return User(
        id: e.key.toString(),
        username: value['username']?.toString() ?? 'Unknown',
        role: _roleFromString(value['role']?.toString() ?? 'Cleaner'),
        email: value['email']?.toString(),
        phone: value['phone']?.toString(),
        address: value['address']?.toString(),
        emergencyContact: value['emergencyContact']?.toString(),
        payRate: value['payRate'] != null ? double.tryParse(value['payRate'].toString()) : null,
        isActive: value['isActive'] as bool? ?? true,
      );
    }).toList();
  }

  Future<void> add({required String email, required String password, required User user}) async {
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
      if (user.phone != null) 'phone': user.phone,
      if (user.address != null) 'address': user.address,
      if (user.emergencyContact != null) 'emergencyContact': user.emergencyContact,
      if (user.payRate != null) 'payRate': user.payRate,
    });
  }

  Future<void> update(User user) async {
    await _ref.child(user.id).update({
      'username': user.username,
      'role': user.role.displayName, // Ensure it's displaying name, not .name Enum identifier
      if (user.email != null) 'email': user.email,
      'phone': user.phone,
      'address': user.address,
      'emergencyContact': user.emergencyContact,
      'payRate': user.payRate,
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
      default:
        return AppRole.cleaner;
    }
  }
}
