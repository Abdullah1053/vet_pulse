class PetModel {
  final int? id;
  final int ownerId;
  final String name;
  final String species; // Cat, Dog, Bird, Horse, etc.
  final String? breed;
  final String? gender; // male, female
  final bool isNeutered;
  final String? dateOfBirth;
  final String? microchipNumber;
  final String? photoPath;
  final String? allergies;
  final String? createdAt;

  // Joined fields for display
  final String? ownerName;
  final String? ownerPhone;
  final double? latestWeight;

  PetModel({
    this.id,
    required this.ownerId,
    required this.name,
    required this.species,
    this.breed,
    this.gender,
    this.isNeutered = false,
    this.dateOfBirth,
    this.microchipNumber,
    this.photoPath,
    this.allergies,
    this.createdAt,
    this.ownerName,
    this.ownerPhone,
    this.latestWeight,
  });

  factory PetModel.fromMap(Map<String, dynamic> map) {
    return PetModel(
      id: map['id'] as int?,
      ownerId: map['owner_id'] as int? ?? 0,
      name: map['name'] as String? ?? '',
      species: map['species'] as String? ?? 'قط',
      breed: map['breed'] as String?,
      gender: map['gender'] as String?,
      isNeutered: (map['is_neutered'] as int? ?? 0) == 1,
      dateOfBirth: map['date_of_birth'] as String?,
      microchipNumber: map['microchip_number'] as String?,
      photoPath: map['photo_path'] as String?,
      allergies: map['allergies'] as String?,
      createdAt: map['created_at'] as String?,
      ownerName: map['owner_name'] as String?,
      ownerPhone: map['owner_phone'] as String?,
      latestWeight: (map['latest_weight'] != null)
          ? (map['latest_weight'] as num).toDouble()
          : null,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'owner_id': ownerId,
      'name': name,
      'species': species,
      'breed': breed,
      'gender': gender,
      'is_neutered': isNeutered ? 1 : 0,
      'date_of_birth': dateOfBirth,
      'microchip_number': microchipNumber,
      'photo_path': photoPath,
      'allergies': allergies,
    };
  }

  bool get hasAllergies => allergies != null && allergies!.trim().isNotEmpty;

  String get genderDisplayArabic {
    if (gender == 'male') return 'ذكر';
    if (gender == 'female') return 'أنثى';
    return gender ?? 'غير محدد';
  }

  PetModel copyWith({
    int? id,
    int? ownerId,
    String? name,
    String? species,
    String? breed,
    String? gender,
    bool? isNeutered,
    String? dateOfBirth,
    String? microchipNumber,
    String? photoPath,
    String? allergies,
    String? createdAt,
    String? ownerName,
    String? ownerPhone,
    double? latestWeight,
  }) {
    return PetModel(
      id: id ?? this.id,
      ownerId: ownerId ?? this.ownerId,
      name: name ?? this.name,
      species: species ?? this.species,
      breed: breed ?? this.breed,
      gender: gender ?? this.gender,
      isNeutered: isNeutered ?? this.isNeutered,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      microchipNumber: microchipNumber ?? this.microchipNumber,
      photoPath: photoPath ?? this.photoPath,
      allergies: allergies ?? this.allergies,
      createdAt: createdAt ?? this.createdAt,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
      latestWeight: latestWeight ?? this.latestWeight,
    );
  }
}
