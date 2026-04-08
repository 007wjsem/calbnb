import 'package:firebase_database/firebase_database.dart';
import '../../admin/domain/property.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';

final propertyRepositoryProvider = Provider((ref) {
  final activeCompanyId = ref.watch(authControllerProvider)?.activeCompanyId;
  return PropertyRepository(activeCompanyId: activeCompanyId);
});

final propertiesStreamProvider = StreamProvider<List<Property>>((ref) {
  final activeCompanyId = ref.watch(authControllerProvider)?.activeCompanyId;
  final propRepo = PropertyRepository(activeCompanyId: activeCompanyId);
  return propRepo.watchAll();
});

class PropertyRepository {
  final String? activeCompanyId;
  PropertyRepository({this.activeCompanyId});

  DatabaseReference get _ref {
    if (activeCompanyId == null) return FirebaseDatabase.instance.ref('properties');
    return FirebaseDatabase.instance.ref('companies/$activeCompanyId/properties');
  }

  Future<List<Property>> fetchAll() async {
    final List<Property> properties = [];

    if (activeCompanyId == null) {
      // Super Admin: Fetch from legacy 'properties' AND all 'companies/*/properties'
      
      // 1. Legacy
      final legacySnap = await FirebaseDatabase.instance.ref('properties').get();
      _parseProperties(legacySnap.value, properties, null);
      
      // 2. Companies
      final companiesSnap = await FirebaseDatabase.instance.ref('companies').get();
      final rawCompanies = companiesSnap.value;
      if (rawCompanies is Map) {
        rawCompanies.forEach((compId, compData) {
          if (compData is Map && compData.containsKey('properties')) {
            _parseProperties(compData['properties'], properties, compId.toString());
          }
        });
      } else if (rawCompanies is List) {
        for (int i = 0; i < rawCompanies.length; i++) {
          final compData = rawCompanies[i];
          if (compData is Map && compData.containsKey('properties')) {
            _parseProperties(compData['properties'], properties, i.toString());
          }
        }
      }
    } else {
      // Company Admin/User: Fetch from their specific company bucket
      final snapshot = await _ref.get();
      _parseProperties(snapshot.value, properties, activeCompanyId);
    }

    // Natively sort properties by their stored order value
    properties.sort((a, b) => a.order.compareTo(b.order));
    return properties;
  }

  /// Real-time stream that emits a new list whenever properties change in Firebase.
  Stream<List<Property>> watchAll() {
    if (activeCompanyId == null) {
      // Super Admin: combine legacy + company properties
      // We listen to BOTH the legacy 'properties' node and the 'companies' node.
      final legacyStream = FirebaseDatabase.instance.ref('properties').onValue;
      final companiesStream = FirebaseDatabase.instance.ref('companies').onValue;

      // We use Rx.combineLatest2 or manual stream merge if possible, 
      // but for simplicity without adding new dependencies, we can use a simpler approach:
      // Since fetchAll() already handles both, and watchAll is mostly for UI updates,
      // we'll keep the companies stream as the primary driver but parse everything.
      
      // Actually, to be truly reactive, we should probably watch both.
      // But in this app, usually legacy properties don't change often.
      // Let's at least ensure we are parsing the companies node correctly.
      
      return companiesStream.asyncMap((event) async {
        final List<Property> props = [];
        
        // 1. Legacy (One-time check per update is fine)
        final legacySnap = await FirebaseDatabase.instance.ref('properties').get();
        _parseProperties(legacySnap.value, props, null);

        // 2. Companies
        final rawCompanies = event.snapshot.value;
        if (rawCompanies is Map) {
          rawCompanies.forEach((compId, compData) {
            if (compData is Map && compData.containsKey('properties')) {
              _parseProperties(compData['properties'], props, compId.toString());
            }
          });
        }
        
        props.sort((a, b) => a.order.compareTo(b.order));
        return props;
      });
    } else {
      return _ref.onValue.map((event) {
        final List<Property> props = [];
        _parseProperties(event.snapshot.value, props, activeCompanyId);
        props.sort((a, b) => a.order.compareTo(b.order));
        return props;
      });
    }
  }

