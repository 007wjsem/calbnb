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
    final snapshot = await _ref.get();
    final Map<dynamic, dynamic>? data = snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return [];
    final properties = data.entries.map((e) {
      final value = e.value as Map<dynamic, dynamic>;
      return Property(
        id: e.key.toString(),
        companyId: value['companyId']?.toString() ?? activeCompanyId ?? '',
        name: value['name']?.toString() ?? 'Unknown',
        address: value['address']?.toString() ?? 'Unknown',
        zipCode: value['zipCode']?.toString() ?? '',
        city: value['city']?.toString() ?? '',
        state: value['state']?.toString() ?? '',
        country: value['country']?.toString() ?? '',
        cleaningFee: (value['cleaningFee'] as num?)?.toDouble() ?? 0.0,
        size: value['size']?.toString() ?? '',
        propertyType: value['propertyType']?.toString() ?? '',
        ownerName: value['ownerName']?.toString() ?? '',
        ownerPhone: value['ownerPhone']?.toString() ?? '',
        ownerEmail: value['ownerEmail']?.toString() ?? '',
        propertyManagement: value['propertyManagement']?.toString() ?? '',
        lockBoxPin: value['lockBoxPin']?.toString() ?? '',
        housePin: value['housePin']?.toString() ?? '',
        garagePin: value['garagePin']?.toString() ?? '',
        order: (value['order'] as num?)?.toInt() ?? 0,
        cleaningInstructions: value['cleaningInstructions']?.toString() ?? '',
        instructionPhotos: (value['instructionPhotos'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      );
    }).toList();
    
    // Natively sort properties by their stored order value
    properties.sort((a, b) => a.order.compareTo(b.order));
    return properties;
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
