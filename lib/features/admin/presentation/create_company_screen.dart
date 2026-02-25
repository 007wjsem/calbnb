import 'package:cloud_functions/cloud_functions.dart';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../company/domain/subscription.dart';
import '../../company/data/company_repository.dart';

class CreateCompanyScreen extends ConsumerStatefulWidget {
  const CreateCompanyScreen({super.key});

  @override
  ConsumerState<CreateCompanyScreen> createState() => _CreateCompanyScreenState();
}


class _CreateCompanyScreenState extends ConsumerState<CreateCompanyScreen> {
  final _formKey = GlobalKey<FormState>();
  String _name = '';
  String _ownerEmail = '';
  SubscriptionTier _selectedTier = SubscriptionTier.growth;
  bool _isLoading = false;

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();

    setState(() => _isLoading = true);

    try {
      final callable = FirebaseFunctions.instance.httpsCallable('provisionCompany');
      final result = await callable.call(<String, dynamic>{
        'companyName': _name,
        'ownerEmail': _ownerEmail,
        'tier': _selectedTier.value,
      });

      if (mounted) {
        final resetLink = result.data['resetLink'] as String?;
        // In a real app the cloud function sends the email. Since we don't have an SMTP relay setup
        // we log it for the admin to copy if needed during dev/testing.
        print('SUCCESS! Reset link for $_ownerEmail: $resetLink');

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Company provisioned successfully!')),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Create New Company')),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator())
        : Padding(
            padding: const EdgeInsets.all(24.0),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    decoration: const InputDecoration(labelText: 'Company Name'),
                    validator: (v) => v == null || v.isEmpty ? 'Required' : null,
                    onSaved: (v) => _name = v ?? '',
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Owner Email',
                      helperText: 'An invitation will be sent to this address to set their password.',
                    ),
                    keyboardType: TextInputType.emailAddress,
                    validator: (v) => v == null || !v.contains('@') ? 'Valid email required' : null,
                    onSaved: (v) => _ownerEmail = v ?? '',
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<SubscriptionTier>(
                    value: _selectedTier,
                    decoration: const InputDecoration(labelText: 'Subscription Tier'),
                    items: SubscriptionTier.values.map((tier) {
                      return DropdownMenuItem(
                        value: tier,
                        child: Text('${tier.displayName} (${tier.basePrice == 0 ? "Custom" : "\$${tier.basePrice}/mo"})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => _selectedTier = val);
                    },
                  ),
                  const Spacer(),
                  FilledButton(
                    onPressed: _submit,
                    child: const Text('Create Company & Send Invite'),
                  ),
                ],
              ),
            ),
          ),
    );
  }
}
