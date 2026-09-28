import 'prescription_model.dart';

class ConsultationModel {
  final int? id;
  final int petId;
  final int doctorId;
  final String visitDate;
  final double? temperature;
  final int? heartRate;
  final String? symptoms; // Subjective
  final String? examinationFindings; // Objective
  final String diagnosis; // Assessment
  final String? treatmentPlan; // Plan
  final double visitCost;
  final String? createdAt;

  // Joined fields
  final String? petName;
  final String? petSpecies;
  final String? doctorName;
  final String? ownerName;
  final List<PrescriptionModel> prescriptions;

  ConsultationModel({
    this.id,
    required this.petId,
    required this.doctorId,
    required this.visitDate,
    this.temperature,
    this.heartRate,
    this.symptoms,
    this.examinationFindings,
    required this.diagnosis,
    this.treatmentPlan,
    this.visitCost = 0.0,
    this.createdAt,
    this.petName,
    this.petSpecies,
    this.doctorName,
    this.ownerName,
    this.prescriptions = const [],
  });

  factory ConsultationModel.fromMap(Map<String, dynamic> map, {List<PrescriptionModel> prescriptions = const []}) {
    return ConsultationModel(
      id: map['id'] as int?,
      petId: map['pet_id'] as int? ?? 0,
      doctorId: map['doctor_id'] as int? ?? 0,
      visitDate: map['visit_date'] as String? ?? '',
      temperature: (map['temperature'] as num?)?.toDouble(),
      heartRate: map['heart_rate'] as int?,
      symptoms: map['symptoms'] as String?,
      examinationFindings: map['examination_findings'] as String?,
      diagnosis: map['diagnosis'] as String? ?? '',
      treatmentPlan: map['treatment_plan'] as String?,
      visitCost: (map['visit_cost'] as num? ?? 0.0).toDouble(),
      createdAt: map['created_at'] as String?,
      petName: map['pet_name'] as String?,
      petSpecies: map['pet_species'] as String?,
      doctorName: map['doctor_name'] as String?,
      ownerName: map['owner_name'] as String?,
      prescriptions: prescriptions,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'pet_id': petId,
      'doctor_id': doctorId,
      'visit_date': visitDate,
      'temperature': temperature,
      'heart_rate': heartRate,
      'symptoms': symptoms,
      'examination_findings': examinationFindings,
      'diagnosis': diagnosis,
      'treatment_plan': treatmentPlan,
      'visit_cost': visitCost,
    };
  }

  ConsultationModel copyWith({
    int? id,
    int? petId,
    int? doctorId,
    String? visitDate,
    double? temperature,
    int? heartRate,
    String? symptoms,
    String? examinationFindings,
    String? diagnosis,
    String? treatmentPlan,
    double? visitCost,
    String? createdAt,
    String? petName,
    String? petSpecies,
    String? doctorName,
    String? ownerName,
    List<PrescriptionModel>? prescriptions,
  }) {
    return ConsultationModel(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      doctorId: doctorId ?? this.doctorId,
      visitDate: visitDate ?? this.visitDate,
      temperature: temperature ?? this.temperature,
      heartRate: heartRate ?? this.heartRate,
      symptoms: symptoms ?? this.symptoms,
      examinationFindings: examinationFindings ?? this.examinationFindings,
      diagnosis: diagnosis ?? this.diagnosis,
      treatmentPlan: treatmentPlan ?? this.treatmentPlan,
      visitCost: visitCost ?? this.visitCost,
      createdAt: createdAt ?? this.createdAt,
      petName: petName ?? this.petName,
      petSpecies: petSpecies ?? this.petSpecies,
      doctorName: doctorName ?? this.doctorName,
      ownerName: ownerName ?? this.ownerName,
      prescriptions: prescriptions ?? this.prescriptions,
    );
  }
}
