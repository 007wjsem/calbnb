import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:async';
import 'dart:convert';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import '../../admin/data/property_repository.dart';
import '../../admin/domain/property.dart';
import '../../company/data/company_repository.dart';
import '../../company/domain/company.dart';
import '../../auth/data/auth_repository.dart';
import '../../admin/data/user_repository.dart';
import '../../auth/domain/user.dart' as domain_user;
import '../../../core/constants/roles.dart';
import '../../../core/theme/app_colors.dart';
import '../../company/domain/subscription.dart';
import 'package:calbnb/l10n/app_localizations.dart';

class PropertyManagementScreen extends ConsumerStatefulWidget {
  final String? companyId;
  const PropertyManagementScreen({super.key, this.companyId});

  @override
  ConsumerState<PropertyManagementScreen> createState() => _PropertyManagementScreenState();
}
class _PropertyManagementScreenState extends ConsumerState<PropertyManagementScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';
  String? _cityFilter;
  String? _mgmtFilter;
  List<Property> _allProperties = [];
  bool _loading = true;
  String? _error;

  StreamSubscription<List<Property>>? _propSub;
  PropertyRepository? _lastRepo;

  @override
  void initState() {
    super.initState();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Re-subscribe whenever the repository instance changes (e.g., after auth state
    // changes that cause propertyRepositoryProvider to reconstruct).
    final repo = ref.read(propertyRepositoryProvider);
    if (repo != _lastRepo) {
      _lastRepo = repo;
      _subscribeToProperties();
    }
  }

  @override
  void dispose() {
    _propSub?.cancel();
    _searchCtrl.dispose();
    super.dispose();
  }


  void _subscribeToProperties() {
    setState(() => _loading = true);
    final repo = ref.read(propertyRepositoryProvider);
    _propSub?.cancel();
    _propSub = repo.watchAll().listen(
      (props) {
        final filteredProps = widget.companyId != null
            ? props.where((p) => p.companyId == widget.companyId).toList()
            : props;
        filteredProps.sort((a, b) {
          if (a.order >= 0 && b.order >= 0) return a.order.compareTo(b.order);
          return a.name.toLowerCase().compareTo(b.name.toLowerCase());
        });
        if (mounted) setState(() { _allProperties = filteredProps; _loading = false; });
      },
      onError: (e) {
        if (mounted) setState(() { _error = e.toString(); _loading = false; });
      },
    );
  }

  // Keep _loadProperties so order-save can trigger a one-shot refresh if needed
  Future<void> _loadProperties() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(propertyRepositoryProvider);
      final props = await repo.fetchAll();
      final filteredProps = widget.companyId != null ? props.where((p) => p.companyId == widget.companyId).toList() : props;
      filteredProps.sort((a, b) {
        if (a.order >= 0 && b.order >= 0) return a.order.compareTo(b.order);
        return a.name.toLowerCase().compareTo(b.name.toLowerCase());
      });
      setState(() { _allProperties = filteredProps; _loading = false; });
    } catch (e) {
      setState(() { _error = e.toString(); _loading = false; });
    }
  }

  List<String> get _cities {
    final s = _allProperties.map((p) => p.city).where((c) => c.isNotEmpty).toSet().toList();
    s.sort();
    return s;
  }

  List<String> get _mgmts {
    final s = _allProperties.map((p) => p.propertyManagement).where((m) => m.isNotEmpty).toSet().toList();
    s.sort();
    return s;
  }

  List<Property> get _filtered {
    return _allProperties.where((p) {
      final matchesQuery = _query.isEmpty ||
          p.name.toLowerCase().contains(_query) ||
          p.address.toLowerCase().contains(_query) ||
          p.city.toLowerCase().contains(_query) ||
          p.ownerName.toLowerCase().contains(_query) ||
          p.propertyManagement.toLowerCase().contains(_query);
      final matchesCity = _cityFilter == null || p.city == _cityFilter;
      final matchesMgmt = _mgmtFilter == null || p.propertyManagement == _mgmtFilter;
      return matchesQuery && matchesCity && matchesMgmt;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(propertyRepositoryProvider);
    final currentUser = ref.watch(authControllerProvider);
    final isSuperAdmin = currentUser?.role.displayName == 'Super Admin';
    final activeCompanyId = currentUser?.activeCompanyId;
    final companyAsync = activeCompanyId != null ? ref.watch(companyProvider(activeCompanyId)) : const AsyncValue.loading();
    final company = companyAsync.valueOrNull;
    final companyCurrency = company?.currencySymbol ?? '\$';
    
    // Warm up global companies for SuperAdmin use cases
    if (isSuperAdmin) {
      ref.watch(globalCompaniesProvider);
    }
    final bool canAddProperty = isSuperAdmin || (company != null && (company.tier.includedProperties == null || _allProperties.length < company.tier.includedProperties!));

    final filtered = _filtered;
    final cities = _cities;
    final mgmts = _mgmts;
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.propertiesTitle),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/'),
        ),
        actions: [
          if (isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: l10n.generateDummyProperty,
              onPressed: () async {
                // Check if already loading
                final initialAsync = ref.read(globalCompaniesProvider);
                
                List<Company>? companies;
                
                if (initialAsync.isLoading) {
                  // Show a temporary loading dialog/overlay
                  showDialog(
                    context: context,
                    barrierDismissible: false,
                    builder: (ctx) => const Center(child: CircularProgressIndicator()),
                  );
                  
                  try {
                    // Wait for the next value from the stream with a timeout
                    companies = await ref.read(globalCompaniesProvider.future).timeout(const Duration(seconds: 5));
                    if (context.mounted) Navigator.pop(context); // Close loading dialog
                  } catch (e) {
                    if (context.mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Timeout or error loading companies. Using fallback.')));
                    }
                    companies = initialAsync.valueOrNull ?? [];
                  }
                } else {
                  companies = initialAsync.valueOrNull ?? [];
                }

                String? selectedId = activeCompanyId;
                final List<Company> finalCompanies = companies ?? [];

                if (finalCompanies.isNotEmpty) {
                  selectedId = await showDialog<String>(
                    context: context,
                    builder: (ctx) {
                      String? dialogSelected = activeCompanyId ?? (finalCompanies.isEmpty ? null : finalCompanies.first.id);
                      return StatefulBuilder(
                        builder: (ctx, setDialogState) {
                          return AlertDialog(
                            title: Text(l10n.generateDummyProperty),
                            content: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(l10n.selectCompanyHint),
                                const SizedBox(height: 16),
                                DropdownButtonFormField<String>(
                                  isExpanded: true,
                                  value: dialogSelected,
                                  items: finalCompanies.map((c) => DropdownMenuItem(
                                    value: c.id,
                                    child: Text(c.name),
                                  )).toList(),
                                  onChanged: (val) => setDialogState(() => dialogSelected = val),
                                ),
                              ],
                            ),
                            actions: [
                              TextButton(onPressed: () => Navigator.pop(ctx), child: Text(l10n.cancelAction)),
                              FilledButton(
                                onPressed: () => Navigator.pop(ctx, dialogSelected),
                                child: Text(l10n.generateAction),
                              ),
                            ],
                          );
                        }
                      );
                    }
                  );
                } else if (activeCompanyId == null) {
                   if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('No companies available. Please create a company first.')),
                    );
                   }
                  return;
                }

                if (selectedId != null) {
                  final dummyProp = _generateDummyProperty(selectedId);
                  await repo.add(dummyProp);
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${dummyProp.name}')));
                  }
                }
              },
            ),
        ],
      ),
      // ── Bottom bar shown only in reorder mode ──────────────────────────
      bottomNavigationBar: null,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: canAddProperty 
            ? () => _showPropertyDialog(context, ref, repo, currencySymbol: companyCurrency)
            : () => _showLimitDialog(context, company?.tier.includedProperties ?? 5, l10n),
        backgroundColor: canAddProperty ? AppColors.primary : Colors.grey.shade600,
        foregroundColor: Colors.white,
        icon: Icon(canAddProperty ? Icons.add_home_outlined : Icons.lock_outline),
        label: Text(canAddProperty ? l10n.addPropertyAction : l10n.limitReached),
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text('${l10n.errorOccurred} $_error'))
              : Column(
                  children: [
                    // ── Search + Filter header ────────────────────────────
                      Container(
                        color: AppColors.surface,
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            TextField(
                              controller: _searchCtrl,
                              decoration: InputDecoration(
                                hintText: l10n.searchPropertiesHint,
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
                            const SizedBox(height: 10),
                            // City filter chips
                            if (cities.isNotEmpty) ...[  
                              Text(l10n.cityLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
                              const SizedBox(height: 6),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _PropFilterChip(
                                      label: l10n.allCitiesFilter,
                                      selected: _cityFilter == null,
                                      onSelected: (_) => setState(() => _cityFilter = null),
                                    ),
                                    ...cities.map((c) => Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: _PropFilterChip(
                                        label: c,
                                        selected: _cityFilter == c,
                                        onSelected: (_) => setState(() => _cityFilter = _cityFilter == c ? null : c),
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            // Management filter chips
                            if (mgmts.isNotEmpty) ...[  
                              Text(l10n.propertyManagementLabel, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
                              const SizedBox(height: 6),
                              SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: Row(
                                  children: [
                                    _PropFilterChip(
                                      label: l10n.allFilter,
                                      selected: _mgmtFilter == null,
                                      onSelected: (_) => setState(() => _mgmtFilter = null),
                                    ),
                                    ...mgmts.map((m) => Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: _PropFilterChip(
                                        label: m,
                                        selected: _mgmtFilter == m,
                                        onSelected: (_) => setState(() => _mgmtFilter = _mgmtFilter == m ? null : m),
                                      ),
                                    )),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 8),
                            ],
                            Padding(
                              padding: const EdgeInsets.only(bottom: 8),
                              child: Text(
                                '${filtered.length} ${l10n.ofKeyword} ${_allProperties.length} ${l10n.propertiesKeyword}',
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
                            ? Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.home_work_outlined, size: 64, color: AppColors.border),
                                    const SizedBox(height: 16),
                                    Text(l10n.noPropertiesFound, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                    const SizedBox(height: 6),
                                    Text(l10n.tryAdjustingSearchFilters, style: const TextStyle(fontSize: 13, color: AppColors.textSecondary)),
                                  ],
                                ),
                              )
                            : ListView.separated(
                                padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
                                itemCount: filtered.length,
                                separatorBuilder: (_, __) => const SizedBox(height: 8),
                                itemBuilder: (context, index) {
                                  final property = filtered[index];
                                  final globalIndex = _allProperties.indexOf(property) + 1;
                                  return _PropertyCard(
                                    property: property,
                                    index: globalIndex,
                                    currencySymbol: companyCurrency,
                                    onEdit: () => _showPropertyDialog(context, ref, repo, existingProperty: property, currencySymbol: companyCurrency),
                                    onDelete: () async {
                                      final confirm = await showDialog<bool>(
                                        context: context,
                                        builder: (ctx) => AlertDialog(
                                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                          title: Text(l10n.deletePropertyTitle),
                                          content: Text(l10n.deletePropertyPrompt(property.name)),
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
                                        await repo.delete(property.id);
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

  void _showPropertyDialog(BuildContext context, WidgetRef ref, PropertyRepository repo, {Property? existingProperty, String currencySymbol = '\$'}) {
    final isEditing = existingProperty != null;
    final nameController = TextEditingController(text: existingProperty?.name ?? '');
    final addressController = TextEditingController(text: existingProperty?.address ?? '');
    final zipCodeController = TextEditingController(text: existingProperty?.zipCode ?? '');
    final cityController = TextEditingController(text: existingProperty?.city ?? '');
    final stateController = TextEditingController(text: isEditing ? existingProperty!.state : '');
    final countryController = TextEditingController(text: isEditing ? existingProperty!.country : '');
    final syncIdController = TextEditingController(text: isEditing ? existingProperty!.syncId : '');
    final cleaningFeeController = TextEditingController(text: isEditing ? existingProperty!.cleaningFee.toStringAsFixed(2) : '');
    final sizeController = TextEditingController(text: existingProperty?.size ?? '');
    final ownerNameController = TextEditingController(text: existingProperty?.ownerName ?? '');

    final ownerPhoneController = TextEditingController(text: existingProperty?.ownerPhone ?? '');
    final ownerEmailController = TextEditingController(text: existingProperty?.ownerEmail ?? '');
    final propertyMgmtController = TextEditingController(text: existingProperty?.propertyManagement ?? '');
    final lockBoxPinController = TextEditingController(text: existingProperty?.lockBoxPin ?? '');
    final housePinController = TextEditingController(text: existingProperty?.housePin ?? '');
    final garagePinController = TextEditingController(text: existingProperty?.garagePin ?? '');
    final cleaningInstructionsController = TextEditingController(text: existingProperty?.cleaningInstructions ?? '');
    List<String> instructionPhotos = List.from(existingProperty?.instructionPhotos ?? []);
    List<String> checklists = List.from(existingProperty?.checklists ?? []);
    final newChecklistCtrl = TextEditingController();
    
    bool isCohost = existingProperty?.isCohost ?? false;
    final ImagePicker picker = ImagePicker();
    
    String selectedType = existingProperty?.propertyType == 'Apartment' || existingProperty?.propertyType == 'Other' 
        ? existingProperty!.propertyType 
        : 'House';

    String? selectedOwnerAccountId = existingProperty?.ownerAccountId;

    // Determine the user context for company access
    final currentUser = ref.read(authControllerProvider);
    final isSuperAdmin = currentUser?.role.displayName == 'Super Admin';
    final userCompanyId = currentUser?.activeCompanyId ?? '';
    
    // For super admins selecting target company; start with existing or empty
    String selectedCompanyId = existingProperty?.companyId.isNotEmpty == true
        ? existingProperty!.companyId
        : (isSuperAdmin ? '' : userCompanyId);
        
    // Watch the active company for Silver-tier gating
    final activeCompId = selectedCompanyId.isNotEmpty ? selectedCompanyId : userCompanyId;
    final companyAsync = ref.watch(companyProvider(activeCompId));
    final hasSilverTier = (companyAsync.valueOrNull?.tier.index ?? 0) >= SubscriptionTier.silver.index;

    int currentStep = 0;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            final isMobile = MediaQuery.of(context).size.width < 600;

            Widget buildResponsiveRow(List<Widget> children) {
              if (isMobile) {
                return Column(
                  children: children.map((c) {
                    if (c is Expanded) return Padding(padding: const EdgeInsets.only(bottom: 16), child: c.child);
                    if (c is SizedBox && (c.width ?? 0) > 0) return const SizedBox.shrink();
                    return c;
                  }).toList(),
                );
              }
              return Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: children,
              );
            }

            Widget buildCompanySelector() {
              final l10n = AppLocalizations.of(context)!;
              if (isSuperAdmin) {
                return Consumer(builder: (ctx, cref, _) {
                  final companiesAsync = cref.watch(globalCompaniesProvider);
                  return companiesAsync.when(
                    data: (companies) => DropdownButtonFormField<String>(
                      isExpanded: true,
                      value: selectedCompanyId.isNotEmpty ? selectedCompanyId : null,
                      decoration: InputDecoration(
                        labelText: l10n.assignToCompanyLabel,
                        prefixIcon: const Icon(Icons.business_outlined),
                      ),
                      hint: Text(l10n.selectCompanyHint),
                      items: companies.map((c) => DropdownMenuItem(
                        value: c.id,
                        child: Text(c.name),
                      )).toList(),
                      onChanged: (val) => setState(() => selectedCompanyId = val ?? ''),
                    ),
                    loading: () => const LinearProgressIndicator(),
                    error: (e, _) => Text('Error: $e'),
                  );
                });
              } else {
                return Consumer(builder: (ctx, cref, _) {
                  final companyAsync = userCompanyId.isNotEmpty
                      ? cref.watch(companyProvider(userCompanyId))
                      : const AsyncValue<dynamic>.data(null);
                  final company = companyAsync.valueOrNull;
                  return InputDecorator(
                    decoration: InputDecoration(
                      labelText: AppLocalizations.of(context)!.companyLabel,
                      prefixIcon: const Icon(Icons.business_outlined),
                    ),
                    child: Text(
                      company?.name ?? userCompanyId,
                      style: const TextStyle(color: AppColors.textPrimary),
                    ),
                  );
                });
              }
            }

            final l10n = AppLocalizations.of(context)!;
            
            final steps = [
              Step(
                title: Text(l10n.stepBasic, style: const TextStyle(fontSize: 13)),
                isActive: currentStep >= 0,
                state: currentStep > 0 ? StepState.complete : StepState.indexed,
                content: Padding(
                  padding: const EdgeInsets.only(top: 8.0),
                  child: Column(
                    children: [
                      buildCompanySelector(),
                      const SizedBox(height: 16),
                      TextField(
                        controller: syncIdController,
                        decoration: InputDecoration(
                          labelText: l10n.syncIdLabel,
                          prefixIcon: const Icon(Icons.sync_alt),
                        ),
                      ),
                      const SizedBox(height: 16),
                      SwitchListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(l10n.isCohostLabel),
                        subtitle: Text(l10n.isCohostHelper, style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
                        value: isCohost,
                        onChanged: (val) {
                          setState(() {
                            isCohost = val;
                          });
                        },
                      ),
                      const SizedBox(height: 16),
                    buildResponsiveRow(
                      [
                        Expanded(
                          flex: 2,
                          child: TextField(
                            controller: nameController,
                            decoration: InputDecoration(labelText: l10n.propertyNameLabel, prefixIcon: const Icon(Icons.label_outline)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            isExpanded: true,
                            value: selectedType,
                            decoration: InputDecoration(labelText: l10n.propertyTypeLabel, prefixIcon: const Icon(Icons.category_outlined)),
                            items: [
                              DropdownMenuItem(value: 'House', child: Text(l10n.typeHouse)),
                              DropdownMenuItem(value: 'Apartment', child: Text(l10n.typeApartment)),
                              DropdownMenuItem(value: 'Other', child: Text(l10n.typeOther)),
                            ],
                            onChanged: (val) {
                              if (val != null) setState(() => selectedType = val);
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Step(
              title: Text(l10n.stepLocationDetails, style: const TextStyle(fontSize: 13)),
                isActive: currentStep >= 1,
                state: currentStep > 1 ? StepState.complete : StepState.indexed,
                content: Column(
                  children: [
                    TextField(
                      controller: addressController,
                      decoration: InputDecoration(labelText: l10n.streetAddressLabel, prefixIcon: const Icon(Icons.location_on_outlined)),
                    ),
                    const SizedBox(height: 16),
                    buildResponsiveRow(
                      [
                        Expanded(
                          child: TextField(
                            controller: cityController,
                            decoration: InputDecoration(labelText: l10n.cityLabel),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: stateController,
                            decoration: InputDecoration(labelText: l10n.stateProvinceLabel),
                          ),
                        ),
                      ],
                    ),
                    if (!isMobile) const SizedBox(height: 16),
                    buildResponsiveRow(
                      [
                        Expanded(
                          child: TextField(
                             controller: zipCodeController,
                             decoration: InputDecoration(labelText: l10n.zipPostalCodeLabel),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                             controller: countryController,
                             decoration: InputDecoration(labelText: l10n.countryLabel),
                          ),
                        ),
                      ],
                    ),
                    if (!isMobile) const SizedBox(height: 16),
                    buildResponsiveRow(
                      [
                        Expanded(
                          child: TextField(
                            controller: cleaningFeeController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                            decoration: InputDecoration(
                              labelText: l10n.cleaningFeeLabel, 
                              prefixIcon: Padding(
                                padding: const EdgeInsets.all(12.0),
                                child: Text(currencySymbol, style: const TextStyle(fontSize: 16)),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: sizeController,
                            decoration: InputDecoration(
                              labelText: l10n.sizeLabel, 
                              hintText: 'e.g. 2x1x1',
                              prefixIcon: const Icon(Icons.aspect_ratio)
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Step(
                title: Text(l10n.stepOwnerMgmt, style: const TextStyle(fontSize: 13)),
                isActive: currentStep >= 2,
                state: currentStep > 2 ? StepState.complete : StepState.indexed,
                content: Padding(
                  padding: const EdgeInsets.only(top: 16.0),
                  child: Column(
                    children: [
                    Consumer(
                      builder: (ctx, cref, _) {
                        final usersRef = cref.watch(userRepositoryProvider);
                        return FutureBuilder<List<domain_user.User>>( // Using `User` from auth domain via renamed mapping below
                          future: usersRef.fetchAll(),
                          builder: (context, snapshot) {
                            if (snapshot.connectionState == ConnectionState.waiting) {
                              return const LinearProgressIndicator();
                            }
                            
                            final allUsers = snapshot.data ?? [];
                            // Filter users who have the Owner role
                            final ownerUsers = allUsers.where((u) => u.role == AppRole.owner).toList();
                            
                            return DropdownButtonFormField<String>(
                              isExpanded: true,
                              value: selectedOwnerAccountId,
                              decoration: InputDecoration(
                                labelText: l10n.linkedOwnerAccountLabel,
                                prefixIcon: const Icon(Icons.manage_accounts_outlined),
                                helperText: l10n.linkedOwnerAccountHelper,
                              ),
                              items: ownerUsers.map((u) {
                                return DropdownMenuItem(
                                  value: u.id,
                                  child: Text('${u.username} (${u.email ?? "No Email"})'),
                                );
                              }).toList()
                                ..insert(0, DropdownMenuItem(value: null, child: Text(l10n.noneUnassigned))),
                              onChanged: (val) {
                                setState(() {
                                  selectedOwnerAccountId = val;
                                  
                                  // Auto-fill legacy text fields if an owner is selected
                                  if (val != null) {
                                    final match = ownerUsers.firstWhere((u) => u.id == val);
                                    ownerNameController.text = match.username;
                                    ownerEmailController.text = match.email ?? '';
                                    ownerPhoneController.text = match.phone ?? '';
                                  }
                                });
                              },
                            );
                          },
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    buildResponsiveRow(
                      [
                        Expanded(
                          child: TextField(
                            controller: ownerNameController,
                            decoration: InputDecoration(labelText: l10n.ownerNameLegacyLabel, prefixIcon: const Icon(Icons.person_outline)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: ownerPhoneController,
                            keyboardType: TextInputType.phone,
                            decoration: InputDecoration(labelText: l10n.phoneNumber, prefixIcon: const Icon(Icons.phone_outlined)),
                          ),
                        ),
                      ],
                    ),
                    if (!isMobile) const SizedBox(height: 16),
                    buildResponsiveRow(
                      [
                        Expanded(
                          child: TextField(
                            controller: ownerEmailController,
                            keyboardType: TextInputType.emailAddress,
                            decoration: InputDecoration(labelText: l10n.emailAddressLabel, prefixIcon: const Icon(Icons.email_outlined)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: propertyMgmtController,
                            decoration: InputDecoration(labelText: l10n.propertyManagementCompanyLabel, prefixIcon: const Icon(Icons.business_outlined)),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Step(
              title: Text(l10n.stepAccessCleaning, style: const TextStyle(fontSize: 13)),
                isActive: currentStep >= 3,
                state: currentStep > 3 ? StepState.complete : StepState.indexed,
                content: Column(
                  children: [
                    buildResponsiveRow(
                      [
                        Expanded(
                          child: TextField(
                            controller: lockBoxPinController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(labelText: l10n.lockBoxPinLabel, prefixIcon: const Icon(Icons.lock_outline)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: housePinController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(labelText: l10n.housePinLabel, prefixIcon: const Icon(Icons.door_front_door_outlined)),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextField(
                            controller: garagePinController,
                            keyboardType: TextInputType.text,
                            decoration: InputDecoration(labelText: l10n.garagePinLabel, prefixIcon: const Icon(Icons.garage_outlined)),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: cleaningInstructionsController,
                      maxLines: 4,
                      decoration: InputDecoration(labelText: l10n.cleaningInstructionsLabel, alignLabelWithHint: true, prefixIcon: const Icon(Icons.cleaning_services_outlined)),
                    ),
                    const SizedBox(height: 16),
                    
                    // --- Checklists section ---
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: Colors.grey.withValues(alpha: 0.2)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(l10n.customCleaningChecklistsTitle, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: TextField(
                                  controller: newChecklistCtrl,
                                  decoration: InputDecoration(
                                    hintText: l10n.addChecklistItemHint,
                                    prefixIcon: const Icon(Icons.check_box_outline_blank, size: 18),
                                  ),
                                  onSubmitted: (val) {
                                    if (val.trim().isNotEmpty) {
                                      setState(() {
                                        checklists.add(val.trim());
                                        newChecklistCtrl.clear();
                                      });
                                    }
                                  },
                                ),
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                icon: const Icon(Icons.add_circle, color: AppColors.primary),
                                tooltip: l10n.addChecklistItemTooltip,
                                onPressed: () {
                                  if (newChecklistCtrl.text.trim().isNotEmpty) {
                                    setState(() {
                                      checklists.add(newChecklistCtrl.text.trim());
                                      newChecklistCtrl.clear();
                                    });
                                  }
                                },
                              ),
                            ],
                          ),
                          if (checklists.isNotEmpty) ...[
                            const SizedBox(height: 12),
                            ListView.builder(
                              shrinkWrap: true,
                              physics: const NeverScrollableScrollPhysics(),
                              itemCount: checklists.length,
                              itemBuilder: (ctx, idx) {
                                return ListTile(
                                  dense: true,
                                  leading: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                  title: Text(checklists[idx], style: const TextStyle(fontSize: 13)),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete_outline, color: Colors.red, size: 18),
                                    onPressed: () {
                                      setState(() => checklists.removeAt(idx));
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final XFile? image = await picker.pickImage(source: ImageSource.gallery, imageQuality: 50, maxWidth: 800);
                          if (image != null) {
                            final bytes = await image.readAsBytes();
                            final base64String = base64Encode(bytes);
                            setState(() {
                              instructionPhotos.add(base64String);
                            });
                          }
                        },
                        icon: const Icon(Icons.add_a_photo),
                        label: Text(l10n.addInstructionPhotoAction),
                      ),
                    ),
                    if (instructionPhotos.isNotEmpty) ...[
                      const SizedBox(height: 16),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: instructionPhotos.asMap().entries.map((entry) {
                          final index = entry.key;
                          final photoB64 = entry.value;
                          return Stack(
                            children: [
                              Container(
                                width: 100,
                                height: 100,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                  image: DecorationImage(
                                    image: MemoryImage(base64Decode(photoB64)),
                                    fit: BoxFit.cover,
                                  ),
                                ),
                              ),
                              Positioned(
                                right: 0,
                                top: 0,
                                child: IconButton(
                                  icon: const Icon(Icons.cancel, color: Colors.red),
                                  onPressed: () {
                                    setState(() {
                                      instructionPhotos.removeAt(index);
                                    });
                                  },
                                ),
                              ),
                            ],
                          );
                        }).toList(),
                      ),
                    ],
                  ],
                ),
              ),
            ];

            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              clipBehavior: Clip.antiAlias,
              child: Container(
                constraints: const BoxConstraints(maxWidth: 900, maxHeight: 650),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
                      color: AppColors.primary.withOpacity(0.05),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  isEditing ? l10n.editPropertyTitle : l10n.addNewPropertyTitle,
                                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.textPrimary),
                                  overflow: TextOverflow.visible,
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  l10n.setupPropertyDetailsDesc,
                                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close),
                            onPressed: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1, thickness: 1),
                    Expanded(
                      child: Stepper(
                        type: MediaQuery.of(context).size.width < 600 ? StepperType.vertical : StepperType.horizontal,
                        currentStep: currentStep,
                        elevation: 0,
                        onStepTapped: (index) {
                          setState(() {
                            currentStep = index;
                          });
                        },
                        onStepContinue: () async {
                          if (currentStep < steps.length - 1) {
                            setState(() {
                              currentStep += 1;
                            });
                          } else {
                            // Final Save Validation
                            if (isSuperAdmin && selectedCompanyId.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text(l10n.pleaseSelectCompanyError)),
                              );
                              return;
                            }
                            
                            final newProp = Property(
                              id: isEditing ? existingProperty!.id : '',
                              companyId: selectedCompanyId,
                              name: nameController.text.trim(),
                              address: addressController.text.trim(),
                              zipCode: zipCodeController.text.trim(),
                              city: cityController.text.trim(),
                              state: stateController.text.trim(),
                              country: countryController.text.trim(),
                              propertyType: selectedType,
                              cleaningFee: double.tryParse(cleaningFeeController.text) ?? 0.0,
                              size: sizeController.text.trim(),
                              ownerName: ownerNameController.text.trim(),
                              ownerPhone: ownerPhoneController.text.trim(),
                              ownerEmail: ownerEmailController.text.trim(),
                              propertyManagement: propertyMgmtController.text.trim(),
                              lockBoxPin: lockBoxPinController.text.trim(),
                              housePin: housePinController.text.trim(),
                              garagePin: garagePinController.text.trim(),
                              order: isEditing ? existingProperty!.order : -1,
                              syncId: syncIdController.text.trim(),
                              isCohost: isCohost,
                              cleaningInstructions: cleaningInstructionsController.text.trim(),
                              instructionPhotos: instructionPhotos,
                              checklists: checklists,
                              ownerAccountId: selectedOwnerAccountId,
                              recurringCadence: existingProperty?.recurringCadence ?? 'none',
                              bufferHours: existingProperty?.bufferHours ?? 0,
                              trashDay: existingProperty?.trashDay ?? '',
                            );

                            if (isEditing) {
                              await repo.update(newProp);
                            } else {
                              await repo.add(newProp);
                            }
                            if (context.mounted) {
                              Navigator.pop(context);
                            }
                          }
                        },
                        onStepCancel: () {
                          if (currentStep > 0) {
                            setState(() {
                              currentStep -= 1;
                            });
                          } else {
                            Navigator.pop(context);
                          }
                        },
                        controlsBuilder: (context, details) {
                          final isLastStep = currentStep == steps.length - 1;
                          final isFirstStep = currentStep == 0;
                          return Padding(
                            padding: const EdgeInsets.only(top: 32),
                            child: Wrap(
                              spacing: 12,
                              runSpacing: 12,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                FilledButton(
                                  onPressed: details.onStepContinue,
                                  style: FilledButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                                  ),
                                  child: Text(isLastStep ? l10n.savePropertyAction : l10n.continueAction),
                                ),
                                TextButton(
                                  onPressed: details.onStepCancel,
                                  child: Text(isFirstStep ? l10n.cancelAction : l10n.backAction),
                                ),
                                if (isFirstStep) 
                                  OutlinedButton.icon(
                                    onPressed: () async {
                                      // Express Save Validation
                                      if (isSuperAdmin && selectedCompanyId.isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(l10n.pleaseSelectCompanyError)),
                                        );
                                        return;
                                      }
                                      if (nameController.text.trim().isEmpty) {
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text(l10n.propertyNameRequiredError)),
                                        );
                                        return;
                                      }
                                      
                                      final newProp = Property(
                                        id: isEditing ? existingProperty!.id : '',
                                        companyId: selectedCompanyId,
                                        name: nameController.text.trim(),
                                        address: addressController.text.trim(),
                                        zipCode: zipCodeController.text.trim(),
                                        city: cityController.text.trim(),
                                        state: stateController.text.trim(),
                                        country: countryController.text.trim(),
                                        propertyType: selectedType,
                                        cleaningFee: double.tryParse(cleaningFeeController.text) ?? 0.0,
                                        size: sizeController.text.trim(),
                                        ownerName: ownerNameController.text.trim(),
                                        ownerPhone: ownerPhoneController.text.trim(),
                                        ownerEmail: ownerEmailController.text.trim(),
                                        propertyManagement: propertyMgmtController.text.trim(),
                                        lockBoxPin: lockBoxPinController.text.trim(),
                                        housePin: housePinController.text.trim(),
                                        garagePin: garagePinController.text.trim(),
                                        order: isEditing ? existingProperty!.order : -1,
                                        syncId: syncIdController.text.trim(),
                                        isCohost: isCohost,
                                        cleaningInstructions: cleaningInstructionsController.text.trim(),
                                        instructionPhotos: instructionPhotos,
                                        checklists: checklists,
                                        ownerAccountId: selectedOwnerAccountId,
                                        recurringCadence: existingProperty?.recurringCadence ?? 'none',
                                        bufferHours: existingProperty?.bufferHours ?? 0,
                                        trashDay: existingProperty?.trashDay ?? '',
                                      );

                                      if (isEditing) {
                                        await repo.update(newProp);
                                      } else {
                                        await repo.add(newProp);
                                      }
                                      if (context.mounted) {
                                        Navigator.pop(context);
                                      }
                                    },
                                    icon: const Icon(Icons.flash_on, size: 18),
                                    label: Text(l10n.expressSaveAction),
                                    style: OutlinedButton.styleFrom(
                                      foregroundColor: AppColors.primary,
                                      side: const BorderSide(color: AppColors.primary),
                                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                    ),
                                  ),
                              ],
                            ),
                          );
                        },
                        steps: steps,
                      ),
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

  Property _generateDummyProperty(String? activeCompanyId) {
    final random = Random();
    
    final streets = ['Gulf Dr', 'Pine Ave', 'Marina Dr', 'Palm Ave', 'Spring Ave', 'Magnolia Ave', 'Bay Blvd'];
    final cities = ['Anna Maria', 'Holmes Beach', 'Bradenton Beach'];
    final zips = ['34216', '34217'];
    final types = ['House', 'Apartment', 'Condo', 'Villa'];
    
    final street = streets[random.nextInt(streets.length)];
    final city = cities[random.nextInt(cities.length)];
    final zip = zips[random.nextInt(zips.length)];
    final type = types[random.nextInt(types.length)];
    final houseNumber = random.nextInt(900) + 100;
    
    final cleaningFee = (random.nextInt(15) * 10) + 100.0; // Between 100 and 250
    final size = '${(random.nextInt(15) * 100) + 800} sqft';
    
    return Property(
      id: '',
      companyId: activeCompanyId ?? '',
      name: 'Test $type on $street',
      address: '$houseNumber $street',
      city: city,
      state: 'FL',
      zipCode: zip,
      country: 'USA',
      cleaningFee: cleaningFee,
      size: size,
      propertyType: type,
      ownerName: 'Test Owner',
      ownerPhone: '555-${random.nextInt(900) + 100}-${random.nextInt(9000) + 1000}',
      ownerEmail: 'owner${random.nextInt(100)}@example.com',
      propertyManagement: 'Anna Maria Mgmt',
      lockBoxPin: '${random.nextInt(9000) + 1000}',
      housePin: '${random.nextInt(9000) + 1000}',
      garagePin: '${random.nextInt(9000) + 1000}',
      syncId: 'TEST-SYNC-${random.nextInt(1000)}',
      cleaningInstructions: 'Please ensure all sand is swept out and linens are washed.',
      instructionPhotos: [],
    );
  }

  void _showLimitDialog(BuildContext context, int limit, AppLocalizations l10n) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(l10n.subscriptionLimitReachedTitle),
        content: Text(l10n.subscriptionLimitReachedDesc(limit)),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(l10n.cancelAction),
          ),
          FilledButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/admin/subscription');
            },
            child: Text(l10n.upgradePlanAction),
          ),
        ],
      ),
    );
  }
}

// ── Property Card ──────────────────────────────────────────────────────────
class _PropertyCard extends StatelessWidget {
  final Property property;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final String currencySymbol;

  const _PropertyCard({required this.property, required this.index, required this.onEdit, required this.onDelete, this.currencySymbol = '\$'});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header row
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text('#$index', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    property.name,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tealLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    property.propertyType.isEmpty 
                        ? l10n.typeHouse 
                        : (property.propertyType == 'Apartment' ? l10n.typeApartment : (property.propertyType == 'Other' ? l10n.typeOther : l10n.typeHouse)),
                    style: const TextStyle(color: AppColors.teal, fontSize: 11, fontWeight: FontWeight.w600),
                  ),
                ),
                IconButton(icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textSecondary), onPressed: onEdit),
                IconButton(icon: const Icon(Icons.delete_outline, size: 18, color: AppColors.error), onPressed: onDelete),
              ],
            ),
            const SizedBox(height: 8),
            // Address
            Row(children: [
              const Icon(Icons.location_on_outlined, size: 14, color: AppColors.textSecondary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  '${property.address}, ${property.city}, ${property.state} ${property.zipCode}',
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ]),
            const SizedBox(height: 6),
            // Fee + size
            Wrap(
              spacing: 16,
              children: [
                _InfoChip(icon: Icons.payments_outlined, label: '$currencySymbol${property.cleaningFee.toStringAsFixed(0)} ${AppLocalizations.of(context)!.cleaningFeeSuffix}', color: AppColors.green),
                if (property.size.isNotEmpty)
                  _InfoChip(icon: Icons.square_foot_rounded, label: property.size, color: AppColors.teal),
                if (property.propertyManagement.isNotEmpty)
                  _InfoChip(icon: Icons.business_outlined, label: property.propertyManagement, color: AppColors.primary),
              ],
            ),
            if (property.ownerName.isNotEmpty || property.lockBoxPin.isNotEmpty) ...[
              const Divider(height: 16),
              Wrap(
                spacing: 16,
                runSpacing: 4,
                children: [
                  if (property.ownerName.isNotEmpty)
                    _InfoChip(icon: Icons.person_outline, label: property.ownerName, color: AppColors.textSecondary),
                  if (property.ownerPhone.isNotEmpty)
                    _InfoChip(icon: Icons.phone_outlined, label: property.ownerPhone, color: AppColors.textSecondary),
                  if (property.lockBoxPin.isNotEmpty)
                    _InfoChip(icon: Icons.lock_outline, label: '${AppLocalizations.of(context)!.lockPrefix} ${property.lockBoxPin}', color: AppColors.amber),
                  if (property.housePin.isNotEmpty)
                    _InfoChip(icon: Icons.home_outlined, label: '${AppLocalizations.of(context)!.housePrefix} ${property.housePin}', color: AppColors.amber),
                  if (property.garagePin.isNotEmpty)
                    _InfoChip(icon: Icons.garage_outlined, label: '${AppLocalizations.of(context)!.garagePrefix} ${property.garagePin}', color: AppColors.amber),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _InfoChip({required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 4),
        Text(label, style: TextStyle(fontSize: 12, color: color, fontWeight: FontWeight.w500)),
      ],
    );
  }
}

// ── Filter Chip for Properties ───────────────────────────────────────────────
class _PropFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final ValueChanged<bool> onSelected;
  const _PropFilterChip({required this.label, required this.selected, required this.onSelected});

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
