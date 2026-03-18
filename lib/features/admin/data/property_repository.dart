import 'package:firebase_database/firebase_database.dart';
import '../../admin/domain/property.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../auth/data/auth_repository.dart';

final propertyRepositoryProvider = Provider((ref) {
  final activeCompanyId = ref.watch(authControllerProvider)?.activeCompanyId;
  return PropertyRepository(activeCompanyId: activeCompanyId);
});

class PropertyRepository {
  final String? activeCompanyId;
  PropertyRepository({this.activeCompanyId});

  DatabaseReference get _ref {
    if (activeCompanyId == null) return FirebaseDatabase.instance.ref('properties');
    return FirebaseDatabase.instance.ref('companies/$activeCompanyId/properties');
  }

  Future<List<Property>> fetchAll() async {
    List<Property> properties = [];

    // Aggressive parsing logic that extracts nested maps even from Lists
    void parseProperties(dynamic rawData, String? fallbackCompanyId) {
      if (rawData == null) return;
      Iterable<MapEntry<dynamic, dynamic>> entries;
      if (rawData is Map) {
        entries = rawData.entries;
      } else if (rawData is List) {
        entries = rawData.asMap().entries;
      } else {
        return;
      }
      
      for (final e in entries) {
        // If it's a map, parse it.
        if (e.value is Map) {
          Map value = e.value as Map;
          String propId = e.key.toString();

          // On iOS, Firebase can return { pushId: { propertyData } } instead of { propertyData }.
          // Detect this by checking if the first key starts with '-' (Firebase push ID format).
          if (value.isNotEmpty &&
              value.keys.first is String &&
              (value.keys.first as String).startsWith('-') &&
              value.values.first is Map) {
            propId = value.keys.first.toString();
            value = value.values.first as Map;
          }

          properties.add(Property(
            id: propId,
            companyId: value['companyId']?.toString() ?? fallbackCompanyId ?? activeCompanyId ?? '',
            name: value['name']?.toString() ?? 'Unknown',
            address: value['address']?.toString() ?? 'Unknown',
            zipCode: value['zipCode']?.toString() ?? '',
            city: value['city']?.toString() ?? '',
            state: value['state']?.toString() ?? '',
            country: value['country']?.toString() ?? '',
            cleaningFee: double.tryParse(value['cleaningFee']?.toString() ?? '0') ?? 0.0,
            size: value['size']?.toString() ?? '',
            propertyType: value['propertyType']?.toString() ?? '',
            ownerName: value['ownerName']?.toString() ?? '',
            ownerPhone: value['ownerPhone']?.toString() ?? '',
            ownerEmail: value['ownerEmail']?.toString() ?? '',
            propertyManagement: value['propertyManagement']?.toString() ?? '',
            lockBoxPin: value['lockBoxPin']?.toString() ?? '',
            housePin: value['housePin']?.toString() ?? '',
            garagePin: value['garagePin']?.toString() ?? '',
            order: int.tryParse(value['order']?.toString() ?? '0') ?? 0,
            cleaningInstructions: value['cleaningInstructions']?.toString() ?? '',
            instructionPhotos: (value['instructionPhotos'] as List<dynamic>?)?.map((x) => x.toString()).toList() ?? [],
            checklists: (value['checklists'] as List<dynamic>?)?.map((x) => x.toString()).toList() ?? [],
            ownerAccountId: value['ownerAccountId']?.toString(),
            recurringCadence: value['recurringCadence']?.toString() ?? 'none',
            bufferHours: int.tryParse(value['bufferHours']?.toString() ?? '0') ?? 0,
            trashDay: value['trashDay']?.toString() ?? '',
          ));
        } else if (e.value is List) {
           // Safely ignore arrays at the property level as they are malformed
        }
      }
    }

    if (activeCompanyId == null) {
      // Super Admin: Fetch from legacy 'properties' AND all 'companies/*/properties'
      
      // 1. Legacy
      final legacySnap = await FirebaseDatabase.instance.ref('properties').get();
      parseProperties(legacySnap.value, null);
      
      // 2. Companies
      final companiesSnap = await FirebaseDatabase.instance.ref('companies').get();
      if (companiesSnap.value is Map) {
        final companiesData = companiesSnap.value as Map;
        companiesData.forEach((compId, compData) {
          if (compData is Map && compData.containsKey('properties')) {
            parseProperties(compData['properties'], compId.toString());
          }
        });
      }
    } else {
      // Company Admin/User: Fetch only from their specific company bucket
      final snapshot = await _ref.get();
      parseProperties(snapshot.value, activeCompanyId);
    }

    // Natively sort properties by their stored order value
    properties.sort((a, b) => a.order.compareTo(b.order));
    return properties;
  }

  /// Real-time stream that emits a new list whenever properties change in Firebase.
  Stream<List<Property>> watchAll() {
    if (activeCompanyId == null) {
      // Super Admin: combine legacy + company properties
      // We listen to the entire companies node for simplicity.
      return FirebaseDatabase.instance.ref('companies').onValue.map((event) {
        final List<Property> props = [];
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

  /// Shared parsing helper used by both fetchAll() and watchAll().
  void _parseProperties(dynamic rawData, List<Property> properties, String? fallbackCompanyId) {
    if (rawData == null) return;
    Iterable<MapEntry<dynamic, dynamic>> entries;
    if (rawData is Map) {
      entries = rawData.entries;
    } else if (rawData is List) {
      entries = rawData.asMap().entries;
    } else {
      return;
    }

    for (final e in entries) {
      if (e.value is Map) {
        final Map outerMap = e.value as Map;

        // On iOS, Firebase can return a map whose keys are all Firebase push-IDs
        // (starting with '-') instead of property field names.
        // In that case, each push-ID key maps to the real property data.
        // We recursively handle this by treating the outer map as another level
        // of entries, extracting ALL push-ID keyed children — not just the first.
        final bool isPushIdWrapper = outerMap.isNotEmpty &&
            outerMap.keys.every((k) => k is String && (k as String).startsWith('-')) &&
            outerMap.values.every((v) => v is Map);

        if (isPushIdWrapper) {
          // Recurse with the outer map directly — will process each push-ID entry
          _parseProperties(outerMap, properties, fallbackCompanyId);
          continue;
        }

        properties.add(Property(
          id: e.key.toString(),
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
          cleaningInstructions: outerMap['cleaningInstructions']?.toString() ?? '',
          instructionPhotos: (outerMap['instructionPhotos'] as List<dynamic>?)?.map((x) => x.toString()).toList() ?? [],
          checklists: (outerMap['checklists'] as List<dynamic>?)?.map((x) => x.toString()).toList() ?? [],
          ownerAccountId: outerMap['ownerAccountId']?.toString(),
          recurringCadence: outerMap['recurringCadence']?.toString() ?? 'none',
          bufferHours: int.tryParse(outerMap['bufferHours']?.toString() ?? '0') ?? 0,
          trashDay: outerMap['trashDay']?.toString() ?? '',
        ));
      }
    }
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
