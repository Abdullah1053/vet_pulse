import 'package:get/get.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../data/models/account_statement_model.dart';
import '../../../data/models/clinic_model.dart';
import '../../../data/repositories/financial_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../utils/financial_statement_pdf_helper.dart';
import 'financial_dashboard_controller.dart';

class OwnerStatementController extends GetxController {
  final FinancialRepository _repo;

  OwnerStatementController(this._repo);

  late int ownerId;
  final Rx<OwnerAccountSummary?> summary = Rx<OwnerAccountSummary?>(null);
  final RxBool isLoading = true.obs;

  // Date range filters
  final Rx<DateTime?> startDate = Rx<DateTime?>(null);
  final Rx<DateTime?> endDate = Rx<DateTime?>(null);

  ClinicModel? get clinic =>
      Get.isRegistered<AuthController>() ? Get.find<AuthController>().clinicInfo.value : null;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is int) {
      ownerId = args;
      loadStatement();
    } else {
      Get.back();
    }
  }

  Future<void> loadStatement() async {
    isLoading.value = true;
    try {
      final s = await _repo.getOwnerAccountSummary(
        ownerId,
        startDate: startDate.value,
        endDate: endDate.value,
      );
      summary.value = s;
    } finally {
      isLoading.value = false;
    }
  }

  void setDateRange(DateTime start, DateTime end) {
    startDate.value = start;
    endDate.value = end;
    loadStatement();
  }

  void clearDateRange() {
    startDate.value = null;
    endDate.value = null;
    loadStatement();
  }

  Future<void> recordPayment(double amount, String paymentMethod, String? notes) async {
    await _repo.recordClientPayment(
      ownerId: ownerId,
      amount: amount,
      paymentMethod: paymentMethod,
      notes: notes,
    );
    await loadStatement();
    if (Get.isRegistered<FinancialDashboardController>()) {
      Get.find<FinancialDashboardController>().loadFinancialData();
    }
    Get.snackbar(
      'تم تسجيل سند القبض بنجاح ✅',
      'تم قيد دفعة بقيمة ${amount.toStringAsFixed(0)} ر.ي عبر ($paymentMethod) لحساب العميل',
      backgroundColor: AppColors.success.withValues(alpha: 0.15),
      colorText: AppColors.success,
      duration: const Duration(seconds: 4),
    );
  }

  Future<void> shareStatementWhatsApp() async {
    final s = summary.value;
    if (s == null) return;
    final phone = s.phonePrimary.replaceAll(RegExp(r'\D'), '');

    final msg = '''
*كشف حساب مالي - عيادة نبض البيطرية*
العميل: ${s.ownerName}
------------------------------
إجمالي الخدمات: ${s.totalBilled.toStringAsFixed(0)} ر.ي
إجمالي المسدد: ${s.totalPaid.toStringAsFixed(0)} ر.ي
المتبقي والآجل: ${s.remainingDue.toStringAsFixed(0)} ر.ي
حالة الحساب: ${s.statusDisplayArabic}
------------------------------
تم إصدار هذا الكشف آلياً عبر نظام VetPulse.
''';

    final uri = Uri.parse(
      'whatsapp://send?phone=$phone&text=${Uri.encodeComponent(msg)}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> printPdfStatement() async {
    final s = summary.value;
    if (s == null) return;
    final pdfBytes = await FinancialStatementPdfHelper.generateStatementPdf(
      summary: s,
      clinic: clinic,
    );
    await Printing.layoutPdf(
      onLayout: (_) async => pdfBytes,
      name: 'كشف_حساب_${s.ownerName}',
    );
  }
}
