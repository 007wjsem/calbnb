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

/// Supported currencies the admin can choose from.
const List<Map<String, String>> kSupportedCurrencies = [
  {'code': 'USD', 'symbol': '\$',  'name': 'US Dollar'},
  {'code': 'PEN', 'symbol': 'S/', 'name': 'Peruvian Sol'},
];
