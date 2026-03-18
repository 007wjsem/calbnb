import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/settings_repository.dart';
import '../../auth/data/auth_repository.dart';
import '../../company/data/company_repository.dart';
import '../../company/presentation/currency_provider.dart';
import '../../company/domain/subscription.dart';
import '../../../core/theme/app_colors.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:calbnb/l10n/app_localizations.dart';

final settingsRepositoryProvider = Provider((ref) => SettingsRepository());

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = true;

  // Currency picker state
  String _selectedCurrency = 'USD';
  // White-label logo state
  Uint8List? _logoBytes;
  String? _existingLogoBase64;
  bool _logoUploading = false;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      if (mounted) {
        setState(() {
          _isLoading = false;
          // Init currency from the active company
          final currentUser = ref.read(authControllerProvider);
          final companyId = currentUser?.activeCompanyId;
          if (companyId != null && companyId.isNotEmpty) {
            final companyAsync = ref.read(companyProvider(companyId));
            _selectedCurrency = companyAsync.valueOrNull?.baseCurrency ?? 'USD';
            _existingLogoBase64 = companyAsync.valueOrNull?.companyLogoBase64;
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${AppLocalizations.of(context)!.errorLoadingData} $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.systemSettingsTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ─── Currency Section (Platinum+) ─────────────────────────────
            Builder(builder: (context) {
              final currentUser = ref.watch(authControllerProvider);
              final companyId = currentUser?.activeCompanyId;
              final companyAsync = companyId != null ? ref.watch(companyProvider(companyId)) : null;
              final isSuperAdmin = currentUser?.role.displayName == 'Super Admin';
              // If not Super Admin, ensure they have an active company
              if (!isSuperAdmin && companyId == null) return const SizedBox.shrink();

              return Card(
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: AppColors.teal.withOpacity(0.4))),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.currency_exchange, color: AppColors.teal, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.currencySettings, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(l10n.currencySettingsDesc, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: _selectedCurrency,
                        decoration: InputDecoration(
                          labelText: l10n.activeCurrency,
                          prefixIcon: const Icon(Icons.paid_outlined),
                        ),
                        items: kSupportedCurrencies.map((c) => DropdownMenuItem(
                          value: c['code'],
                          child: Text('${c['symbol']}  ${c['code']} – ${c['name']}'),
                        )).toList(),
                        onChanged: (val) => setState(() => _selectedCurrency = val ?? 'USD'),
                      ),
                      const SizedBox(height: 12),
                      Align(
                        alignment: Alignment.centerRight,
                        child: FilledButton.icon(
                          icon: const Icon(Icons.check),
                          label: Text(l10n.applyCurrency),
                          onPressed: () async {
                            if (companyId == null) return;
                            final selected = kSupportedCurrencies.firstWhere((c) => c['code'] == _selectedCurrency);
                            await ref.read(companyRepositoryProvider).updateCurrency(
                              companyId: companyId,
                              baseCurrency: _selectedCurrency,
                              currencySymbol: selected['symbol']!,
                            );
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('${AppLocalizations.of(context)!.currencyUpdatedTo} $_selectedCurrency')),
                              );
                            }
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }),
            // ─── White-Label Section (Diamond) ─────────────────────────
            Builder(builder: (context) {
              final currentUser = ref.watch(authControllerProvider);
              final companyId = currentUser?.activeCompanyId;
              final companyAsync = companyId != null ? ref.watch(companyProvider(companyId)) : null;
              final company = companyAsync?.valueOrNull;
              final isDiamond = company != null && (company.tier == SubscriptionTier.diamond);

              if (!isDiamond) return const SizedBox.shrink();

              final existingLogo = _existingLogoBase64 ?? company.companyLogoBase64;
              final previewBytes = _logoBytes ?? (existingLogo != null ? base64Decode(existingLogo) : null);

              return Card(
                margin: const EdgeInsets.only(bottom: 24),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16), side: BorderSide(color: Colors.amber.shade700.withOpacity(0.4))),
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.auto_awesome, color: Colors.amber.shade700, size: 20),
                          const SizedBox(width: 8),
                          Text(l10n.whiteLabelBranding, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(color: Colors.amber.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                            child: Text(l10n.diamondTier, style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.amber.shade700)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(l10n.whiteLabelDesc, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                      const SizedBox(height: 16),
                      if (previewBytes != null)
                        Center(
                          child: Stack(
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.memory(previewBytes, height: 80, fit: BoxFit.contain),
                              ),
                              Positioned(
                                top: -4, right: -4,
                                child: GestureDetector(
                                  onTap: () => setState(() { _logoBytes = null; _existingLogoBase64 = null; }),
                                  child: Container(
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(shape: BoxShape.circle, color: AppColors.error),
                                    child: const Icon(Icons.close, color: Colors.white, size: 14),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      if (previewBytes != null) const SizedBox(height: 12),
                      Row(
                        children: [
                          OutlinedButton.icon(
                            icon: const Icon(Icons.image_outlined),
                            label: Text(l10n.chooseLogo),
                            onPressed: () async {
                              final picker = ImagePicker();
                              final file = await picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 85);
                              if (file != null) {
                                final bytes = await file.readAsBytes();
                                setState(() => _logoBytes = bytes);
                              }
                            },
                          ),
                          const SizedBox(width: 12),
                          FilledButton.icon(
                            icon: _logoUploading ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Icon(Icons.upload),
                            label: Text(l10n.upload),
                            onPressed: _logoUploading ? null : () async {
                              if (companyId == null) return;
                              setState(() => _logoUploading = true);
                              final base64Str = _logoBytes != null ? base64Encode(_logoBytes!) : null;
                              await ref.read(companyRepositoryProvider).updateCompanyLogo(
                                companyId: companyId,
                                logoBase64: base64Str,
                              );
                              setState(() {
                                _existingLogoBase64 = base64Str;
                                _logoBytes = null;
                                _logoUploading = false;
                              });
                              if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(content: Text(base64Str != null ? AppLocalizations.of(context)!.logoUpdated : AppLocalizations.of(context)!.logoRemoved)),
                                );
                              }
                            },
                          ),
                          if ((existingLogo != null || _logoBytes != null)) ...[
                            const SizedBox(width: 8),
                            TextButton(
                              style: TextButton.styleFrom(foregroundColor: AppColors.error),
                              child: Text(l10n.remove),
                              onPressed: _logoUploading ? null : () async {
                                if (companyId == null) return;
                                setState(() => _logoUploading = true);
                                await ref.read(companyRepositoryProvider).updateCompanyLogo(
                                  companyId: companyId,
                                  logoBase64: null,
                                );
                                setState(() { _logoBytes = null; _existingLogoBase64 = null; _logoUploading = false; });
                              },
                            ),
                          ],
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
