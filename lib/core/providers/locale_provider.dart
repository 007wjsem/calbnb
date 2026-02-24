import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provides the user's selected Locale (English or Spanish).
/// Persists the choice using SharedPreferences.
class LocaleNotifier extends StateNotifier<Locale> {
  final SharedPreferences _prefs;
  static const _langKey = 'selected_language';

  LocaleNotifier(this._prefs) : super(const Locale('en')) {
    _loadSavedLocale();
  }

  void _loadSavedLocale() {
    final savedLang = _prefs.getString(_langKey);
    if (savedLang != null) {
      state = Locale(savedLang);
    }
  }

  Future<void> setLocale(Locale locale) async {
    state = locale;
    await _prefs.setString(_langKey, locale.languageCode);
  }
}

final sharedPreferencesProvider = Provider<SharedPreferences>((ref) {
  throw UnimplementedError('sharedPreferencesProvider must be overridden in main() prior to use');
});

final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  final prefs = ref.watch(sharedPreferencesProvider);
  return LocaleNotifier(prefs);
});
