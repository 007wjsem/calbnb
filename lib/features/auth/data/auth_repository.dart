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
      await _loadUserFromDatabase(credential.user!.uid, email);
    } on auth.FirebaseAuthException catch (e) {
      // On unsigned macOS/Windows apps, Firebase Auth throws 'keychain-error'
      // AFTER a successful sign-in, when it tries to persist the token to the
      // native Keychain (which requires a paid Developer certificate).
      // The user IS authenticated in memory at this point — we recover by
      // reading FirebaseAuth.instance.currentUser directly.
      if (e.code == 'keychain-error') {
        final currentUser = auth.FirebaseAuth.instance.currentUser;
        if (currentUser != null) {
          await _loadUserFromDatabase(currentUser.uid, email);
          return;
        }
      }
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Invalid email or password.');
      }
      throw Exception(e.message ?? 'Authentication failed.');
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  /// Fetches user record from Realtime Database and sets the app state.
  Future<void> _loadUserFromDatabase(String uid, String fallbackEmail) async {
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
        username: data['username']?.toString() ?? fallbackEmail,
        role: _roleFromString(data['role']?.toString() ?? 'Cleaner'),
        isActive: data['isActive'] as bool? ?? true,
        email: data['email']?.toString(),
        phone: data['phone']?.toString(),
        address: data['address']?.toString(),
        emergencyContact: data['emergencyContact']?.toString(),
        payRate: data['payRate'] != null ? double.tryParse(data['payRate'].toString()) : null,
        companyId: data['companyId']?.toString(),
      );
    } else {
      await auth.FirebaseAuth.instance.signOut();
      throw Exception('User data not found in database.');
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
