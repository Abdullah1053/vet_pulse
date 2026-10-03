import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../data/models/account_statement_model.dart';
import '../../../data/models/clinic_model.dart';
import '../../../data/repositories/financial_repository.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/financial_controller.dart';
import '../utils/financial_statement_pdf_helper.dart';

class OwnerAccountStatementController extends GetxController {
  final FinancialRepository _repo = FinancialRepository();
  final AuthController _authController = Get.find<AuthController>();

  late int ownerId;
  final Rx<OwnerAccountSummary?> summary = Rx<OwnerAccountSummary?>(null);
  final RxBool isLoading = true.obs;

  ClinicModel? get clinic => _authController.clinicInfo.value;

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
      final s = await _repo.getOwnerAccountSummary(ownerId);
      summary.value = s;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> recordPayment(double amount, String paymentMethod, String? notes) async {
    await _repo.recordClientPayment(
      ownerId: ownerId,
      amount: amount,
      paymentMethod: paymentMethod,
      notes: notes,
    );
    await loadStatement();
    if (Get.isRegistered<FinancialController>()) {
      Get.find<FinancialController>().loadFinancialData();
    }
    Get.snackbar(
      'تم تسجيل سند القبض بنجاح',
      'تم قيد دفعة نقدية بقيمة ${amount.toStringAsFixed(0)} ر.ي وتحديث رصيد المربي',
      backgroundColor: AppColors.success.withValues(alpha: 0.2),
      colorText: AppColors.success,
    );
  }

  Future<void> shareStatementWhatsApp() async {
    final s = summary.value;
    if (s == null) return;
    final phone = s.phonePrimary.replaceAll(RegExp(r'\D'), '');

    final msg = '''
*كشف حساب مالي - عيادة نبض البيطرية*
المربي: ${s.ownerName}
------------------------------
إجمالي المطالبات (مدين): ${s.totalBilled.toStringAsFixed(0)} ر.ي
إجمالي المسدد (دائن): ${s.totalPaid.toStringAsFixed(0)} ر.ي
*المتبقي المستحق:* ${s.balanceDue.toStringAsFixed(0)} ر.ي
------------------------------
نشكركم على ثقتكم بنا.
''';

    final uri = Uri.parse('whatsapp://send?phone=$phone&text=${Uri.encodeComponent(msg)}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      Get.snackbar('واتساب', 'تعذر فتح تطبيق واتساب');
    }
  }
}

