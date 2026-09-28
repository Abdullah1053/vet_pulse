class UserModel {
  final int? id;
  final String username;
  final String? passwordHash;
  final String fullName;
  final String role; // lead_doctor, assistant_vet, receptionist, pharmacist
  final String? phone;
  final String? pinCode;
  final bool isActive;
  final String? createdAt;

  UserModel({
    this.id,
    required this.username,
    this.passwordHash,
    required this.fullName,
    required this.role,
    this.phone,
    this.pinCode,
    this.isActive = true,
    this.createdAt,
  });

  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as int?,
      username: map['username'] as String? ?? '',
      passwordHash: map['password_hash'] as String?,
      fullName: map['full_name'] as String? ?? '',
      role: map['role'] as String? ?? 'lead_doctor',
      phone: map['phone'] as String?,
      pinCode: map['pin_code'] as String?,
      isActive: (map['is_active'] as int? ?? 1) == 1,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'username': username,
      if (passwordHash != null) 'password_hash': passwordHash,
      'full_name': fullName,
      'role': role,
      'phone': phone,
      'pin_code': pinCode,
      'is_active': isActive ? 1 : 0,
    };
  }

  // Permission helpers based on RBAC matrix in specification
  bool get isLeadDoctor => role == 'lead_doctor';
  bool get isAssistantVet => role == 'assistant_vet';
  bool get isReceptionist => role == 'receptionist';
  bool get isPharmacist => role == 'pharmacist';

  bool get canPerformConsultation => isLeadDoctor || isAssistantVet;
  bool get canPerformSurgeries => isLeadDoctor || isAssistantVet;
  bool get canModifyInventory => isLeadDoctor || isPharmacist;
  bool get canManageUsers => isLeadDoctor;
  bool get canDeleteRecords => isLeadDoctor;

  String get roleDisplayArabic {
    switch (role) {
      case 'lead_doctor':
        return 'طبيب رئيسي';
      case 'assistant_vet':
        return 'طبيب مساعد';
      case 'receptionist':
        return 'موظف استقبال';
      case 'pharmacist':
        return 'أمين المستودع والصيدلية';
      default:
        return role;
    }
  }
}
