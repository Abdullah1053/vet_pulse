class FinancialTransactionModel {
  final int? id;
  final String transactionType; // income, expense, payment
  final String? category; // consultation, surgery, pharmacy, direct_payment, etc.
  final int? ownerId;
  final int? petId;
  final int? referenceId;
  final String? referenceType;
  final double amount;
  final double paidAmount;
  final double remainingAmount;
  final String paymentMethod; // cash, bank_transfer, debt
  final String transactionDate;
  final String? notes;
  final String? createdAt;

  // Joined fields
  final String? ownerName;
  final String? ownerPhone;
  final String? petName;

  FinancialTransactionModel({
    this.id,
    required this.transactionType,
    this.category,
    this.ownerId,
    this.petId,
    this.referenceId,
    this.referenceType,
    required this.amount,
    this.paidAmount = 0.0,
    this.remainingAmount = 0.0,
    this.paymentMethod = 'cash',
    required this.transactionDate,
    this.notes,
    this.createdAt,
    this.ownerName,
    this.ownerPhone,
    this.petName,
  });

  factory FinancialTransactionModel.fromMap(Map<String, dynamic> map) {
    return FinancialTransactionModel(
      id: map['id'] as int?,
      transactionType: map['transaction_type'] as String? ?? 'income',
      category: map['category'] as String?,
      ownerId: map['owner_id'] as int?,
      petId: map['pet_id'] as int?,
      referenceId: map['reference_id'] as int?,
      referenceType: map['reference_type'] as String?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paidAmount: (map['paid_amount'] as num?)?.toDouble() ?? 0.0,
      remainingAmount: (map['remaining_amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['payment_method'] as String? ?? 'cash',
      transactionDate: map['transaction_date'] as String? ?? '',
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String?,
      ownerName: map['owner_name'] as String?,
      ownerPhone: map['owner_phone'] as String?,
      petName: map['pet_name'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'transaction_type': transactionType,
      'category': category,
      'owner_id': ownerId,
      'pet_id': petId,
      'reference_id': referenceId,
      'reference_type': referenceType,
      'amount': amount,
      'paid_amount': paidAmount,
      'remaining_amount': remainingAmount,
      'payment_method': paymentMethod,
      'transaction_date': transactionDate,
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

  String get typeDisplayArabic {
    switch (transactionType) {
      case 'income':
        return 'إيراد خدمات';
      case 'payment':
        return 'سند قبض / دفعة مسددة';
      case 'expense':
        return 'سند صرف / مصروف';
      default:
        return 'حركة مالية';
    }
  }

  String get categoryDisplayArabic {
    switch (category) {
      case 'consultation':
        return 'كشف سريري واستشارة';
      case 'surgery':
        return 'عملية جراحية';
      case 'pharmacy':
        return 'مبيعات صيدلية';
      case 'direct_payment':
        return 'دفعة سداد حساب';
      default:
        return category ?? 'عام';
    }
  }

  String get paymentMethodDisplayArabic {
    switch (paymentMethod) {
      case 'cash':
      case 'نقدا':
        return 'نقدا';
      case 'jawali':
      case 'جوالي':
        return 'جوالي';
      case 'jeeb':
      case 'جيب':
        return 'جيب';
      case 'kuraimi':
      case 'كريمي':
        return 'كريمي';
      case 'floosak':
      case 'فلوسك':
        return 'فلوسك';
      default:
        return paymentMethod.isNotEmpty ? paymentMethod : 'نقدا';
    }
  }

  bool get hasRemainingDebt => false;
}
