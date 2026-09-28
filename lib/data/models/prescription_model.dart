class PrescriptionModel {
  final int? id;
  final int consultationId;
  final int medicineId;
  final String dosage;
  final String frequency;
  final int durationDays;
  final int quantityDispensed;
  final String? instructions;

  // Joined display attributes
  final String? medicineName;
  final String? medicineForm;
  final String? medicineConcentration;

  PrescriptionModel({
    this.id,
    required this.consultationId,
    required this.medicineId,
    required this.dosage,
    required this.frequency,
    required this.durationDays,
    required this.quantityDispensed,
    this.instructions,
    this.medicineName,
    this.medicineForm,
    this.medicineConcentration,
  });

  factory PrescriptionModel.fromMap(Map<String, dynamic> map) {
    return PrescriptionModel(
      id: map['id'] as int?,
      consultationId: map['consultation_id'] as int? ?? 0,
      medicineId: map['medicine_id'] as int? ?? 0,
      dosage: map['dosage'] as String? ?? '',
      frequency: map['frequency'] as String? ?? '',
      durationDays: map['duration_days'] as int? ?? 1,
      quantityDispensed: map['quantity_dispensed'] as int? ?? 1,
      instructions: map['instructions'] as String?,
      medicineName: map['medicine_name'] as String?,
      medicineForm: map['medicine_form'] as String?,
      medicineConcentration: map['medicine_concentration'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'consultation_id': consultationId,
      'medicine_id': medicineId,
      'dosage': dosage,
      'frequency': frequency,
      'duration_days': durationDays,
      'quantity_dispensed': quantityDispensed,
      'instructions': instructions,
    };
  }

  PrescriptionModel copyWith({
    int? id,
    int? consultationId,
    int? medicineId,
    String? dosage,
    String? frequency,
    int? durationDays,
    int? quantityDispensed,
    String? instructions,
    String? medicineName,
    String? medicineForm,
    String? medicineConcentration,
  }) {
    return PrescriptionModel(
      id: id ?? this.id,
      consultationId: consultationId ?? this.consultationId,
      medicineId: medicineId ?? this.medicineId,
      dosage: dosage ?? this.dosage,
      frequency: frequency ?? this.frequency,
      durationDays: durationDays ?? this.durationDays,
      quantityDispensed: quantityDispensed ?? this.quantityDispensed,
      instructions: instructions ?? this.instructions,
      medicineName: medicineName ?? this.medicineName,
      medicineForm: medicineForm ?? this.medicineForm,
      medicineConcentration: medicineConcentration ?? this.medicineConcentration,
    );
  }
}
