class BackupLogModel {
  final int? id;
  final String backupName;
  final String filePath;
  final int sizeBytes;
  final String backupType; // 'internal', 'external', 'manual', 'scheduled'
  final String? destination;
  final String status; // 'success', 'failed'
  final String? errorMessage;
  final String createdAt;

  BackupLogModel({
    this.id,
    required this.backupName,
    required this.filePath,
    this.sizeBytes = 0,
    this.backupType = 'internal',
    this.destination,
    this.status = 'success',
    this.errorMessage,
    required this.createdAt,
  });

  factory BackupLogModel.fromMap(Map<String, dynamic> map) {
    return BackupLogModel(
      id: map['id'] as int?,
      backupName: map['backup_name'] as String? ?? '',
      filePath: map['file_path'] as String? ?? '',
      sizeBytes: map['size_bytes'] as int? ?? 0,
      backupType: map['backup_type'] as String? ?? 'internal',
      destination: map['destination'] as String?,
      status: map['status'] as String? ?? 'success',
      errorMessage: map['error_message'] as String?,
      createdAt: map['created_at'] as String? ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'backup_name': backupName,
      'file_path': filePath,
      'size_bytes': sizeBytes,
      'backup_type': backupType,
      'destination': destination,
      'status': status,
      'error_message': errorMessage,
      'created_at': createdAt,
    };
    if (id != null) map['id'] = id;
    return map;
  }

  String get formattedSize {
    if (sizeBytes < 1024) return '$sizeBytes B';
    if (sizeBytes < 1024 * 1024) return '${(sizeBytes / 1024).toStringAsFixed(1)} KB';
    return '${(sizeBytes / (1024 * 1024)).toStringAsFixed(2)} MB';
  }

  String get typeDisplayArabic {
    switch (backupType) {
      case 'internal':
        return 'نسخ داخلي';
      case 'external':
        return 'نسخ خارجي (فلاش / مجلد)';
      case 'cloud':
        return 'نسخ سحابي';
      case 'scheduled':
        return 'نسخ دوري مجدول';
      default:
        return 'نسخ احتياطي';
    }
  }

  bool get isSuccess => status == 'success';
}
