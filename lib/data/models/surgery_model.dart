class SurgeryModel {
  final int? id;
  final int petId;
  final int leadSurgeonId;
  final String scheduledDate;
  final String surgeryName;
  final String? surgeryCategory;
  final String status; // scheduled, in_progress, completed, cancelled
  final bool preOpChecklistPassed;
  final String? anesthesiaProtocol;
  final String? postOpNotes;
  final double? estimatedCost;

  // Joined fields
  final String? petName;
  final String? petSpecies;
  final String? surgeonName;
  final String? ownerName;
  final String? ownerPhone;

  SurgeryModel({
    this.id,
    required this.petId,
    required this.leadSurgeonId,
    required this.scheduledDate,
    required this.surgeryName,
    this.surgeryCategory,
    this.status = 'scheduled',
    this.preOpChecklistPassed = false,
    this.anesthesiaProtocol,
    this.postOpNotes,
    this.estimatedCost,
    this.petName,
    this.petSpecies,
    this.surgeonName,
    this.ownerName,
    this.ownerPhone,
  });

  factory SurgeryModel.fromMap(Map<String, dynamic> map) {
    return SurgeryModel(
      id: map['id'] as int?,
      petId: map['pet_id'] as int? ?? 0,
      leadSurgeonId: map['lead_surgeon_id'] as int? ?? 0,
      scheduledDate: map['scheduled_date'] as String? ?? '',
      surgeryName: map['surgery_name'] as String? ?? '',
      surgeryCategory: map['surgery_category'] as String?,
      status: map['status'] as String? ?? 'scheduled',
      preOpChecklistPassed: (map['pre_op_checklist_passed'] as int? ?? 0) == 1,
      anesthesiaProtocol: map['anesthesia_protocol'] as String?,
      postOpNotes: map['post_op_notes'] as String?,
      estimatedCost: (map['estimated_cost'] as num?)?.toDouble(),
      petName: map['pet_name'] as String?,
      petSpecies: map['pet_species'] as String?,
      surgeonName: map['surgeon_name'] as String?,
      ownerName: map['owner_name'] as String?,
      ownerPhone: map['owner_phone'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'pet_id': petId,
      'lead_surgeon_id': leadSurgeonId,
      'scheduled_date': scheduledDate,
      'surgery_name': surgeryName,
      'surgery_category': surgeryCategory,
      'status': status,
      'pre_op_checklist_passed': preOpChecklistPassed ? 1 : 0,
      'anesthesia_protocol': anesthesiaProtocol,
      'post_op_notes': postOpNotes,
      'estimated_cost': estimatedCost,
    };
  }

  String get statusDisplayArabic {
    switch (status) {
      case 'scheduled':
        return 'مجدولة';
      case 'in_progress':
        return 'جارية الآن';
      case 'completed':
        return 'مكتملة بنجاح';
      case 'cancelled':
        return 'ملغية';
      default:
        return status;
    }
  }

  SurgeryModel copyWith({
    int? id,
    int? petId,
    int? leadSurgeonId,
    String? scheduledDate,
    String? surgeryName,
    String? surgeryCategory,
    String? status,
    bool? preOpChecklistPassed,
    String? anesthesiaProtocol,
    String? postOpNotes,
    double? estimatedCost,
    String? petName,
    String? petSpecies,
    String? surgeonName,
    String? ownerName,
    String? ownerPhone,
  }) {
    return SurgeryModel(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      leadSurgeonId: leadSurgeonId ?? this.leadSurgeonId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      surgeryName: surgeryName ?? this.surgeryName,
      surgeryCategory: surgeryCategory ?? this.surgeryCategory,
      status: status ?? this.status,
      preOpChecklistPassed: preOpChecklistPassed ?? this.preOpChecklistPassed,
      anesthesiaProtocol: anesthesiaProtocol ?? this.anesthesiaProtocol,
      postOpNotes: postOpNotes ?? this.postOpNotes,
      estimatedCost: estimatedCost ?? this.estimatedCost,
      petName: petName ?? this.petName,
      petSpecies: petSpecies ?? this.petSpecies,
      surgeonName: surgeonName ?? this.surgeonName,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
    );
  }
}
