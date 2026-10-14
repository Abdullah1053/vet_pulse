import 'customer_payment_model.dart';

class AccountStatementItem {
  final int? id;
  final String date;
  final String type; // 'consultation', 'surgery', 'payment', 'pharmacy', 'other'
  final String description;
  final String? petName;
  final double debit; // تكلفة الخدمة / المطالبة
  final double credit; // الدفعة المسددة
  final double balance; // الرصيد التراكمي
  final String? paymentMethod;
  final String? notes;

  AccountStatementItem({
    this.id,
    required this.date,
    required this.type,
    required this.description,
    this.petName,
    required this.debit,
    required this.credit,
    required this.balance,
    this.paymentMethod,
    this.notes,
  });

  String get typeDisplayArabic {
    switch (type) {
      case 'consultation':
        return 'كشف سريري';
      case 'surgery':
        return 'عملية جراحية';
      case 'payment':
        return 'سند قبض / دفعة';
      case 'pharmacy':
        return 'مشتريات صيدلية';
      case 'opening_balance':
        return 'رصيد سابق منقول';
      default:
        return 'حركة حساب';
    }
  }
}

class OwnerAccountSummary {
  final int ownerId;
  final String ownerName;
  final String phonePrimary;
  final String? address;
  final double totalBilled; // إجمالي قيمة الخدمات والمشتريات
  final double totalPaid; // إجمالي المبالغ المسددة فعلياً
  final double balanceDue; // إجمالي المبالغ المتبقية والآجلة
  final List<AccountStatementItem> statementItems;
  final List<CustomerPaymentModel> paymentLedger;

  OwnerAccountSummary({
    required this.ownerId,
    required this.ownerName,
    required this.phonePrimary,
    this.address,
    required this.totalBilled,
    required this.totalPaid,
    required this.balanceDue,
    this.statementItems = const [],
    this.paymentLedger = const [],
  });

  /// هل على العميل مبالغ آجلة مستحقة السداد؟
  bool get hasDebt => balanceDue > 0.001;

  /// هل الحساب خالص ومسدد بالكامل؟
  bool get isFullySettled => balanceDue <= 0.001;

  /// المبلغ المتبقي والآجل (موجب دائماً)
  double get remainingDue => balanceDue > 0 ? balanceDue : 0.0;

  /// نص حالة الحساب باللغة العربية
  String get statusDisplayArabic {
    if (isFullySettled) {
      return 'خالص ومسدد بالكامل';
    } else {
      return 'رصيد متبقي آجل: ${remainingDue.toStringAsFixed(0)} ر.ي';
    }
  }
}
