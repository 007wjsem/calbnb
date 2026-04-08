import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../domain/lead.dart';
import '../data/lead_repository.dart';
import '../../../core/constants/countries.dart';
import '../../company/presentation/currency_provider.dart';
import '../../../core/theme/app_colors.dart';
import 'package:calbnb/l10n/app_localizations.dart';
import 'package:uuid/uuid.dart';

class LeadRegistrationScreen extends ConsumerStatefulWidget {
  const LeadRegistrationScreen({super.key});

  @override
  ConsumerState<LeadRegistrationScreen> createState() => _LeadRegistrationScreenState();
}

class _LeadRegistrationScreenState extends ConsumerState<LeadRegistrationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _contactInfoController = TextEditingController();
  
  String _contactPreference = 'email';
  String _selectedCountryName = 'United States';
  String _selectedPhoneCode = '+1';
  bool _isSubmitting = false;

  @override
  void dispose() {
    _nameController.dispose();
    _contactInfoController.dispose();
    super.dispose();
  }

  Future<void> _submitLead() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    
    try {
      final info = _contactInfoController.text.trim();
      final lead = Lead(
        id: const Uuid().v4(),
        name: _nameController.text.trim(),
        contactPreference: _contactPreference,
        contactInfo: info,
        countryCode: _contactPreference == 'whatsapp' ? _selectedPhoneCode : null,
        status: 'new',
        timestamp: DateTime.now(),
      );

      await ref.read(leadRepositoryProvider).createLead(lead);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppLocalizations.of(context)!.leadSubmittedSuccess)),
        );
        context.go('/login');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [AppColors.sidebarBg, AppColors.primary, AppColors.teal],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            stops: [0.0, 0.55, 1.0],
          ),
        ),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
              child: Card(
                elevation: 20,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                child: Padding(
                  padding: const EdgeInsets.all(32.0),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          l10n.leadRegistrationTitle,
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold, color: AppColors.primary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          l10n.leadRegistrationSubtitle,
                          style: const TextStyle(fontSize: 14, color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        
                        TextFormField(
                          controller: _nameController,
                          decoration: InputDecoration(
                            labelText: l10n.leadNameLabel,
                            prefixIcon: const Icon(Icons.business_outlined),
                          ),
                          validator: (v) => (v == null || v.isEmpty) ? l10n.fieldRequired : null,
                        ),
                        const SizedBox(height: 20),
                        
                        Text(l10n.contactPreferenceLabel, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                        const SizedBox(height: 8),
                        SegmentedButton<String>(
                          segments: [
                            ButtonSegment(value: 'email', label: Text(l10n.emailOption), icon: const Icon(Icons.email_outlined)),
                            ButtonSegment(value: 'whatsapp', label: Text(l10n.whatsappOption), icon: const Icon(Icons.chat_outlined)),
                          ],
                          selected: {_contactPreference},
                          onSelectionChanged: (set) => setState(() => _contactPreference = set.first),
                        ),
                        const SizedBox(height: 20),
                        
                        if (_contactPreference == 'whatsapp') ...[
                           DropdownButtonFormField<String>(
                            value: _selectedCountryName,
                            isExpanded: true,
                            decoration: InputDecoration(
                              labelText: l10n.countryPickerLabel,
                              prefixIcon: const Icon(Icons.public_outlined),
                            ),
                            items: kAllCountries.map((c) => DropdownMenuItem(
                              value: c['name'],
                              child: Text(
                                '${c["flag"]} ${c["phoneCode"]}  –  ${c["name"]}',
                                overflow: TextOverflow.ellipsis,
                              ),
                            )).toList(),
                            onChanged: (v) {
                              if (v == null) return;
                              final country = kAllCountries.firstWhere((c) => c['name'] == v);
                              setState(() {
                                _selectedCountryName = v;
                                _selectedPhoneCode = country['phoneCode']!;
                              });
                            },
                          ),
                          const SizedBox(height: 16),
                        ],

                        TextFormField(
                          controller: _contactInfoController,
                          keyboardType: _contactPreference == 'email' ? TextInputType.emailAddress : TextInputType.phone,
                          decoration: InputDecoration(
                            labelText: _contactPreference == 'email' ? l10n.emailPlaceholder : l10n.phoneNumberPlaceholder,
                            prefixIcon: Icon(_contactPreference == 'email' ? Icons.alternate_email : Icons.phone_android),
                          ),
                          validator: (v) {
                             if (v == null || v.isEmpty) return l10n.fieldRequired;
                             if (_contactPreference == 'email' && !v.contains('@')) return 'Invalid email';
                             return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        
                        SizedBox(
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSubmitting ? null : _submitLead,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                            ),
                            child: _isSubmitting 
                                ? const CircularProgressIndicator(color: Colors.white)
                                : Text(l10n.submitLeadButton, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () => context.go('/login'),
                          child: Text(l10n.loginButton),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
