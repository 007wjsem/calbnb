enum PropertyType { house, apartment, condo, villa, cabin }

class Property {
  final String id;
  final String name;
  final String address;
  final String city;
  final String state;
  final String zipCode;
  final String country;
  final double cleaningFee;
  final double size; // in square meters
  final PropertyType type;
  final String cleaningInstructions;
  final List<String> instructionPhotos;

  const Property({
    required this.id,
    required this.name,
    required this.address,
    required this.city,
    required this.state,
    required this.zipCode,
    required this.country,
    required this.cleaningFee,
    required this.size,
    required this.type,
    this.cleaningInstructions = '',
    this.instructionPhotos = const [],
  });

  // Convert to a map for Firebase Realtime Database
  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'address': address,
        'city': city,
        'state': state,
        'zipCode': zipCode,
        'country': country,
        'cleaningFee': cleaningFee,
        'size': size,
        'type': type.name,
        'cleaningInstructions': cleaningInstructions,
        'instructionPhotos': instructionPhotos,
      };

  // Create a Property from a Firebase map
  factory Property.fromJson(Map<String, dynamic> json) => Property(
        id: json['id'] as String,
        name: json['name'] as String,
        address: json['address'] as String,
        city: json['city'] as String,
        state: json['state'] as String,
        zipCode: json['zipCode'] as String,
        country: json['country'] as String,
        cleaningFee: (json['cleaningFee'] as num).toDouble(),
        size: (json['size'] as num).toDouble(),
        type: PropertyType.values.firstWhere((e) => e.name == json['type']),
        cleaningInstructions: json['cleaningInstructions'] as String? ?? '',
        instructionPhotos: (json['instructionPhotos'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [],
      );
}