class OwnerAccountStatementView extends StatelessWidget {
  const OwnerAccountStatementView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OwnerAccountStatementController());

    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
              controller.summary.value != null
                  ? 'كشف حساب: ${controller.summary.value!.ownerName}'
                  : 'كشف حساب مالي',
            )),
        actions: [
          IconButton(
            tooltip: 'تحديث البيانات',
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadStatement,
          ),
          IconButton(
            tooltip: 'مشاركة ملخص عبر واتساب',
            icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
            onPressed: controller.shareStatementWhatsApp,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final s = controller.summary.value;
        if (s == null) {
          return const EmptyStateView(
            title: 'لم يتم العثور على حساب المربي',
            subtitle: 'تأكد من اختيار المربي الصحيح',
            icon: Icons.account_balance_wallet_outlined,
          );
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Client & Balance Overview Card
              _buildOwnerHeaderCard(context, controller, s),
              const SizedBox(height: 16),

              // KPI Row: Billed, Paid, Remaining
              _buildKpiMetrics(context, s),
              const SizedBox(height: 20),

              // Action Buttons Row (PDF View/Print, Add Payment)
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: () => _openPdfPreview(context, controller, s),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 20),
                      label: const Text(
                        'عرض وطباعة كشف الحساب (PDF)',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () => _showAddPaymentDialog(context, controller),
                      icon: const Icon(Icons.add_card_outlined, size: 18),
                      label: const Text(
                        'سند قبض',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Ledger Transactions Table Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'سجل الحركات والخدمات السريرية (${s.statementItems.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkNeutral,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (s.statementItems.isEmpty) ...[
                const EmptyStateView(
                  title: 'لا توجد حركات مالية مسجلة',
                  subtitle: 'لم يتم تسجيل أي كشوفات أو عمليات أو دفعات بعد لهذا المربي',
                  icon: Icons.receipt_long_outlined,
                ),
              ] else ...[
                _buildStatementTable(context, s),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildOwnerHeaderCard(
    BuildContext context,
    OwnerAccountStatementController controller,
    OwnerAccountSummary s,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 28,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: AppColors.primary, size: 30),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        s.ownerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 17),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'هاتف: ${s.phonePrimary} ${s.phoneSecondary != null ? " | ${s.phoneSecondary}" : ""}',
                        style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                      ),
                      if (s.address != null && s.address!.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          s.address!,
                          style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: s.hasDebt ? AppColors.criticalBackground : AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: s.hasDebt ? AppColors.critical : AppColors.success,
                      width: 1,
                    ),
                  ),
                  child: Text(
                    s.hasDebt ? 'عليه دين متبقي' : 'الحساب خالص ومسدد',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: s.hasDebt ? AppColors.critical : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildKpiMetrics(BuildContext context, OwnerAccountSummary s) {
    return Row(
      children: [
        // Total Billed
        Expanded(
          child: _buildMetricCard(
            title: 'إجمالي المطالبات',
            amount: '${s.totalBilled.toStringAsFixed(0)} ر.ي',
            color: Colors.blue.shade800,
            bgColor: Colors.blue.shade50,
            icon: Icons.receipt_outlined,
          ),
        ),
        const SizedBox(width: 10),

        // Total Paid
        Expanded(
          child: _buildMetricCard(
            title: 'إجمالي المسدد',
            amount: '${s.totalPaid.toStringAsFixed(0)} ر.ي',
            color: Colors.green.shade800,
            bgColor: Colors.green.shade50,
            icon: Icons.check_circle_outline,
          ),
        ),
        const SizedBox(width: 10),

        // Balance Due
        Expanded(
          child: _buildMetricCard(
            title: s.hasDebt ? 'المتبقي (دين)' : 'الرصيد',
            amount: '${s.balanceDue.toStringAsFixed(0)} ر.ي',
            color: s.hasDebt ? AppColors.critical : AppColors.primary,
            bgColor: s.hasDebt ? AppColors.criticalBackground : AppColors.secondary.withValues(alpha: 0.1),
            icon: s.hasDebt ? Icons.warning_amber_rounded : Icons.account_balance_wallet_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String amount,
    required Color color,
    required Color bgColor,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 6),
          Text(
            amount,
            style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold, color: color),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 2),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: color.withValues(alpha: 0.85)),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildStatementTable(BuildContext context, OwnerAccountSummary s) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      clipBehavior: Clip.antiAlias,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: DataTable(
          headingRowColor: WidgetStateProperty.all(AppColors.primary.withValues(alpha: 0.08)),
          columns: const [
            DataColumn(label: Text('التاريخ', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('البيان / الخدمة', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('المريض', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('مدين (ر.ي)', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('دائن (ر.ي)', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الرصيد (ر.ي)', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: s.statementItems.map((item) {
            return DataRow(
              cells: [
                DataCell(Text(item.date, style: const TextStyle(fontSize: 12))),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 220),
                    child: Text(
                      item.description,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(item.petName ?? '-', style: const TextStyle(fontSize: 12))),
                DataCell(Text(
                  item.debit > 0 ? item.debit.toStringAsFixed(0) : '-',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: item.debit > 0 ? Colors.blue.shade900 : Colors.grey,
                  ),
                )),
                DataCell(Text(
                  item.credit > 0 ? item.credit.toStringAsFixed(0) : '-',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: item.credit > 0 ? Colors.green.shade800 : Colors.grey,
                  ),
                )),
                DataCell(
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: item.balance > 0
                          ? AppColors.criticalBackground
                          : AppColors.success.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      item.balance.toStringAsFixed(0),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: item.balance > 0 ? AppColors.critical : AppColors.success,
                      ),
                    ),
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ),
    );
  }

  void _openPdfPreview(
    BuildContext context,
    OwnerAccountStatementController controller,
    OwnerAccountSummary s,
  ) {
    Get.to(() => Scaffold(
          appBar: AppBar(
            title: Text('كشف حساب PDF: ${s.ownerName}'),
            actions: [
              IconButton(
                tooltip: 'مشاركة PDF',
                icon: const Icon(Icons.share),
                onPressed: () => FinancialStatementPdfHelper.shareStatementPdf(
                  summary: s,
                  clinic: controller.clinic,
                ),
              ),
            ],
          ),
          body: PdfPreview(
            build: (format) => FinancialStatementPdfHelper.generateStatementPdf(
              summary: s,
              clinic: controller.clinic,
            ),
            pdfFileName: 'account_statement_${s.ownerName}_${s.ownerId}.pdf',
            canChangeOrientation: false,
            canChangePageFormat: false,
          ),
        ));
  }

  void _showAddPaymentDialog(
    BuildContext context,
    OwnerAccountStatementController controller,
  ) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String paymentMethod = 'cash';

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: AppColors.success),
            const SizedBox(width: 8),
            Text('سند قبض لحساب: ${controller.summary.value?.ownerName ?? ""}'),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ المسدد (ر.ي) *',
                    hintText: 'مثال: 10000',
                    prefixIcon: Icon(Icons.money),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  initialValue: paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'طريقة التحصيل *',
                    border: OutlineInputBorder(),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'cash', child: Text('نقداً (كاش)')),
                    DropdownMenuItem(value: 'bank_transfer', child: Text('تحويل بنكي / محفظة إلكترونية')),
                  ],
                  onChanged: (val) {
                    if (val != null) {
                      setState(() => paymentMethod = val);
                    }
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات السند (اختياري)',
                    hintText: 'سداد دفعة متبقية من عملية...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('إلغاء'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
              if (amt <= 0) {
                Get.snackbar('خطأ', 'يرجى إدخال مبلغ صحيح');
                return;
              }
              Get.back();
              controller.recordPayment(
                amt,
                paymentMethod,
                notesController.text.trim().isEmpty ? null : notesController.text.trim(),
              );
            },
            child: const Text('حفظ سند القبض'),
          ),
        ],
      ),
    );
  }
}
