import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:intl/intl.dart';
import 'package:printing/printing.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_payment_methods.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../data/models/account_statement_model.dart';
import '../controllers/owner_statement_controller.dart';
import '../utils/financial_statement_pdf_helper.dart';

class OwnerAccountStatementView extends GetView<OwnerStatementController> {
  const OwnerAccountStatementView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Obx(() => Text(
              controller.summary.value != null
                  ? 'كشف حساب: ${controller.summary.value!.ownerName}'
                  : 'كشف حساب مالي',
            )),
        actions: [
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
            title: 'لم يتم العثور على حساب العميل',
            subtitle: 'تأكد من اختيار العميل الصحيح',
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

              // KPI Row: Billed, Paid, Remaining / Balance Due
              _buildKpiMetrics(context, s),
              const SizedBox(height: 16),

              // Date Range Filter Toolbar
              _buildDateFilterBar(context, controller),
              const SizedBox(height: 16),

              // Action Buttons Row (PDF View/Print, Add Payment Voucher)
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
                        'سند قبض / دفعة',
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
                    'كشف الحركات والخدمات التفصيلي (${s.statementItems.length})',
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
                  subtitle: 'لم يتم العثور على أي حركات خلال الفترة المحددة لهذا العميل',
                  icon: Icons.receipt_long_outlined,
                ),
              ] else ...[
                _buildStatementTable(context, s),
              ],

              const SizedBox(height: 24),

              // Payment Ledger Section (سجل الدفعات المستقلة)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'سجل الدفعات وسندات القبض المسددة (${s.paymentLedger.length})',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppColors.darkNeutral,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (s.paymentLedger.isEmpty) ...[
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: const Center(
                    child: Text(
                      'لا توجد سندات قبض مسددة بشكل مستقل بعد',
                      style: TextStyle(color: AppColors.textSecondary, fontSize: 13),
                    ),
                  ),
                ),
              ] else ...[
                _buildPaymentLedgerList(context, s),
              ],
            ],
          ),
        );
      }),
    );
  }

  Widget _buildOwnerHeaderCard(
    BuildContext context,
    OwnerStatementController controller,
    OwnerAccountSummary s,
  ) {
    final hasDebt = s.hasDebt;

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
                        'هاتف: ${s.phonePrimary}',
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
                    color: hasDebt
                        ? Colors.amber.shade50
                        : AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: hasDebt ? Colors.amber.shade700 : AppColors.success,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        hasDebt ? Icons.warning_amber_rounded : Icons.check_circle,
                        size: 16,
                        color: hasDebt ? Colors.amber.shade900 : AppColors.success,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        s.statusDisplayArabic,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: hasDebt ? Colors.amber.shade900 : AppColors.success,
                        ),
                      ),
                    ],
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
            title: 'إجمالي الخدمات',
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

        // Remaining / Balance Due
        Expanded(
          child: _buildMetricCard(
            title: s.hasDebt ? 'المتبقي والآجل' : 'حالة الحساب',
            amount: s.hasDebt
                ? '${s.remainingDue.toStringAsFixed(0)} ر.ي'
                : 'مسدد بالكامل',
            color: s.hasDebt ? Colors.amber.shade900 : AppColors.primary,
            bgColor: s.hasDebt ? Colors.amber.shade50 : AppColors.secondary.withValues(alpha: 0.1),
            icon: s.hasDebt ? Icons.hourglass_bottom : Icons.verified_outlined,
          ),
        ),
      ],
    );
  }

  Widget _buildDateFilterBar(
    BuildContext context,
    OwnerStatementController controller,
  ) {
    final start = controller.startDate.value;
    final end = controller.endDate.value;
    final isFiltered = start != null && end != null;

    final filterText = isFiltered
        ? 'الفترة: ${DateFormat('yyyy-MM-dd').format(start)} إلى ${DateFormat('yyyy-MM-dd').format(end)}'
        : 'كافة الحركات المالية (انقر لتحديد فترة زمنية)';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: isFiltered ? AppColors.secondaryLight : Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isFiltered ? AppColors.primary.withValues(alpha: 0.4) : Colors.grey.shade300,
        ),
      ),
      child: Row(
        children: [
          Icon(
            Icons.date_range,
            size: 20,
            color: isFiltered ? AppColors.primary : AppColors.textSecondary,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: InkWell(
              onTap: () async {
                final picked = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                  initialDateRange: isFiltered
                      ? DateTimeRange(start: start, end: end)
                      : DateTimeRange(
                          start: DateTime.now().subtract(const Duration(days: 30)),
                          end: DateTime.now(),
                        ),
                );
                if (picked != null) {
                  controller.setDateRange(picked.start, picked.end);
                }
              },
              child: Text(
                filterText,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: isFiltered ? FontWeight.bold : FontWeight.normal,
                  color: isFiltered ? AppColors.primaryDark : AppColors.textPrimary,
                ),
              ),
            ),
          ),
          if (isFiltered)
            IconButton(
              icon: const Icon(Icons.close, size: 18, color: AppColors.critical),
              tooltip: 'إلغاء التصفية',
              onPressed: controller.clearDateRange,
            ),
        ],
      ),
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
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: color),
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
            DataColumn(label: Text('البيان / تفاصيل الحركة', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('المريض', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('المطلوب (مدين)', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('المسدد (دائن)', style: TextStyle(fontWeight: FontWeight.bold))),
            DataColumn(label: Text('الرصيد التراكمي', style: TextStyle(fontWeight: FontWeight.bold))),
          ],
          rows: s.statementItems.map((item) {
            return DataRow(
              cells: [
                DataCell(Text(item.date, style: const TextStyle(fontSize: 12))),
                DataCell(
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 240),
                    child: Text(
                      item.description,
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                DataCell(Text(item.petName ?? '-', style: const TextStyle(fontSize: 12))),
                DataCell(Text(
                  item.debit > 0 ? '${item.debit.toStringAsFixed(0)} ر.ي' : '-',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: item.debit > 0 ? Colors.blue.shade900 : Colors.grey,
                  ),
                )),
                DataCell(Text(
                  item.credit > 0 ? '${item.credit.toStringAsFixed(0)} ر.ي' : '-',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: item.credit > 0 ? Colors.green.shade800 : Colors.grey,
                  ),
                )),
                DataCell(
                  Text(
                    '${item.balance.toStringAsFixed(0)} ر.ي',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: item.balance > 0.001 ? Colors.amber.shade900 : AppColors.success,
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

  Widget _buildPaymentLedgerList(BuildContext context, OwnerAccountSummary s) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListView.separated(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: s.paymentLedger.length,
        separatorBuilder: (_, _) => const Divider(height: 1),
        itemBuilder: (context, idx) {
          final p = s.paymentLedger[idx];
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: AppColors.success.withValues(alpha: 0.15),
              child: const Icon(Icons.receipt_long, color: AppColors.success, size: 20),
            ),
            title: Row(
              children: [
                Text(
                  p.receiptNumber ?? '#${p.id}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    p.paymentMethodDisplayArabic,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                ),
              ],
            ),
            subtitle: Text(
              'التاريخ: ${p.paymentDate.length >= 10 ? p.paymentDate.substring(0, 10) : p.paymentDate}${p.notes != null && p.notes!.isNotEmpty ? ' | ${p.notes}' : ''}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
            ),
            trailing: Text(
              '${p.amount.toStringAsFixed(0)} ر.ي',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
                color: AppColors.success,
              ),
            ),
          );
        },
      ),
    );
  }

  void _openPdfPreview(
    BuildContext context,
    OwnerStatementController controller,
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
    OwnerStatementController controller,
  ) {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String paymentMethod = AppPaymentMethods.cash;

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
                    hintText: 'مثال: 5000',
                    prefixIcon: Icon(Icons.money),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'طريقة التحصيل *',
                    border: OutlineInputBorder(),
                  ),
                  items: AppPaymentMethods.fixedOptions.map((opt) {
                    IconData icon;
                    switch (opt) {
                      case AppPaymentMethods.jawali:
                      case AppPaymentMethods.jeeb:
                      case AppPaymentMethods.floosak:
                        icon = Icons.phone_android;
                        break;
                      case AppPaymentMethods.kuraimi:
                        icon = Icons.account_balance;
                        break;
                      case AppPaymentMethods.cash:
                      default:
                        icon = Icons.payments_outlined;
                        break;
                    }
                    return DropdownMenuItem<String>(
                      value: opt,
                      child: Row(
                        children: [
                          Icon(icon, size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(opt, style: const TextStyle(fontWeight: FontWeight.w600)),
                        ],
                      ),
                    );
                  }).toList(),
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
                    hintText: 'سداد دفعة من الحساب الآجل...',
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
