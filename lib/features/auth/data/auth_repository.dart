import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
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

  /// macOS REST API key (bypasses Keychain on unsigned builds).
  static const _macosApiKey = 'AIzaSyB4UNHKffFOTtxZviWzaO9rO8QKP1lFDSs';

  Future<void> login(String email, String password) async {
    // On macOS the native Firebase Auth SDK always throws keychain-error because
    // the app requires a paid Apple Distribution certificate to access the Keychain.
    // Fix: use the Firebase Auth REST API directly — it's just HTTPS, no Keychain needed.
    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.macOS) {
      await _loginViaMacOSRestApi(email.trim(), password);
      return;
    }

    // All other platforms (Android, iOS, Windows) use the normal SDK path.
    try {
      final credential = await auth.FirebaseAuth.instance.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      await _loadUserFromDatabase(credential.user!.uid, email);
    } on auth.FirebaseAuthException catch (e) {
      if (e.code == 'user-not-found' || e.code == 'wrong-password' || e.code == 'invalid-credential') {
        throw Exception('Invalid email or password.');
      }
      throw Exception(e.message ?? 'Authentication failed.');
    } catch (e) {
      throw Exception('Login failed: ${e.toString()}');
    }
  }

  /// Authenticates using the Firebase Auth REST API, bypassing the macOS Keychain entirely.
  Future<void> _loginViaMacOSRestApi(String email, String password) async {
    const url =
        'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$_macosApiKey';
    
    try {
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email,
          'password': password,
          'returnSecureToken': true,
        }),
      );

      final body = jsonDecode(response.body) as Map<String, dynamic>;

      if (response.statusCode != 200) {
        final errCode = (body['error']?['message'] as String? ?? '').toLowerCase();
        if (errCode.contains('invalid') || errCode.contains('password') || errCode.contains('email')) {
          throw Exception('Invalid email or password.');
        }
        throw Exception('Authentication failed: ${body['error']?['message']}');
      }

      final uid = body['localId'] as String;
      await _loadUserFromDatabase(uid, email);
    } catch (e) {
      rethrow;
    }
  }


  /// Fetches user record from Realtime Database and sets the app state.
  Future<void> _loadUserFromDatabase(String uid, String fallbackEmail) async {
    final snapshot = await FirebaseDatabase.instance.ref('users/$uid').get();
    
    if (snapshot.exists) {
      final data = snapshot.value as Map<dynamic, dynamic>;
      
      // Prevent login if user is soft-deleted
      if (data['isActive'] == false) {
        try {
          await auth.FirebaseAuth.instance.signOut();
        } catch (_) {}
        throw Exception('This account has been deactivated.');
      }

      final companyIdsRaw = data['companyIds'];
      List<String> companyIds = [];
      if (companyIdsRaw is List) {
        companyIds = companyIdsRaw.map((e) => e.toString()).toList();
      } else if (companyIdsRaw is Map) {
        // Handle Map if stored as keys
        companyIds = companyIdsRaw.keys.map((e) => e.toString()).toList();
      } else if (data['companyId'] != null) {
        // Fallback for legacy single companyId field
        companyIds = [data['companyId'].toString()];
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
        companyIds: companyIds,
        activeCompanyId: data['activeCompanyId']?.toString() ?? (companyIds.isNotEmpty ? companyIds.first : null),
        language: data['language']?.toString(),
      );
    } else {
      try {
        await auth.FirebaseAuth.instance.signOut();
      } catch (_) {}
      throw Exception('User data not found in database.');
    }
  }

  Future<void> logout() async {
    try {
      await auth.FirebaseAuth.instance.signOut();
    } catch (_) {
      // Ignore keychain failures on logout
    }
    state = null;
  }



  /// Update editable profile fields in the Realtime Database and refresh local state.
  Future<void> updateProfile({
    String? phone,
    String? address,
    String? emergencyContact,
    String? language,
  }) async {
    final user = state;
    if (user == null) return;

    await FirebaseDatabase.instance.ref('users/${user.id}').update({
      'phone': phone,
      'address': address,
      'emergencyContact': emergencyContact,
      if (language != null) 'language': language,
    });

    state = User(
      id: user.id,
      username: user.username,
      role: user.role,
      isActive: user.isActive,
      email: user.email,
      phone: phone,
      address: address,
      emergencyContact: emergencyContact,
      language: language ?? user.language,
    );
  }

  /// Update the Firebase Auth password.
  Future<void> updatePassword(String newPassword) async {
    final currentUser = auth.FirebaseAuth.instance.currentUser;
    if (currentUser == null) throw Exception('Not authenticated.');
    await currentUser.updatePassword(newPassword);
  }

  /// Switch the active company for the user.
  Future<void> switchCompany(String companyId) async {
    final user = state;
    if (user == null) return;
    if (!user.companyIds.contains(companyId)) {
      throw Exception('You do not have access to this company.');
    }

    await FirebaseDatabase.instance.ref('users/${user.id}').update({
      'activeCompanyId': companyId,
    });

    state = user.copyWith(activeCompanyId: companyId);
  }

  AppRole _roleFromString(String? roleStr) {
    if (roleStr == null) return AppRole.cleaner;
    final normalized = roleStr.toLowerCase().trim();
    
    switch (normalized) {
      case 'super admin':
      case 'superadmin':
      case 'superadministrator':
        return AppRole.superAdmin;
      case 'administrator':
      case 'admin':
        return AppRole.administrator;
      case 'manager':
        return AppRole.manager;
      case 'cleaner':
        return AppRole.cleaner;
      case 'inspector':
        return AppRole.inspector;
      case 'property owner':
      case 'owner':
        return AppRole.owner;
      default:
        return AppRole.cleaner;
    }
  }

}