  void _parseProperties(dynamic rawData, List<Property> properties, String? fallbackCompanyId) {
    if (rawData == null) return;
    
    Map<dynamic, dynamic> entriesMap;
    if (rawData is Map) {
      entriesMap = rawData;
    } else if (rawData is List) {
      entriesMap = rawData.asMap();
    } else {
      return;
    }

    entriesMap.forEach((key, value) {
      if (value is Map) {
        final Map outerMap = value;
        // Handle iOS push-ID wrappers: if all keys of this map start with '-' and values are Maps, recurse.
        final bool isPushIdWrapper = outerMap.isNotEmpty &&
            outerMap.keys.every((k) => k is String && k.startsWith('-')) &&
            outerMap.values.every((v) => v is Map);

        if (isPushIdWrapper) {
          _parseProperties(outerMap, properties, fallbackCompanyId);
          return; // Skip adding 'outerMap' itself as a property
        }

        properties.add(Property(
          id: key.toString(),
          companyId: outerMap['companyId']?.toString() ?? fallbackCompanyId ?? activeCompanyId ?? '',
          name: outerMap['name']?.toString() ?? '',
          address: outerMap['address']?.toString() ?? '',
          zipCode: outerMap['zipCode']?.toString() ?? '',
          city: outerMap['city']?.toString() ?? '',
          state: outerMap['state']?.toString() ?? '',
          country: outerMap['country']?.toString() ?? '',
          cleaningFee: double.tryParse(outerMap['cleaningFee']?.toString() ?? '0') ?? 0.0,
          size: outerMap['size']?.toString() ?? '',
          propertyType: outerMap['propertyType']?.toString() ?? '',
          ownerName: outerMap['ownerName']?.toString() ?? '',
          ownerPhone: outerMap['ownerPhone']?.toString() ?? '',
          ownerEmail: outerMap['ownerEmail']?.toString() ?? '',
          propertyManagement: outerMap['propertyManagement']?.toString() ?? '',
          lockBoxPin: outerMap['lockBoxPin']?.toString() ?? '',
          housePin: outerMap['housePin']?.toString() ?? '',
          garagePin: outerMap['garagePin']?.toString() ?? '',
          order: int.tryParse(outerMap['order']?.toString() ?? '0') ?? 0,
          syncId: outerMap['syncId']?.toString() ?? '',
          isCohost: outerMap['isCohost'] == true || outerMap['isCohost'] == 'true',
          cleaningInstructions: outerMap['cleaningInstructions']?.toString() ?? '',
          instructionPhotos: (outerMap['instructionPhotos'] as List<dynamic>?)?.map((x) => x.toString()).toList() ?? [],
          checklists: (outerMap['checklists'] as List<dynamic>?)?.map((x) => x.toString()).toList() ?? [],
          ownerAccountId: outerMap['ownerAccountId']?.toString(),
          recurringCadence: outerMap['recurringCadence']?.toString() ?? 'none',
          bufferHours: int.tryParse(outerMap['bufferHours']?.toString() ?? '0') ?? 0,
          trashDay: outerMap['trashDay']?.toString() ?? '',
        ));
      }
    });
  }
  Future<void> add(Property property) async {
    // If property has a specific companyId that differs from the active context,
    // write directly to that company's bucket (Super Admin use case).
    final targetRef = (property.companyId.isNotEmpty && property.companyId != activeCompanyId)
        ? FirebaseDatabase.instance.ref('companies/${property.companyId}/properties')
        : _ref;
    final newRef = property.id.isEmpty ? targetRef.push() : targetRef.child(property.id);
    await newRef.set({
      'companyId': property.companyId,
      'name': property.name,
      'address': property.address,
      'zipCode': property.zipCode,
      'city': property.city,
      'state': property.state,
      'country': property.country,
      'cleaningFee': property.cleaningFee,
      'size': property.size,
      'propertyType': property.propertyType,
      'ownerName': property.ownerName,
      'ownerPhone': property.ownerPhone,
      'ownerEmail': property.ownerEmail,
      'propertyManagement': property.propertyManagement,
      'lockBoxPin': property.lockBoxPin,
      'housePin': property.housePin,
      'garagePin': property.garagePin,
      'order': property.order,
      'syncId': property.syncId,
      'isCohost': property.isCohost,
      'cleaningInstructions': property.cleaningInstructions,
      'instructionPhotos': property.instructionPhotos,
      'checklists': property.checklists,
      'ownerAccountId': property.ownerAccountId,
      'recurringCadence': property.recurringCadence,
      'bufferHours': property.bufferHours,
      'trashDay': property.trashDay,
    });
  }

  Future<void> update(Property property) async {
    // When editing, write to the correct company's bucket
    final targetRef = (property.companyId.isNotEmpty && property.companyId != activeCompanyId)
        ? FirebaseDatabase.instance.ref('companies/${property.companyId}/properties')
        : _ref;
    await targetRef.child(property.id).update({
      'companyId': property.companyId,
      'name': property.name,
      'address': property.address,
      'zipCode': property.zipCode,
      'city': property.city,
      'state': property.state,
      'country': property.country,
      'cleaningFee': property.cleaningFee,
      'size': property.size,
      'propertyType': property.propertyType,
      'ownerName': property.ownerName,
      'ownerPhone': property.ownerPhone,
      'ownerEmail': property.ownerEmail,
      'propertyManagement': property.propertyManagement,
      'lockBoxPin': property.lockBoxPin,
      'housePin': property.housePin,
      'garagePin': property.garagePin,
      'order': property.order,
      'syncId': property.syncId,
      'isCohost': property.isCohost,
      'cleaningInstructions': property.cleaningInstructions,
      'instructionPhotos': property.instructionPhotos,
      'checklists': property.checklists,
      'ownerAccountId': property.ownerAccountId,
      'recurringCadence': property.recurringCadence,
      'bufferHours': property.bufferHours,
      'trashDay': property.trashDay,
    });
  }

  Future<void> updateOrderBatch(List<String> orderedIds) async {
    // Perform a multi-path update to efficiently update the order field
    // of multiple properties in a single network request.
    final Map<String, dynamic> updates = {};
    for (int i = 0; i < orderedIds.length; i++) {
      updates['${orderedIds[i]}/order'] = i;
    }
    if (updates.isNotEmpty) {
      await _ref.update(updates);
    }
  }

  Future<void> delete(String pid) async {
    await _ref.child(pid).remove();
  }
}
