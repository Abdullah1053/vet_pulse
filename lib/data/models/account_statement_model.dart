class AccountStatementItem {
  final int? id;
  final String date;
  final String type; // 'consultation', 'surgery', 'payment', 'pharmacy', 'other'
  final String description;
  final String? petName;
  final double debit; // تكلفة الخدمة المسددة
  final double credit; // المدفوع
  final double balance; // الرصيد الحالي
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
    this.notes,
  });

  String get typeDisplayArabic {
    switch (type) {
      case 'consultation':
        return 'كشف سريري';
      case 'surgery':
        return 'عملية جراحية';
      case 'payment':
        return 'سند قبض';
      case 'pharmacy':
        return 'صيدلية';
      default:
        return 'حركة حساب';
    }
  }
}

class OwnerAccountSummary {
  final int ownerId;
  final String ownerName;
  final String phonePrimary;
  final String? phoneSecondary;
  final String? address;
  final double totalBilled; // إجمالي الفواتير
  final double totalPaid; // إجمالي المسدد
  final double balanceDue; // الرصيد
  final List<AccountStatementItem> statementItems;

  OwnerAccountSummary({
    required this.ownerId,
    required this.ownerName,
    required this.phonePrimary,
    this.phoneSecondary,
    this.address,
    required this.totalBilled,
    required this.totalPaid,
    required this.balanceDue,
    this.statementItems = const [],
  });

  bool get hasDebt => false;
}
