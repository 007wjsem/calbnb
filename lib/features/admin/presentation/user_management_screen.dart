import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../admin/data/user_repository.dart';
import '../../auth/domain/user.dart';
import '../../../core/constants/roles.dart';
import '../../../core/theme/app_colors.dart';
import '../../auth/data/auth_repository.dart';
import '../../company/data/company_repository.dart';
import '../../company/domain/company.dart';
import '../../company/domain/subscription.dart';
import '../../company/presentation/currency_provider.dart';
import '../../../core/constants/countries.dart';
import 'package:calbnb/l10n/app_localizations.dart';

final userRepositoryProvider = Provider((ref) => UserRepository());

class UserManagementScreen extends ConsumerStatefulWidget {
  const UserManagementScreen({super.key});

  @override
  ConsumerState<UserManagementScreen> createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends ConsumerState<UserManagementScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  AppRole? _roleFilter; // null = All
  List<User> _allUsers = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadUsers();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadUsers() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(userRepositoryProvider);
      final users = await repo.fetchAll();
      users.sort((a, b) => a.username.toLowerCase().compareTo(b.username.toLowerCase()));
      setState(() { _allUsers = users; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<User> get _filtered {
    return _allUsers.where((u) {
      final matchesQuery = _query.isEmpty ||
          u.username.toLowerCase().contains(_query) ||
          (u.email?.toLowerCase().contains(_query) ?? false) ||
          (u.phone?.toLowerCase().contains(_query) ?? false);
      final matchesRole = _roleFilter == null || u.role == _roleFilter;
      return matchesQuery && matchesRole;
    }).toList();
  }

  void _showUserDialog(BuildContext context, WidgetRef ref, UserRepository repo, {User? existingUser}) {
    final isEditing = existingUser != null;
    final emailCtrl = TextEditingController(text: existingUser?.email ?? '');
    final passwordCtrl = TextEditingController();
    final usernameCtrl = TextEditingController(text: existingUser?.username ?? '');
    final addressCtrl = TextEditingController(text: existingUser?.address ?? '');
    final emergencyCtrl = TextEditingController(text: existingUser?.emergencyContact ?? '');
    AppRole selectedRole = existingUser?.role ?? AppRole.cleaner;

    // Parse existing phone: split off country code if stored with + or use separate node
    // Parse existing phone: split off country code if stored with + or use separate node
    String initialCountryCode = (existingUser?.phoneCountryCode != null && existingUser!.phoneCountryCode!.isNotEmpty)
        ? (existingUser.phoneCountryCode!.startsWith('+') ? existingUser.phoneCountryCode! : '+${existingUser.phoneCountryCode}')
        : '+1';
    String initialPhoneDigits = existingUser?.phone ?? '';

    // Legacy fallback: split if phoneCountryCode node is missing but phone starts with +
    if ((existingUser?.phoneCountryCode == null || existingUser!.phoneCountryCode!.isEmpty) &&
        initialPhoneDigits.startsWith('+')) {
      // Try to match one of the known country codes
      final matched = kAllCountries
          .map((c) => c['phoneCode']!)
          .where((code) => initialPhoneDigits.startsWith(code))
          .fold<String>('', (longest, code) => code.length > longest.length ? code : longest);
      if (matched.isNotEmpty) {
        initialCountryCode = matched;
        initialPhoneDigits = initialPhoneDigits.substring(matched.length);
      }
    }
    final phoneCtrl = TextEditingController(text: initialPhoneDigits);

    final currentUser = ref.read(authControllerProvider);
    final isSuperAdmin = currentUser?.role == AppRole.superAdmin;
    final allCompanies = ref.read(globalCompaniesProvider).valueOrNull ?? [];
    
    final currentCompanyId = currentUser?.activeCompanyId;

    List<String> selectedCompanyIds = List.from(existingUser?.companyIds ?? []);
    if (!isEditing && currentCompanyId != null && !selectedCompanyIds.contains(currentCompanyId)) {
      selectedCompanyIds.add(currentCompanyId);
    }
    
    String? selectedActiveCompanyId = existingUser?.activeCompanyId ?? (!isEditing ? currentCompanyId : null);
    if (selectedActiveCompanyId != null && selectedActiveCompanyId.isEmpty) selectedActiveCompanyId = null;
    
    final initialFound = kAllCountries.firstWhere((c) => c['phoneCode'] == initialCountryCode, orElse: () => kAllCountries.firstWhere((c) => c['name'] == 'United States'));
    String initialCountryName = initialFound['name']!;

    final l10n = AppLocalizations.of(context)!;
    String companySearchQuery = '';

    showDialog(
      context: context,
      builder: (context) {
        bool isSelectingActive = false;
        String activeSearchQuery = '';
        String selectedCountryCode = initialCountryCode;
        String selectedCountryName = initialCountryName;

        return StatefulBuilder(
          builder: (context, setDialogState) {
            final filteredCompanies = allCompanies.where((c) => 
              c.name.toLowerCase().contains(companySearchQuery.toLowerCase())
            ).toList();

            final selectedCompaniesList = allCompanies.where((c) => 
              selectedCompanyIds.contains(c.id) &&
              c.name.toLowerCase().contains(activeSearchQuery.toLowerCase())
            ).toList();

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
                      Text(
                        isEditing ? l10n.editUserTitle : l10n.createNewUserTitle,
                        style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        isEditing ? l10n.updateRoleDetails : l10n.registerNewUser,
                        style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                      ),
                      const SizedBox(height: 24),
                      TextField(controller: emailCtrl, decoration: InputDecoration(labelText: l10n.emailAddressLabel, prefixIcon: const Icon(Icons.email_outlined)), readOnly: isEditing),
                      const SizedBox(height: 14),
                      if (!isEditing) ...[
                        TextField(controller: passwordCtrl, decoration: InputDecoration(labelText: l10n.passwordLabel, prefixIcon: const Icon(Icons.lock_outline)), obscureText: true),
                        const SizedBox(height: 14),
                      ],
                      TextField(
                        controller: usernameCtrl,
                        decoration: InputDecoration(
                          labelText: l10n.displayNameLabel,
                          prefixIcon: const Icon(Icons.person_outline),
                        ),
                      ),
                      const SizedBox(height: 14),
                      // ── Phone number with inline country code picker ──────
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: l10n.phoneNumber,
                          prefixIcon: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(left: 12, right: 4),
                                child: Icon(Icons.phone_outlined),
                              ),
                              DropdownButtonHideUnderline(
                                child: DropdownButton<String>(
                                  value: selectedCountryName,
                                  isDense: true,
                                  icon: const Icon(Icons.arrow_drop_down, size: 16),
                                  items: kAllCountries
                                      .map((c) => DropdownMenuItem<String>(
                                            value: c['name'],
                                            child: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                Text(c['flag'] ?? '', style: const TextStyle(fontSize: 16)),
                                                const SizedBox(width: 4),
                                                Text(
                                                  '${c['phoneCode']} - ${c['name']}',
                                                  style: const TextStyle(fontSize: 14),
                                                ),
                                              ],
                                            ),
                                          ))
                                      .toList(),
                                  onChanged: (v) {
                                    if (v == null) return;
                                    final country = kAllCountries.firstWhere((c) => c['name'] == v);
                                    setDialogState(() {
                                      selectedCountryName = v;
                                      selectedCountryCode = country['phoneCode']!;
                                    });
                                  },
                                ),
                              ),
                              Container(
                                width: 1,
                                height: 24,
                                margin: const EdgeInsets.only(left: 4, right: 12),
                                color: AppColors.border,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 14),
                      TextField(controller: addressCtrl, decoration: InputDecoration(labelText: l10n.address, prefixIcon: const Icon(Icons.home_outlined))),
                      const SizedBox(height: 14),
                      TextField(controller: emergencyCtrl, decoration: InputDecoration(labelText: l10n.emergencyContact, prefixIcon: const Icon(Icons.health_and_safety_outlined))),
                      const SizedBox(height: 14),
                      DropdownButtonFormField<AppRole>(
                        value: selectedRole,
                        decoration: InputDecoration(labelText: l10n.roleLabel, prefixIcon: const Icon(Icons.manage_accounts_outlined)),
                        items: AppRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.displayName))).toList(),
                        onChanged: (v) { if (v != null) setDialogState(() => selectedRole = v); },
                      ),
                      if (isSuperAdmin) ...[
                        const SizedBox(height: 24),
                        const Text('Company Membership', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                        const Text('Search and toggle company access.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        const SizedBox(height: 8),
                        TextField(
                          decoration: const InputDecoration(
                            hintText: 'Search companies...',
                            prefixIcon: Icon(Icons.search, size: 20),
                          ),
                          onChanged: (v) => setDialogState(() => companySearchQuery = v),
                        ),
                        const SizedBox(height: 8),
                        Container(
                          height: 150,
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.grey.shade200),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: ListView.builder(
                            itemCount: filteredCompanies.length,
                            itemBuilder: (context, index) {
                              final comp = filteredCompanies[index];
                              final isSelected = selectedCompanyIds.contains(comp.id);
                              return CheckboxListTile(
                                title: Text(comp.name, style: const TextStyle(fontSize: 13)),
                                value: isSelected,
                                onChanged: (val) {
                                  setDialogState(() {
                                    if (val == true) {
                                      selectedCompanyIds.add(comp.id);
                                      selectedActiveCompanyId ??= comp.id;
                                    } else {
                                      selectedCompanyIds.remove(comp.id);
                                      if (selectedActiveCompanyId == comp.id) {
                                        selectedActiveCompanyId = selectedCompanyIds.indexed.firstOrNull?.$2;
                                      }
                                    }
                                  });
                                },
                                dense: true,
                                controlAffinity: ListTileControlAffinity.leading,
                              );
                            },
                          ),
                        ),
                        if (selectedCompanyIds.isNotEmpty) ...[
                          const SizedBox(height: 24),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Active Company Selection', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                              if (isSelectingActive)
                                TextButton.icon(
                                  onPressed: () => setDialogState(() => isSelectingActive = false),
                                  icon: const Icon(Icons.close, size: 16),
                                  label: const Text('Cancel', style: TextStyle(fontSize: 12)),
                                ),
                            ],
                          ),
                          const Text('The primary company context for this user.', style: TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                          const SizedBox(height: 8),
                          if (!isSelectingActive)
                            InkWell(
                              onTap: () => setDialogState(() => isSelectingActive = true),
                              borderRadius: BorderRadius.circular(12),
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                                  borderRadius: BorderRadius.circular(12),
                                  color: AppColors.primary.withValues(alpha: 0.05),
                                ),
                                child: Row(
                                  children: [
                                    const Icon(Icons.business_center, color: AppColors.primary, size: 20),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        allCompanies.firstWhere((c) => c.id == selectedActiveCompanyId, orElse: () => Company(id: '', name: 'None Selected', ownerUid: '', tier: SubscriptionTier.free, status: SubscriptionStatus.active, propertyCount: 0, createdAt: DateTime.now())).name,
                                        style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                                      ),
                                    ),
                                    const Icon(Icons.unfold_more, size: 18, color: AppColors.textSecondary),
                                  ],
                                ),
                              ),
                            )
                          else ...[
                            TextField(
                              decoration: const InputDecoration(
                                hintText: 'Search selected companies...',
                                prefixIcon: Icon(Icons.search, size: 20),
                              ),
                              onChanged: (v) => setDialogState(() => activeSearchQuery = v),
                            ),
                            const SizedBox(height: 8),
                            Container(
                              constraints: const BoxConstraints(maxHeight: 200),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.grey.shade200),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: ListView.builder(
                                shrinkWrap: true,
                                itemCount: selectedCompaniesList.length,
                                itemBuilder: (context, index) {
                                  final comp = selectedCompaniesList[index];
                                  return ListTile(
                                    title: Text(comp.name, style: const TextStyle(fontSize: 13)),
                                    trailing: selectedActiveCompanyId == comp.id ? const Icon(Icons.check_circle, color: AppColors.primary, size: 18) : null,
                                    onTap: () => setDialogState(() {
                                      selectedActiveCompanyId = comp.id;
                                      isSelectingActive = false;
                                    }),
                                    dense: true,
                                  );
                                },
                              ),
                            ),
                          ],
                        ],
                      ],
                      const SizedBox(height: 28),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(onPressed: () => Navigator.pop(context), child: Text(l10n.cancelAction)),
                          const SizedBox(width: 12),
                          FilledButton(
                            onPressed: () async {
                              final activeId = selectedActiveCompanyId;
                              try {
                                if (isEditing) {
                                  await repo.update(User(
                                    id: existingUser!.id,
                                    username: usernameCtrl.text.trim(),
                                    role: selectedRole,
                                    email: existingUser.email,
                                    phone: phoneCtrl.text.trim().isNotEmpty
                                        ? phoneCtrl.text.trim().replaceAll(RegExp(r'[^\d]'), '')
                                        : null,
                                    phoneCountryCode: selectedCountryCode.replaceAll('+', ''),
                                    address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                                    emergencyContact: emergencyCtrl.text.trim().isNotEmpty ? emergencyCtrl.text.trim() : null,
                                    companyIds: selectedCompanyIds,
                                    activeCompanyId: activeId,
                                  ));
                                } else {
                                  await repo.add(
                                    email: emailCtrl.text.trim(),
                                    password: passwordCtrl.text,
                                    companyIds: selectedCompanyIds,
                                    activeCompanyId: activeId,
                                    user: User(
                                      id: '',
                                      username: usernameCtrl.text.trim(),
                                      role: selectedRole,
                                      phone: phoneCtrl.text.trim().isNotEmpty
                                         ? phoneCtrl.text.trim().replaceAll(RegExp(r'[^\d]'), '')
                                         : null,
                                      phoneCountryCode: selectedCountryCode.replaceAll('+', ''),
                                      address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                                      emergencyContact: emergencyCtrl.text.trim().isNotEmpty ? emergencyCtrl.text.trim() : null,
                                      companyIds: selectedCompanyIds,
                                      activeCompanyId: activeId,
                                    ),
                                  );
                                }
                                if (context.mounted) {
                                  Navigator.pop(context);
                                  await _loadUsers();
                                }
                              } catch (e) {
                                if (context.mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${l10n.errorOccurred} $e'), backgroundColor: AppColors.error));
                                }
                              }
                            },
                            child: Text(isEditing ? l10n.saveChanges : l10n.createUserAction),
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

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(userRepositoryProvider);
    ref.watch(globalCompaniesProvider);
    
    final filtered = _filtered;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.usersTitle),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          final currentUser = ref.read(authControllerProvider);
          final companyId = currentUser?.activeCompanyId;
          if (companyId != null && companyId.isNotEmpty) {
            final company = ref.read(companyProvider(companyId)).valueOrNull;
            if (company != null) {
              final maxUsers = company.tier.maxUsers;
              final currentCount = _allUsers.where((u) => u.role != AppRole.superAdmin).length;
              if (currentCount >= maxUsers) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('${l10n.userLimitReachedPrefix} ($currentCount/$maxUsers). ${l10n.userLimitReachedSuffix.replaceFirst('plan', '${company.tier.displayName} plan')}'),
                    backgroundColor: AppColors.error,
                    duration: const Duration(seconds: 4),
                    action: SnackBarAction(label: l10n.upgradeAction, textColor: Colors.white, onPressed: () => context.go('/billing')),
                  ),
                );
                return;
              }
            }
          }
          _showUserDialog(context, ref, repo);
        },
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_outlined),
        label: Text(l10n.addUserAction),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('${l10n.errorOccurred} $_error'))
              : Column(
                  children: [
                    Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: l10n.searchUsersHint,
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
                          const SizedBox(height: 12),
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterChip(
                                  label: l10n.allRolesFilter,
                                  selected: _roleFilter == null,
                                  onSelected: (_) => setState(() => _roleFilter = null),
                                ),
                                ...AppRole.values.map((role) => Padding(
                                  padding: const EdgeInsets.only(left: 8),
                                  child: _FilterChip(
                                    label: role.displayName,
                                    selected: _roleFilter == role,
                                    onSelected: (_) => setState(() => _roleFilter = _roleFilter == role ? null : role),
                                  ),
                                )),
                              ],
                            ),
                          ),
                          const SizedBox(height: 10),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '${filtered.length} ${l10n.ofKeyword} ${_allUsers.length} ${l10n.usersKeyword}',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    Expanded(
                      child: filtered.isEmpty
                          ? _EmptyState(
                              icon: Icons.person_search_outlined,
                              title: l10n.noUsersFound,
                              subtitle: _query.isNotEmpty || _roleFilter != null
                                  ? l10n.tryDifferentSearch
                                  : l10n.addFirstUserAbove,
                            )
                          : ListView.separated(
                              padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const SizedBox(height: 8),
                              itemBuilder: (context, index) {
                                final user = filtered[index];
                                return _UserCard(
                                  user: user,
                                  onEdit: () => _showUserDialog(context, ref, repo, existingUser: user),
                                  onDelete: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: Text(l10n.deleteUserTitle),
                                        content: Text('${l10n.deletePromptPrefix} ${user.username}${l10n.deletePromptSuffix}'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(l10n.cancelAction)),
                                          FilledButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                                            child: Text(l10n.deleteAction),
                                          ),
                                        ],
                                      ),
                                    );
                                    if (confirm == true && mounted) {
                                      await repo.delete(user.id);
                                      await _loadUsers();
                                    }
                                  },
                                );
                              },
                            ),
                    ),
                  ],
                ),
    );
  }
}

