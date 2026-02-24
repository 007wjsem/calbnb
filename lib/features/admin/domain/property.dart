class Property {
  final String id;
  final String name;
  final String address;
  final String zipCode;
  final String city;
  final String state;
  final String country;
  final double cleaningFee;
  final String size;
  final String propertyType;
  final String ownerName;
  final String ownerPhone;
  final String ownerEmail;
  final String propertyManagement;
  final String lockBoxPin;
  final String housePin;
  final String garagePin;
  final int order; // New field to store sorting position
  final String cleaningInstructions;
  final List<String> instructionPhotos; // Base64 encoded

  Property({
    required this.id,
    required this.name,
    required this.address,
    required this.zipCode,
    required this.city,
    required this.state,
    required this.country,
    required this.cleaningFee,
    required this.size,
    required this.propertyType,
    required this.ownerName,
    required this.ownerPhone,
    required this.ownerEmail,
    required this.propertyManagement,
    required this.lockBoxPin,
    required this.housePin,
    required this.garagePin,
    this.order = 0, // Default to 0
    this.cleaningInstructions = '',
    this.instructionPhotos = const [],
  });
}
