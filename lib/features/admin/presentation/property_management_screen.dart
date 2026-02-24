import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'dart:convert';
import 'dart:math';
import 'package:image_picker/image_picker.dart';
import '../../admin/data/property_repository.dart';
import '../../admin/domain/property.dart';
import '../../auth/data/auth_repository.dart';
import '../../../core/theme/app_colors.dart';

final propertyRepositoryProvider = Provider((ref) => PropertyRepository());

class PropertyManagementScreen extends ConsumerStatefulWidget {
  const PropertyManagementScreen({super.key});

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

  @override
  void initState() {
    super.initState();
    _loadProperties();
    _searchCtrl.addListener(() => setState(() => _query = _searchCtrl.text.trim().toLowerCase()));
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProperties() async {
    setState(() => _loading = true);
    try {
      final repo = ref.read(propertyRepositoryProvider);
      final props = await repo.fetchAll();
      props.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
      setState(() { _allProperties = props; _loading = false; });
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
    final filtered = _filtered;
    final cities = _cities;
    final mgmts = _mgmts;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Properties'),
        leading: IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.go('/')),
        actions: [
          if (isSuperAdmin)
            IconButton(
              icon: const Icon(Icons.auto_awesome),
              tooltip: 'Generate Dummy Property (Test)',
              onPressed: () async {
                final dummyProp = _generateDummyProperty();
                await repo.add(dummyProp);
                await _loadProperties();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Added ${dummyProp.name}')));
                }
              },
            ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showPropertyDialog(context, ref, repo),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_home_outlined),
        label: const Text('Add Property'),
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
                          TextField(
                            controller: _searchCtrl,
                            decoration: InputDecoration(
                              hintText: 'Search by name, address, owner, or management…',
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
                            const Text('City', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _PropFilterChip(
                                    label: 'All Cities',
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
                            const Text('Property Management', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.5)),
                            const SizedBox(height: 6),
                            SingleChildScrollView(
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                children: [
                                  _PropFilterChip(
                                    label: 'All',
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
                              '${filtered.length} of ${_allProperties.length} properties',
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
                                  const Text('No properties found', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: AppColors.textPrimary)),
                                  const SizedBox(height: 6),
                                  const Text('Try adjusting your search or filters', style: TextStyle(fontSize: 13, color: AppColors.textSecondary)),
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
                                  onEdit: () => _showPropertyDialog(context, ref, repo, existingProperty: property),
                                  onDelete: () async {
                                    final confirm = await showDialog<bool>(
                                      context: context,
                                      builder: (ctx) => AlertDialog(
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                                        title: const Text('Delete Property'),
                                        content: Text('Delete "${property.name}"? This cannot be undone.'),
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
                                      await repo.delete(property.id);
                                      await _loadProperties();
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

  void _showPropertyDialog(BuildContext context, WidgetRef ref, PropertyRepository repo, {Property? existingProperty}) {
    final isEditing = existingProperty != null;
    final nameController = TextEditingController(text: existingProperty?.name ?? '');
    final addressController = TextEditingController(text: existingProperty?.address ?? '');
    final zipCodeController = TextEditingController(text: existingProperty?.zipCode ?? '');
    final cityController = TextEditingController(text: existingProperty?.city ?? '');
    final stateController = TextEditingController(text: existingProperty?.state ?? '');
    final countryController = TextEditingController(text: existingProperty?.country ?? '');
    final cleaningFeeController = TextEditingController(text: existingProperty?.cleaningFee.toString() ?? '');
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
    final ImagePicker picker = ImagePicker();
    
    String selectedType = existingProperty?.propertyType == 'Apartment' || existingProperty?.propertyType == 'Other' 
        ? existingProperty!.propertyType 
        : 'House';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                padding: const EdgeInsets.all(32),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text(
                        isEditing ? 'Edit Property Details' : 'Add New Property',
                        style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Color(0xFF0F172A)),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        isEditing ? 'Modify the property information below.' : 'Fill out the property details below.',
                        style: const TextStyle(color: Colors.grey),
                      ),
                      const SizedBox(height: 24),
                      Row(
                        children: [
                          Expanded(
                            flex: 2,
                            child: TextField(
                              controller: nameController,
                              decoration: const InputDecoration(labelText: 'Property Name', prefixIcon: Icon(Icons.label_outline)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: selectedType,
                              decoration: const InputDecoration(labelText: 'Property Type', prefixIcon: Icon(Icons.category_outlined)),
                              items: ['House', 'Apartment', 'Other'].map((type) {
                                return DropdownMenuItem(value: type, child: Text(type));
                              }).toList(),
                              onChanged: (val) {
                                if (val != null) setState(() => selectedType = val);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: addressController,
                        decoration: const InputDecoration(labelText: 'Street Address', prefixIcon: Icon(Icons.location_on_outlined)),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: cityController,
                              decoration: const InputDecoration(labelText: 'City'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: stateController,
                              decoration: const InputDecoration(labelText: 'State/Province'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                               controller: zipCodeController,
                               decoration: const InputDecoration(labelText: 'Zip/Postal Code'),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                               controller: countryController,
                               decoration: const InputDecoration(labelText: 'Country'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: cleaningFeeController,
                              keyboardType: const TextInputType.numberWithOptions(decimal: true),
                              decoration: const InputDecoration(labelText: 'Cleaning Fee (\$)', prefixIcon: Icon(Icons.attach_money)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: sizeController,
                              decoration: const InputDecoration(labelText: 'Size (e.g. 1500 sqft)', prefixIcon: Icon(Icons.aspect_ratio)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Owner Information', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey.shade700)),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ownerNameController,
                              decoration: const InputDecoration(labelText: 'Owner Name', prefixIcon: Icon(Icons.person_outline)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: ownerPhoneController,
                              keyboardType: TextInputType.phone,
                              decoration: const InputDecoration(labelText: 'Phone Number', prefixIcon: Icon(Icons.phone_outlined)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: ownerEmailController,
                              keyboardType: TextInputType.emailAddress,
                              decoration: const InputDecoration(labelText: 'Email Address', prefixIcon: Icon(Icons.email_outlined)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: propertyMgmtController,
                              decoration: const InputDecoration(labelText: 'Property Management', prefixIcon: Icon(Icons.business_outlined)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Access Pins', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey.shade700)),
                      const Divider(),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: lockBoxPinController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Lock Box Pin', prefixIcon: Icon(Icons.lock_outline)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: housePinController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'House Pin', prefixIcon: Icon(Icons.door_front_door_outlined)),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: TextField(
                              controller: garagePinController,
                              keyboardType: TextInputType.number,
                              decoration: const InputDecoration(labelText: 'Garage Pin', prefixIcon: Icon(Icons.garage_outlined)),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                      Text('Cleaning Instructions', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.blueGrey.shade700)),
                      const Divider(),
                      const SizedBox(height: 8),
                      TextField(
                        controller: cleaningInstructionsController,
                        maxLines: 4,
                        decoration: const InputDecoration(labelText: 'Instructions', alignLabelWithHint: true, prefixIcon: Icon(Icons.cleaning_services_outlined)),
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
                          label: const Text('Add Instruction Photo'),
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
                      const SizedBox(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text('Cancel'),
                          ),
                          const SizedBox(width: 16),
                          ElevatedButton(
                            onPressed: () async {
                              final newProp = Property(
                                id: isEditing ? existingProperty!.id : '',
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
                                order: isEditing ? existingProperty!.order : -1, // order defaults to -1 on add, handled by repository
                                cleaningInstructions: cleaningInstructionsController.text.trim(),
                                instructionPhotos: instructionPhotos,
                              );

                              if (isEditing) {
                                await repo.update(newProp);
                              } else {
                                await repo.add(newProp);
                              }
                              if (context.mounted) {
                                Navigator.pop(context);
                                await _loadProperties();
                              }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF0284C7),
                              foregroundColor: Colors.white,
                            ),
                            child: const Text('Save Property'),
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

  Property _generateDummyProperty() {
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
      cleaningInstructions: 'Please ensure all sand is swept out and linens are washed.',
      instructionPhotos: [],
    );
  }
}

// ── Property Card ──────────────────────────────────────────────────────────
class _PropertyCard extends StatelessWidget {
  final Property property;
  final int index;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const _PropertyCard({required this.property, required this.index, required this.onEdit, required this.onDelete});

  @override
  Widget build(BuildContext context) {
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
                  child: Text(property.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15, color: AppColors.textPrimary)),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.tealLight,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColors.teal.withValues(alpha: 0.3)),
                  ),
                  child: Text(
                    property.propertyType.isEmpty ? 'House' : property.propertyType,
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
                ),
              ),
            ]),
            const SizedBox(height: 6),
            // Fee + size
            Wrap(
              spacing: 16,
              children: [
                _InfoChip(icon: Icons.attach_money_rounded, label: '\$${property.cleaningFee.toStringAsFixed(0)} cleaning fee', color: AppColors.green),
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
                    _InfoChip(icon: Icons.lock_outline, label: 'Lock: ${property.lockBoxPin}', color: AppColors.amber),
                  if (property.housePin.isNotEmpty)
                    _InfoChip(icon: Icons.home_outlined, label: 'House: ${property.housePin}', color: AppColors.amber),
                  if (property.garagePin.isNotEmpty)
                    _InfoChip(icon: Icons.garage_outlined, label: 'Garage: ${property.garagePin}', color: AppColors.amber),
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