// ── User Card ───────────────────────────────────────────────────────────────
class _UserCard extends StatelessWidget {
  final User user;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  const _UserCard({required this.user, required this.onEdit, required this.onDelete});

  Color _roleColor(AppRole role) {
    switch (role) {
      case AppRole.superAdmin: return const Color(0xFF7C3AED);
      case AppRole.administrator: return AppColors.primary;
      case AppRole.manager: return AppColors.teal;
      case AppRole.cleaner: return AppColors.green;
      case AppRole.inspector: return AppColors.amber;
      case AppRole.owner: return const Color(0xFF0EA5E9);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _roleColor(user.role);
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: color.withValues(alpha: 0.12),
              child: Text(
                user.username.substring(0, 1).toUpperCase(),
                style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 16),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.username,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (user.email != null)
                    Text(
                      user.email!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  if (user.phone != null)
                    Text(
                      user.phone!,
                      style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: color.withValues(alpha: 0.3)),
              ),
              child: Text(user.role.displayName, style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.w600)),
            ),
            IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary), onPressed: onEdit),
            IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error), onPressed: onDelete),
          ],
        ),
      ),
    );
  }
}

// ── Shared: Filter Chip ──────────────────────────────────────────────────────
class _FilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  const _FilterChip({required this.label, required this.selected, required this.onSelected});

  @override
  Widget build(BuildContext context) {
    return FilterChip(
      label: Text(label),
      selected: selected,
      onSelected: onSelected,
      selectedColor: AppColors.primary,
      checkmarkColor: Colors.white,
      labelStyle: TextStyle(
        color: selected ? Colors.white : AppColors.textSecondary,
        fontSize: 12,
        fontWeight: selected ? FontWeight.w600 : FontWeight.normal,
      ),
      backgroundColor: AppColors.background,
      side: BorderSide(color: selected ? AppColors.primary : AppColors.border),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
    );
  }
}

// ── Shared: Empty State ──────────────────────────────────────────────────────
class _EmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyState({required this.icon, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 64, color: AppColors.border),
          const SizedBox(height: 16),
          Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
          const SizedBox(height: 6),
          Text(subtitle, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
        ],
      ),
    );
  }
}
