class AppPaymentMethods {
  AppPaymentMethods._();

  static const String cash = 'نقدا';
  static const String deferred = 'آجل';
  static const String jawali = 'جوالي';
  static const String jeeb = 'جيب';
  static const String kuraimi = 'كريمي';
  static const String floosak = 'فلوسك';

  static const List<String> fixedOptions = [
    cash,
    jawali,
    jeeb,
    kuraimi,
    floosak,
  ];

  static const List<String> billingOptions = [
    cash,
    deferred,
    jawali,
    jeeb,
    kuraimi,
    floosak,
  ];
}
