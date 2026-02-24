import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../admin/data/user_repository.dart';
import '../../auth/domain/user.dart';
import '../../../core/constants/roles.dart';
import '../../../core/theme/app_colors.dart';

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

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(userRepositoryProvider);
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Users'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showUserDialog(context, ref, repo),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.person_add_outlined),
        label: const Text('Add User'),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('Error: $_error'))
              : Column(
                  children: [
                    // ── Search + Filter header ────────────────────────────
                    Container(
                      color: AppColors.surface,
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Search bar
                          TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: 'Search by name, email or phone…',
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
                          // Role filter chips
                          SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              children: [
                                _FilterChip(
                                  label: 'All Roles',
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
                          // Results count
                          Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Text(
                              '${filtered.length} of ${_allUsers.length} users',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    // ── List ─────────────────────────────────────────────
                    Expanded(
                      child: filtered.isEmpty
                          ? _EmptyState(
                              icon: Icons.person_search_outlined,
                              title: 'No users found',
                              subtitle: _query.isNotEmpty || _roleFilter != null
                                  ? 'Try a different search or filter'
                                  : 'Add your first user above',
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
                                        title: const Text('Delete User'),
                                        content: Text('Delete ${user.username}? This action cannot be undone.'),
                                        actions: [
                                          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                          FilledButton(
                                            onPressed: () => Navigator.pop(ctx, true),
                                            style: FilledButton.styleFrom(backgroundColor: AppColors.error),
                                            child: const Text('Delete'),
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

  void _showUserDialog(BuildContext context, WidgetRef ref, UserRepository repo, {User? existingUser}) {
    final isEditing = existingUser != null;
    final emailCtrl = TextEditingController(text: existingUser?.email ?? '');
    final passwordCtrl = TextEditingController();
    final usernameCtrl = TextEditingController(text: existingUser?.username ?? '');
    final phoneCtrl = TextEditingController(text: existingUser?.phone ?? '');
    final addressCtrl = TextEditingController(text: existingUser?.address ?? '');
    final emergencyCtrl = TextEditingController(text: existingUser?.emergencyContact ?? '');
    final payRateCtrl = TextEditingController(text: existingUser?.payRate?.toString() ?? '');
    AppRole selectedRole = existingUser?.role ?? AppRole.cleaner;

    showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => Dialog(
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
                    isEditing ? 'Edit User' : 'Create New User',
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    isEditing ? 'Update role or contact details.' : 'Register a new user in the system.',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 24),
                  TextField(controller: emailCtrl, decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)), readOnly: isEditing),
                  const SizedBox(height: 14),
                  if (!isEditing) ...[
                    TextField(controller: passwordCtrl, decoration: const InputDecoration(labelText: 'Password', prefixIcon: Icon(Icons.lock_outline)), obscureText: true),
                    const SizedBox(height: 14),
                  ],
                  TextField(controller: usernameCtrl, decoration: const InputDecoration(labelText: 'Display Name', prefixIcon: Icon(Icons.person_outline))),
                  const SizedBox(height: 14),
                  TextField(controller: phoneCtrl, decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)), keyboardType: TextInputType.phone),
                  const SizedBox(height: 14),
                  TextField(controller: addressCtrl, decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.home_outlined))),
                  const SizedBox(height: 14),
                  TextField(controller: emergencyCtrl, decoration: const InputDecoration(labelText: 'Emergency Contact', prefixIcon: Icon(Icons.health_and_safety_outlined))),
                  const SizedBox(height: 14),
                  TextField(controller: payRateCtrl, decoration: const InputDecoration(labelText: 'Pay Rate', prefixIcon: Icon(Icons.attach_money_outlined)), keyboardType: const TextInputType.numberWithOptions(decimal: true)),
                  const SizedBox(height: 14),
                  DropdownButtonFormField<AppRole>(
                    value: selectedRole,
                    decoration: const InputDecoration(labelText: 'Role', prefixIcon: Icon(Icons.manage_accounts_outlined)),
                    items: AppRole.values.map((r) => DropdownMenuItem(value: r, child: Text(r.displayName))).toList(),
                    onChanged: (v) { if (v != null) setDialogState(() => selectedRole = v); },
                  ),
                  const SizedBox(height: 28),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                      const SizedBox(width: 12),
                      FilledButton(
                        onPressed: () async {
                          try {
                            if (isEditing) {
                              await repo.update(User(
                                id: existingUser!.id,
                                username: usernameCtrl.text.trim(),
                                role: selectedRole,
                                email: existingUser.email,
                                phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                                address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                                emergencyContact: emergencyCtrl.text.trim().isNotEmpty ? emergencyCtrl.text.trim() : null,
                                payRate: double.tryParse(payRateCtrl.text.trim()),
                              ));
                            } else {
                              await repo.add(
                                email: emailCtrl.text.trim(),
                                password: passwordCtrl.text,
                                user: User(
                                  id: '',
                                  username: usernameCtrl.text.trim(),
                                  role: selectedRole,
                                  phone: phoneCtrl.text.trim().isNotEmpty ? phoneCtrl.text.trim() : null,
                                  address: addressCtrl.text.trim().isNotEmpty ? addressCtrl.text.trim() : null,
                                  emergencyContact: emergencyCtrl.text.trim().isNotEmpty ? emergencyCtrl.text.trim() : null,
                                  payRate: double.tryParse(payRateCtrl.text.trim()),
                                ),
                              );
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                              await _loadUsers();
                            }
                          } catch (e) {
                            if (context.mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error));
                            }
                          }
                        },
                        child: Text(isEditing ? 'Save Changes' : 'Create User'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
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
                  Text(user.username, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.textPrimary)),
                  if (user.email != null)
                    Text(user.email!, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                  if (user.phone != null)
                    Text(user.phone!, style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
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
