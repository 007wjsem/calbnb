class Property {
  final String id;
  final String companyId;
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
  final List<String> checklists;
  final String? ownerAccountId; // Links to a User with AppRole.owner
  final String debugRaw;

  // Silver-tier scheduling fields
  final String recurringCadence;  // 'none', 'weekly', 'biweekly', 'monthly'
  final int bufferHours;          // Buffer hours required between checkout and next checkin
  final String trashDay;          // e.g. 'Monday', 'Wednesday', '' = none

  Property({
    required this.id,
    required this.companyId,
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
    this.checklists = const [],
    this.ownerAccountId,
    this.debugRaw = '',
    this.recurringCadence = 'none',
    this.bufferHours = 0,
    this.trashDay = '',
  });

  Property copyWith({
    String? id,
    String? companyId,
    String? name,
    String? address,
    String? zipCode,
    String? city,
    String? state,
    String? country,
    double? cleaningFee,
    String? size,
    String? propertyType,
    String? ownerName,
    String? ownerPhone,
    String? ownerEmail,
    String? propertyManagement,
    String? lockBoxPin,
    String? housePin,
    String? garagePin,
    int? order,
    String? cleaningInstructions,
    List<String>? instructionPhotos,
    List<String>? checklists,
    String? ownerAccountId,
    String? recurringCadence,
    int? bufferHours,
    String? trashDay,
  }) {
    return Property(
      id: id ?? this.id,
      companyId: companyId ?? this.companyId,
      name: name ?? this.name,
      address: address ?? this.address,
      zipCode: zipCode ?? this.zipCode,
      city: city ?? this.city,
      state: state ?? this.state,
      country: country ?? this.country,
      cleaningFee: cleaningFee ?? this.cleaningFee,
      size: size ?? this.size,
      propertyType: propertyType ?? this.propertyType,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      ownerEmail: ownerEmail ?? this.ownerEmail,
      propertyManagement: propertyManagement ?? this.propertyManagement,
      lockBoxPin: lockBoxPin ?? this.lockBoxPin,
      housePin: housePin ?? this.housePin,
      garagePin: garagePin ?? this.garagePin,
      order: order ?? this.order,
      cleaningInstructions: cleaningInstructions ?? this.cleaningInstructions,
      instructionPhotos: instructionPhotos ?? this.instructionPhotos,
      checklists: checklists ?? this.checklists,
      ownerAccountId: ownerAccountId ?? this.ownerAccountId,
      debugRaw: this.debugRaw,
      recurringCadence: recurringCadence ?? this.recurringCadence,
      bufferHours: bufferHours ?? this.bufferHours,
      trashDay: trashDay ?? this.trashDay,
    );
  }
}
