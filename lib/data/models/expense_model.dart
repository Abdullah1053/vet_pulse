class ExpenseModel {
  final int? id;
  final String title;
  final String category;
  final double amount;
  final String expenseDate;
  final String? notes;
  final String? createdAt;

  ExpenseModel({
    this.id,
    required this.title,
    required this.category,
    required this.amount,
    required this.expenseDate,
    this.notes,
    this.createdAt,
  });

  factory ExpenseModel.fromMap(Map<String, dynamic> map) {
    return ExpenseModel(
      id: map['id'] as int?,
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? 'operating',
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      expenseDate: map['expense_date'] as String? ?? '',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'title': title,
      'category': category,
      'amount': amount,
      'expense_date': expenseDate,
      'notes': notes,
    };
    if (id != null) {
      map['id'] = id;
    }
    if (createdAt != null) {
      map['created_at'] = createdAt;
    }
    return map;
  }

  String get categoryDisplayArabic {
    switch (category) {
      case 'operating':
        return 'مصاريف تشغيلية (كهرباء/طاقة)';
      case 'medical_supplies':
        return 'مستلزمات طبية وتخدير';
      case 'medicines':
        return 'مشتريات أدوية ومخزون';
      case 'rent':
        return 'إيجار مقر العيادة';
      case 'salaries':
        return 'رواتب ومكافآت';
      case 'maintenance':
        return 'صيانة أجهزة ومعدات';
      default:
        return 'مصاريف متنوعة';
    }
  }

  ExpenseModel copyWith({
    int? id,
    String? title,
    String? category,
    double? amount,
    String? expenseDate,
    String? notes,
    String? createdAt,
  }) {
    return ExpenseModel(
      id: id ?? this.id,
      title: title ?? this.title,
      category: category ?? this.category,
      amount: amount ?? this.amount,
      expenseDate: expenseDate ?? this.expenseDate,
      notes: notes ?? this.notes,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
