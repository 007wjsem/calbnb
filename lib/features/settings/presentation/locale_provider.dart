import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../auth/domain/user.dart';
import '../../auth/data/auth_repository.dart';

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier(ref);
});

class LocaleNotifier extends StateNotifier<Locale> {
  static const _localeKey = 'app_locale';
  final Ref _ref;

  LocaleNotifier(this._ref) : super(const Locale('en')) {
    _loadLocale();
    _listenToUser();
  }

  void _listenToUser() {
    _ref.listen<User?>(authControllerProvider, (previous, next) {
      if (next != null && next.language != null) {
        final newLocale = Locale(next.language!);
        if (newLocale.languageCode != state.languageCode) {
          state = newLocale;
        }
      }
    });
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final String? languageCode = prefs.getString(_localeKey);
    if (languageCode != null) {
      state = Locale(languageCode);
    }
  }

  Future<void> setLocale(Locale locale) async {
    if (!['en', 'es'].contains(locale.languageCode)) return;
    
    state = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale.languageCode);

    // Sync to user profile if logged in
    final authController = _ref.read(authControllerProvider.notifier);
    final user = _ref.read(authControllerProvider);
    if (user != null && user.language != locale.languageCode) {
      await authController.updateProfile(
        phone: user.phone,
        address: user.address,
        emergencyContact: user.emergencyContact,
        language: locale.languageCode,
      );
    }
  }
}
