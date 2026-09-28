class PetWeightModel {
  final int? id;
  final int petId;
  final double weight;
  final String recordedDate;

  PetWeightModel({
    this.id,
    required this.petId,
    required this.weight,
    required this.recordedDate,
  });

  factory PetWeightModel.fromMap(Map<String, dynamic> map) {
    return PetWeightModel(
      id: map['id'] as int?,
      petId: map['pet_id'] as int? ?? 0,
      weight: (map['weight'] as num? ?? 0.0).toDouble(),
      recordedDate: map['recorded_date'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'pet_id': petId,
      'weight': weight,
      'recorded_date': recordedDate,
    };
  }
}
