import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
  bool _showInactive = false;

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
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
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
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    const Text('Show Inactive', style: TextStyle(color: AppColors.textSecondary, fontSize: 13, fontWeight: FontWeight.w600)),
                    Switch(
                      value: _showInactive,
                      onChanged: (val) => setState(() => _showInactive = val),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: companiesAsync.when(
              data: (companies) {
                final filtered = companies.where((c) {
                  final matchesSearch = c.name.toLowerCase().contains(_query);
                  final matchesStatus = _showInactive || c.status == SubscriptionStatus.active;
                  return matchesSearch && matchesStatus;
                }).toList();

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
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: AppColors.primary.withOpacity(0.1),
                                  child: const Icon(Icons.business, color: AppColors.primary),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(company.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 8,
                                        runSpacing: 4,
                                        children: [
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: company.status == SubscriptionStatus.active ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              company.status.displayName,
                                              style: TextStyle(fontSize: 11, color: company.status == SubscriptionStatus.active ? Colors.green : Colors.red, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                            decoration: BoxDecoration(
                                              color: AppColors.teal.withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              company.tier.displayName,
                                              style: const TextStyle(fontSize: 11, color: AppColors.teal, fontWeight: FontWeight.bold),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.edit_outlined, color: AppColors.textSecondary),
                                  onPressed: () => _showEditCompanyDialog(context, ref, company),
                                  tooltip: 'Edit Company',
                                ),
                              ],
                            ),
                            const Divider(height: 24),
                            Row(
                              children: [
                                Expanded(
                                  child: Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          'ID: ${company.id}',
                                          style: const TextStyle(fontSize: 11, color: Colors.grey),
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      const SizedBox(width: 4),
                                      InkWell(
                                        borderRadius: BorderRadius.circular(4),
                                        onTap: () {
                                          Clipboard.setData(ClipboardData(text: company.id));
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            const SnackBar(content: Text('Copied ID to clipboard'), duration: Duration(seconds: 2)),
                                          );
                                        },
                                        child: const Padding(
                                          padding: EdgeInsets.all(4.0),
                                          child: Icon(Icons.copy, size: 14, color: Colors.grey),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Tooltip(
                                  message: 'View Properties',
                                  child: IconButton(
                                    icon: const Icon(Icons.home_work_outlined),
                                    color: AppColors.primary,
                                    onPressed: () {
                                      context.push('/admin/properties?companyId=${company.id}');
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
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
    bool createAdmin = true;

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
                      const SizedBox(height: 20),
                      SwitchListTile(
                        title: const Text('Create with Administrator', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        subtitle: const Text('If disabled, you will need to add an admin later.', style: TextStyle(fontSize: 12)),
                        value: createAdmin,
                        onChanged: isSaving ? null : (val) => setState(() => createAdmin = val),
                        activeColor: AppColors.primary,
                        contentPadding: EdgeInsets.zero,
                      ),
                      if (createAdmin) ...[
                        const SizedBox(height: 16),
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
                      ],
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

                                if (compName.isEmpty) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please enter a company name.')),
                                  );
                                  return;
                                }

                                if (createAdmin && (adminName.isEmpty || adminEmail.isEmpty || adminPass.length < 6)) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Please fill all admin fields. Password > 6 chars.')),
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
                                    ownerUid: '', // Will be replaced/set properly later or via super admin logic
                                    tier: SubscriptionTier.free,
                                    status: SubscriptionStatus.active,
                                    propertyCount: 0,
                                    createdAt: DateTime.now(),
                                  );

                                  // 3. Save Company
                                  await ref.read(companyRepositoryProvider).createCompany(newCompany);

                                  // 4. Create Admin User (Optional)
                                  if (createAdmin) {
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
                                  }

                                  if (context.mounted) {
                                    Navigator.pop(context);
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(content: Text(createAdmin ? 'Company and Admin created successfully!' : 'Company created successfully!')),
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

    void _showEditCompanyDialog(BuildContext context, WidgetRef ref, Company company) {
      SubscriptionTier selectedTier = company.tier;
      SubscriptionStatus selectedStatus = company.status;
      bool isSaving = false;

      showDialog(
        context: context,
        builder: (context) {
          return StatefulBuilder(
            builder: (context, setState) {
              return Dialog(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                child: Container(
                  width: 400,
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        'Edit ${company.name}',
                        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 24),
                      DropdownButtonFormField<SubscriptionTier>(
                        value: selectedTier,
                        decoration: const InputDecoration(labelText: 'Subscription Tier', prefixIcon: Icon(Icons.star_border)),
                        items: SubscriptionTier.values.map((tier) {
                          return DropdownMenuItem(
                            value: tier,
                            child: Text(tier.displayName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedTier = val);
                        },
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<SubscriptionStatus>(
                        value: selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.info_outline)),
                        items: SubscriptionStatus.values.map((status) {
                          return DropdownMenuItem(
                            value: status,
                            child: Text(status.displayName),
                          );
                        }).toList(),
                        onChanged: (val) {
                          if (val != null) setState(() => selectedStatus = val);
                        },
                      ),
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: isSaving ? null : () async {
                              setState(() => isSaving = true);
                              try {
                                final updatedCompany = company.copyWith(
                                  tier: selectedTier,
                                  status: selectedStatus,
                                );
                                await ref.read(companyRepositoryProvider).updateCompany(updatedCompany);
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Company updated successfully')),
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
                            child: isSaving ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : const Text('Save Changes'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      );
    }
}
