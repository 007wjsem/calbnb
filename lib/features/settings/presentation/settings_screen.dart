import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../data/settings_repository.dart';
import '../../admin/data/property_repository.dart';
import '../../admin/domain/property.dart';

final settingsRepositoryProvider = Provider((ref) => SettingsRepository());
final propertyRepositoryProvider = Provider((ref) => PropertyRepository());

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});

  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _isLoading = true;
  List<Property> _properties = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final propRepo = ref.read(propertyRepositoryProvider);
      final setRepo = ref.read(settingsRepositoryProvider);

      final allProps = await propRepo.fetchAll();
      final orderIds = await setRepo.fetchPropertyOrder();

      // Sort properties based on the saved ID order
      // Properties not in the order list will go to the end
      if (orderIds.isNotEmpty) {
        allProps.sort((a, b) {
          final indexA = orderIds.indexOf(a.id);
          final indexB = orderIds.indexOf(b.id);
          if (indexA == -1 && indexB == -1) return 0;
          if (indexA == -1) return 1;
          if (indexB == -1) return -1;
          return indexA.compareTo(indexB);
        });
      }

      if (mounted) {
        setState(() {
          _properties = allProps;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
  }

  Future<void> _saveSettings() async {
    setState(() => _isLoading = true);
    final repo = ref.read(settingsRepositoryProvider);
    final propRepo = ref.read(propertyRepositoryProvider);
    try {
      final orderIds = _properties.map((p) => p.id).toList();
      print('DEBUG: Attempting to save property order to Firebase: $orderIds');
      
      await Future.wait([
        repo.savePropertyOrder(orderIds),
        propRepo.updateOrderBatch(orderIds),
      ]);
      
      print('DEBUG: Save successful.');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Property order saved successfully.')),
        );
      }
    } catch (e, stack) {
      print('DEBUG ERROR saving property order: $e');
      print('DEBUG STACK: $stack');
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error saving property order: $e')),
        );
      }
    }
  }

  void _onReorder(int oldIndex, int newIndex) {
    setState(() {
      if (oldIndex < newIndex) {
        newIndex -= 1;
      }
      final Property item = _properties.removeAt(oldIndex);
      _properties.insert(newIndex, item);
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('System Settings'),
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
            const Text(
              'Property Display Order',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Drag and drop the properties below to rearrange how they appear in the system. Click "Save Order" when finished.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ReorderableListView.builder(
                itemCount: _properties.length,
                onReorder: _onReorder,
                itemBuilder: (context, index) {
                  final property = _properties[index];
                  return Card(
                    key: ValueKey(property.id),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      leading: const Icon(Icons.drag_handle, color: Colors.grey),
                      title: Text(property.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text('${property.address}, ${property.city} - ${property.propertyType}'),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _saveSettings,
        backgroundColor: const Color(0xFF1E3A8A),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.save),
        label: const Text('Save Order'),
      ),
    );
  }
}
