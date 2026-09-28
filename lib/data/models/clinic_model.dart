class ClinicModel {
  final int? id;
  final String clinicName;
  final String doctorName;
  final String? phone;
  final String? address;
  final String? logoPath;
  final String? licenseNumber;
  final String? createdAt;

  ClinicModel({
    this.id,
    required this.clinicName,
    required this.doctorName,
    this.phone,
    this.address,
    this.logoPath,
    this.licenseNumber,
    this.createdAt,
  });

  factory ClinicModel.fromMap(Map<String, dynamic> map) {
    return ClinicModel(
      id: map['id'] as int?,
      clinicName: map['clinic_name'] as String? ?? '',
      doctorName: map['doctor_name'] as String? ?? '',
      phone: map['phone'] as String?,
      address: map['address'] as String?,
      logoPath: map['logo_path'] as String?,
      licenseNumber: map['license_number'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'clinic_name': clinicName,
      'doctor_name': doctorName,
      'phone': phone,
      'address': address,
      'logo_path': logoPath,
      'license_number': licenseNumber,
    };
  }

  ClinicModel copyWith({
    int? id,
    String? clinicName,
    String? doctorName,
    String? phone,
    String? address,
    String? logoPath,
    String? licenseNumber,
    String? createdAt,
  }) {
    return ClinicModel(
      id: id ?? this.id,
      clinicName: clinicName ?? this.clinicName,
      doctorName: doctorName ?? this.doctorName,
      phone: phone ?? this.phone,
      address: address ?? this.address,
      logoPath: logoPath ?? this.logoPath,
      licenseNumber: licenseNumber ?? this.licenseNumber,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
