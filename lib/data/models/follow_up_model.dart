import '../../core/utils/arabic_date_helper.dart';

class FollowUpModel {
  final int? id;
  final int petId;
  final int? consultationId;
  final String scheduledDate;
  final String? scheduledTime;
  final String reason;
  final String status; // pending, completed, missed, cancelled
  final bool reminderSent;
  final String? notes;

  // Joined fields
  final String? petName;
  final String? petSpecies;
  final String? ownerName;
  final String? ownerPhone;

  FollowUpModel({
    this.id,
    required this.petId,
    this.consultationId,
    required this.scheduledDate,
    this.scheduledTime,
    required this.reason,
    this.status = 'pending',
    this.reminderSent = false,
    this.notes,
    this.petName,
    this.petSpecies,
    this.ownerName,
    this.ownerPhone,
  });

  factory FollowUpModel.fromMap(Map<String, dynamic> map) {
    return FollowUpModel(
      id: map['id'] as int?,
      petId: map['pet_id'] as int? ?? 0,
      consultationId: map['consultation_id'] as int?,
      scheduledDate: map['scheduled_date'] as String? ?? '',
      scheduledTime: map['scheduled_time'] as String?,
      reason: map['reason'] as String? ?? '',
      status: map['status'] as String? ?? 'pending',
      reminderSent: (map['reminder_sent'] as int? ?? 0) == 1,
      notes: map['notes'] as String?,
      petName: map['pet_name'] as String?,
      petSpecies: map['pet_species'] as String?,
      ownerName: map['owner_name'] as String?,
      ownerPhone: map['owner_phone'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'pet_id': petId,
      'consultation_id': consultationId,
      'scheduled_date': scheduledDate,
      'scheduled_time': scheduledTime,
      'reason': reason,
      'status': status,
      'reminder_sent': reminderSent ? 1 : 0,
      'notes': notes,
    };
  }

  bool get isPending => status == 'pending';
  bool get isCompleted => status == 'completed';
  bool get isMissed => status == 'missed';
  bool get isCancelled => status == 'cancelled';

  bool get isOverdue {
    if (!isPending) return false;
    final date = ArabicDateHelper.parseDate(scheduledDate);
    if (date == null) return false;
    return ArabicDateHelper.daysDifference(date) < 0;
  }

  bool get isToday {
    final date = ArabicDateHelper.parseDate(scheduledDate);
    if (date == null) return false;
    return ArabicDateHelper.daysDifference(date) == 0;
  }

  String get statusDisplayArabic {
    switch (status) {
      case 'pending':
        return isOverdue ? 'متأخرة' : (isToday ? 'اليوم' : 'قيد الانتظار');
      case 'completed':
        return 'تمت الزيارة';
      case 'missed':
        return 'فائتة';
      case 'cancelled':
        return 'ملغية';
      default:
        return status;
    }
  }

  FollowUpModel copyWith({
    int? id,
    int? petId,
    int? consultationId,
    String? scheduledDate,
    String? scheduledTime,
    String? reason,
    String? status,
    bool? reminderSent,
    String? notes,
    String? petName,
    String? petSpecies,
    String? ownerName,
    String? ownerPhone,
  }) {
    return FollowUpModel(
      id: id ?? this.id,
      petId: petId ?? this.petId,
      consultationId: consultationId ?? this.consultationId,
      scheduledDate: scheduledDate ?? this.scheduledDate,
      scheduledTime: scheduledTime ?? this.scheduledTime,
      reason: reason ?? this.reason,
      status: status ?? this.status,
      reminderSent: reminderSent ?? this.reminderSent,
      notes: notes ?? this.notes,
      petName: petName ?? this.petName,
      petSpecies: petSpecies ?? this.petSpecies,
      ownerName: ownerName ?? this.ownerName,
      ownerPhone: ownerPhone ?? this.ownerPhone,
    );
  }
}
