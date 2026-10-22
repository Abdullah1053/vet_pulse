class CustomerPaymentModel {
  final int? id;
  final int ownerId;
  final int? transactionId;
  final double amount;
  final String paymentMethod;
  final String paymentDate;
  final String? receiptNumber;
  final String? notes;
  final String? createdAt;

  // Joined fields
  final String? ownerName;
  final String? ownerPhone;

  CustomerPaymentModel({
    this.id,
    required this.ownerId,
    this.transactionId,
    required this.amount,
    this.paymentMethod = 'نقدا',
    required this.paymentDate,
    this.receiptNumber,
    this.notes,
    this.createdAt,
    this.ownerName,
    this.ownerPhone,
  });

  factory CustomerPaymentModel.fromMap(Map<String, dynamic> map) {
    return CustomerPaymentModel(
      id: map['id'] as int?,
      ownerId: map['owner_id'] as int? ?? 0,
      transactionId: map['transaction_id'] as int?,
      amount: (map['amount'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: map['payment_method'] as String? ?? 'نقدا',
      paymentDate: map['payment_date'] as String? ?? '',
      receiptNumber: map['receipt_number'] as String?,
      notes: map['notes'] as String?,
      createdAt: map['created_at'] as String?,
      ownerName: map['owner_name'] as String?,
      ownerPhone: map['owner_phone'] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final map = <String, dynamic>{
      'owner_id': ownerId,
      'amount': amount,
      'payment_method': paymentMethod,
      'payment_date': paymentDate,
      'receipt_number': receiptNumber,
      'notes': notes,
    };
    if (id != null) map['id'] = id;
    if (transactionId != null) map['transaction_id'] = transactionId;
    if (createdAt != null) map['created_at'] = createdAt;
    return map;
  }

  String get paymentMethodDisplayArabic {
    switch (paymentMethod) {
      case 'deferred':
      case 'آجل':
        return 'آجل (مديونية)';
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

  String get formattedDate {
    if (paymentDate.length >= 10) {
      return paymentDate.substring(0, 10);
    }
    return paymentDate;
  }
}
