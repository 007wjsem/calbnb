import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:firebase_database/firebase_database.dart';
import '../../auth/domain/user.dart';
import '../../../core/constants/roles.dart';

part 'auth_repository.g.dart';

@riverpod
class AuthController extends _$AuthController {
  @override
  User? build() {
    return null; // Not logged in initially
  }

  Future<void> login(String email, String password) async {
    try {
      final credential = await auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      
      final uid = credential.user!.uid;
      
      // Fetch user role from Realtime Database
      final snapshot = await FirebaseDatabase.instance.ref('users/$uid').get();
      if (snapshot.exists) {
        final data = snapshot.value as Map<dynamic, dynamic>;
        
        // Prevent login if user is soft-deleted
        if (data['isActive'] == false) {
          await auth.FirebaseAuth.instance.signOut();
          throw Exception('This account has been deactivated.');
        }
        
        state = User(
          id: uid,
          username: data['username']?.toString() ?? email,
          role: _roleFromString(data['role']?.toString() ?? 'Cleaner'),
          isActive: data['isActive'] as bool? ?? true,
          email: data['email']?.toString(),
          phone: data['phone']?.toString(),
          address: data['address']?.toString(),
          emergencyContact: data['emergencyContact']?.toString(),
          payRate: data['payRate'] != null ? double.tryParse(data['payRate'].toString()) : null,
        );
      } else {
        // Automatically sign out if database record is missing to prevent orphan sessions
        await auth.FirebaseAuth.instance.signOut();
        throw Exception('User data not found in database.');
      }
    } on auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Invalid email or password.');
      }
      throw Exception(e.message ?? 'Authentication failed.');
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  Future<void> logout() async {
    await auth.FirebaseAuth.instance.signOut();
    state = null;
  }

  /// Update editable profile fields in the Realtime Database and refresh local state.
  Future<void> updateProfile({
    String? phone,
    String? address,
    String? emergencyContact,
  }) async {
    final user = state;
    if (user == null) return;

    await FirebaseDatabase.instance.ref('users/${user.id}').update({
      'phone': phone,
      'address': address,
      'emergencyContact': emergencyContact,
    });

    state = User(
      id: user.id,
      username: user.username,
      role: user.role,
      isActive: user.isActive,
      email: user.email,
      payRate: user.payRate,
      phone: phone,
      address: address,
      emergencyContact: emergencyContact,
    );
  }

  /// Update the Firebase Auth password.
  Future<void> updatePassword(String newPassword) async {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('Not authenticated.');
    await currentUser.updatePassword(newPassword);
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
