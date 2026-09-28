class OwnerModel {
  final int? id;
  final String fullName;
  final String phonePrimary;
  final String? phoneSecondary;
  final String? address;
  final String? notes;
  final String? createdAt;

  OwnerModel({
    this.id,
    required this.fullName,
    required this.phonePrimary,
    this.phoneSecondary,
    this.address,
    this.notes,
    this.createdAt,
  });

  factory OwnerModel.fromMap(Map<String, dynamic> map) {
    return OwnerModel(
      id: map['id'] as int?,
      fullName: map['full_name'] as String? ?? '',
      phonePrimary: map['phone_primary'] as String? ?? '',
      phoneSecondary: map['phone_secondary'] as String?,
      address: map['address'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'full_name': fullName,
      'phone_primary': phonePrimary,
      'phone_secondary': phoneSecondary,
      'address': address,
      'notes': notes,
    };
  }

  OwnerModel copyWith({
    int? id,
    String? fullName,
    String? phonePrimary,
    String? phoneSecondary,
    String? address,
    String? notes,
    String? createdAt,
  }) {
    return OwnerModel(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      phonePrimary: phonePrimary ?? this.phonePrimary,
      phoneSecondary: phoneSecondary ?? this.phoneSecondary,
      address: address ?? this.address,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
