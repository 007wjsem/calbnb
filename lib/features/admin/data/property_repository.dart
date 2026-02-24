import 'package:firebase_database/firebase_database.dart';
import '../../admin/domain/property.dart';

class PropertyRepository {
  final DatabaseReference _ref = FirebaseDatabase.instance.ref('properties');

  Future<List<Property>> fetchAll() async {
    final snapshot = await _ref.get();
    final Map<dynamic, dynamic>? data = snapshot.value as Map<dynamic, dynamic>?;
    if (data == null) return [];
    final properties = data.entries.map((e) {
      final value = e.value as Map<dynamic, dynamic>;
      return Property(
        id: e.key.toString(),
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
    final newRef = property.id.isEmpty ? _ref.push() : _ref.child(property.id);
    await newRef.set({
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
    await _ref.child(property.id).update({
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
