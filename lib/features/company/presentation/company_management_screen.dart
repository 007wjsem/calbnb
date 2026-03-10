import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/company_repository.dart';
import '../domain/company.dart';
import '../domain/subscription.dart';
import '../../admin/data/user_repository.dart';
import '../../auth/domain/user.dart';
import '../../../core/constants/roles.dart';
import '../../../core/theme/app_colors.dart';

class CompanyManagementScreen extends ConsumerStatefulWidget {
  const CompanyManagementScreen({super.key});

  @override
  ConsumerState<CompanyManagementScreen> createState() => _CompanyManagementScreenState();
}

class _CompanyManagementScreenState extends ConsumerState<CompanyManagementScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Only super admins should see this screen, but we ensure the global companies provider is used
    final companiesAsync = ref.watch(globalCompaniesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Companies'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddCompanyDialog(context, ref),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.business_center_outlined),
        label: const Text('Add Company'),
      ),
      body: Column(
        children: [
          Container(
            color: AppColors.surface,
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
            child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Search companies...',
                prefixIcon: const Icon(Icons.search_rounded, color: AppColors.textSecondary),
                suffixIcon: _query.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear_rounded, size: 18),
                        onPressed: () => _searchCtrl.clear(),
                      )
                    : null,
                filled: true,
                fillColor: AppColors.background,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: companiesAsync.when(
              data: (companies) {
                final filtered = companies.where((c) => c.name.toLowerCase().contains(_query)).toList();
                if (filtered.isEmpty) {
                  return const Center(
                    child: Text('No companies found.', style: TextStyle(color: AppColors.textSecondary, fontSize: 16)),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final company = filtered[index];
                    return Card(
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundColor: AppColors.primary.withOpacity(0.1),
                          child: const Icon(Icons.business, color: AppColors.primary),
                        ),
                        title: Text(company.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('Status: ${company.subscription.status.name}'),
                      ),
                    );
                  },
                );
              },
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (err, _) => Center(child: Text('Error: $err')),
            ),
          ),
        ],
      ),
    );
  }

  void _showAddCompanyDialog(BuildContext context, WidgetRef ref) {
    final companyNameCtrl = TextEditingController();
    final adminNameCtrl = TextEditingController();
    final adminEmailCtrl = TextEditingController();
    final adminPasswordCtrl = TextEditingController();
    bool isSaving = false;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 500),
                padding: const EdgeInsets.all(32),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const Text(
                        'Create New Company',
                        style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'This will create a new company and its initial Administrator user.',
                        style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      TextField(
                        controller: companyNameCtrl,
                        decoration: const InputDecoration(labelText: 'Company Name', prefixIcon: Icon(Icons.business_outlined)),
                        enabled: !isSaving,
                      ),
                      const SizedBox(height: 24),
                      const Text('Initial Administrator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const Divider(),
                      const SizedBox(height: 8),
                      TextField(
                        controller: adminNameCtrl,
                        decoration: const InputDecoration(labelText: 'Admin Name', prefixIcon: Icon(Icons.person_outline)),
                        enabled: !isSaving,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: adminEmailCtrl,
                        decoration: const InputDecoration(labelText: 'Admin Email', prefixIcon: Icon(Icons.email_outlined)),
                        keyboardType: TextInputType.emailAddress,
                        enabled: !isSaving,
                      ),
                      const SizedBox(height: 14),
                      TextField(
                        controller: adminPasswordCtrl,
                        decoration: const InputDecoration(labelText: 'Temp Password', prefixIcon: Icon(Icons.lock_outline)),
                        obscureText: true,
                        enabled: !isSaving,
                      ),
                      const SizedBox(height: 28),
                      if (isSaving)
                        const Center(child: CircularProgressIndicator())
                      else
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            TextButton(
                              onPressed: () => Navigator.pop(context),
                              child: const Text('Cancel'),
                            ),
                            const SizedBox(width: 12),
                            FilledButton(
                              onPressed: () async {
                                final compName = companyNameCtrl.text.trim();
                                final adminName = adminNameCtrl.text.trim();
                                final adminEmail = adminEmailCtrl.text.trim();
                                final adminPass = adminPasswordCtrl.text;

                                if (compName.isEmpty || adminName.isEmpty || adminEmail.isEmpty || adminPass.length < 6) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please fill all fields. Password > 6 chars.')),
                                  );
                                  return;
                                }

                                setState(() => isSaving = true);

                                try {
                                  // 1. Generate a new company ID
                                  final newCompanyId = DateTime.now().millisecondsSinceEpoch.toString();

                                  // 2. Create Company object
                                  final newCompany = Company(
                                    id: newCompanyId,
                                    name: compName,
                                    subscription: Subscription(
                                      tier: SubscriptionTier.starter,
                                      status: SubscriptionStatus.active,
                                      startDate: DateTime.now(),
                                    ),
                                    createdAt: DateTime.now(),
                                  );

                                  // 3. Save Company
                                  await ref.read(companyRepositoryProvider).createCompany(newCompany);

                                  // 4. Create Admin User
                                  final newUser = User(
                                    id: '', // Will be set by Firebase Auth
                                    username: adminName,
                                    role: AppRole.administrator,
                                    isActive: true,
                                  );

                                  await UserRepository().add(
                                    email: adminEmail,
                                    password: adminPass,
                                    user: newUser,
                                    companyIds: [newCompanyId],
                                    activeCompanyId: newCompanyId,
                                  );

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Company and Admin created successfully!')),
                                    );
                                  }
                                } catch (e) {
                                  setState(() => isSaving = false);
                                  if (context.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                                    );
                                  }
                                }
                              },
                              child: const Text('Create'),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }
}
