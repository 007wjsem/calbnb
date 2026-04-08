import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../company/data/company_repository.dart';
import '../../auth/data/auth_repository.dart';

/// Returns the currency symbol for the currently active company (e.g. "$", "€").
/// Falls back to "$" if not loaded yet.
final currencySymbolProvider = Provider<String>((ref) {
  final user = ref.watch(authControllerProvider);
  final companyId = user?.activeCompanyId;
  if (companyId == null || companyId.isEmpty) return '\$';
  final companyAsync = ref.watch(companyProvider(companyId));
  return companyAsync.valueOrNull?.currencySymbol ?? '\$';
});

/// Returns the ISO currency code for the active company (e.g. "USD").
final currencyCodeProvider = Provider<String>((ref) {
  final user = ref.watch(authControllerProvider);
  final companyId = user?.activeCompanyId;
  if (companyId == null || companyId.isEmpty) return 'USD';
  final companyAsync = ref.watch(companyProvider(companyId));
  return companyAsync.valueOrNull?.baseCurrency ?? 'USD';
});

/// Formats a double as a money string using the active company currency symbol.
/// Example: formatMoney(ref, 49.5) → "$49.50"
String formatMoney(WidgetRef ref, double amount) {
  final symbol = ref.watch(currencySymbolProvider);
  return '$symbol${amount.toStringAsFixed(2)}';
}

/// Returns the phone country dialing code for the active company (e.g. "+51").
final phoneCountryCodeProvider = Provider<String>((ref) {
  final user = ref.watch(authControllerProvider);
  final companyId = user?.activeCompanyId;
  if (companyId == null || companyId.isEmpty) return '+1';
  final companyAsync = ref.watch(companyProvider(companyId));
  return companyAsync.valueOrNull?.phoneCountryCode ?? '+1';
});

/// Supported currencies the admin can choose from.
/// phoneCode = international dialing prefix for that country.
const List<Map<String, String>> kSupportedCurrencies = [
  {'code': 'USD', 'symbol': '\$',  'name': 'US Dollar',     'phoneCode': '+1',  'flag': '🇺🇸'},
  {'code': 'PEN', 'symbol': 'S/',  'name': 'Peruvian Sol',  'phoneCode': '+51', 'flag': '🇵🇪'},
  {'code': 'EUR', 'symbol': '€',   'name': 'Euro',          'phoneCode': '+34', 'flag': '🇪🇸'},
  {'code': 'MXN', 'symbol': 'MX\$', 'name': 'Mexican Peso',  'phoneCode': '+52', 'flag': '🇲🇽'},
  {'code': 'COP', 'symbol': 'COP', 'name': 'Colombian Peso', 'phoneCode': '+57', 'flag': '🇨🇴'},
  {'code': 'ARS', 'symbol': 'ARS', 'name': 'Argentine Peso', 'phoneCode': '+54', 'flag': '🇦🇷'},
  {'code': 'CLP', 'symbol': 'CLP', 'name': 'Chilean Peso',   'phoneCode': '+56', 'flag': '🇨🇱'},
  {'code': 'GBP', 'symbol': '£',   'name': 'British Pound', 'phoneCode': '+44', 'flag': '🇬🇧'},
  {'code': 'BRL', 'symbol': 'R\$', 'name': 'Brazilian Real','phoneCode': '+55', 'flag': '🇧🇷'},
];
