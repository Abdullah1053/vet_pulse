import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_payment_methods.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../controllers/new_consultation_controller.dart';

class ConsultationFinancialSection extends GetView<NewConsultationController> {
  const ConsultationFinancialSection({super.key});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  '5- أتعاب الكشف والخدمات السريرية',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    AppStringsAr.currency, // ريال يمني
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            // Payment method selector placed before fees inputs
            Obx(
              () => DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: controller.selectedPaymentMethod.value,
                decoration: const InputDecoration(
                  labelText: 'طريقة الدفع *',
                  prefixIcon: Icon(Icons.payment, color: AppColors.primary),
                  border: OutlineInputBorder(),
                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                ),
                items: const [
                  DropdownMenuItem(
                    value: AppPaymentMethods.cash,
                    child: Row(
                      children: [
                        Icon(Icons.money, size: 18, color: Colors.green),
                        SizedBox(width: 8),
                        Text('نقدا', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppPaymentMethods.deferred,
                    child: Row(
                      children: [
                        Icon(Icons.schedule_send_outlined, size: 18, color: Colors.deepOrange),
                        SizedBox(width: 8),
                        Text(
                          'آجل (مبلغ مستحق لاحقاً)',
                          style: TextStyle(fontWeight: FontWeight.bold, color: Colors.deepOrange),
                        ),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppPaymentMethods.jawali,
                    child: Row(
                      children: [
                        Icon(Icons.phone_android, size: 18, color: Colors.blue),
                        SizedBox(width: 8),
                        Text('جوالي', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppPaymentMethods.jeeb,
                    child: Row(
                      children: [
                        Icon(Icons.account_balance_wallet, size: 18, color: Colors.purple),
                        SizedBox(width: 8),
                        Text('جيب', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppPaymentMethods.kuraimi,
                    child: Row(
                      children: [
                        Icon(Icons.account_balance, size: 18, color: Colors.teal),
                        SizedBox(width: 8),
                        Text('كريمي', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                  DropdownMenuItem(
                    value: AppPaymentMethods.floosak,
                    child: Row(
                      children: [
                        Icon(Icons.credit_card, size: 18, color: Colors.orange),
                        SizedBox(width: 8),
                        Text('فلوسك', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  ),
                ],
                onChanged: (val) {
                  if (val != null) controller.setPaymentMethod(val);
                },
              ),
            ),
            const SizedBox(height: 12),
            // Fees inputs: Hide paid amount when deferred
            Obx(() {
              if (controller.isDeferredPayment) {
                return CustomTextField(
                  label: 'إجمالي الأتعاب (${AppStringsAr.currencyShort}) *',
                  hint: '5000',
                  controller: controller.costController,
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                  prefixIcon: const Icon(Icons.request_quote_outlined),
                );
              }
              return Row(
                children: [
                  Expanded(
                    child: CustomTextField(
                      label: 'إجمالي الأتعاب (${AppStringsAr.currencyShort}) *',
                      hint: '5000',
                      controller: controller.costController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.request_quote_outlined),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: CustomTextField(
                      label: 'المبلغ المدفوع (${AppStringsAr.currencyShort}) *',
                      hint: 'المسدد الآن',
                      controller: controller.paidAmountController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      prefixIcon: const Icon(Icons.price_check),
                    ),
                  ),
                ],
              );
            }),
            const SizedBox(height: 12),
            // Live remaining calculation banner
            Obx(() {
              final cost = double.tryParse(controller.costController.text.trim()) ?? 0.0;
              final paid = controller.isDeferredPayment
                  ? 0.0
                  : (double.tryParse(controller.paidAmountController.text.trim()) ?? 0.0);
              final remaining = controller.remainingAmount.value;
              final isFullyPaid = !controller.isDeferredPayment && remaining <= 0.001;
              final isZeroPaid = controller.isDeferredPayment || (paid <= 0.001 && cost > 0);

              Color bgColor = isFullyPaid
                  ? AppColors.success.withValues(alpha: 0.1)
                  : (isZeroPaid ? Colors.red.shade50 : Colors.amber.shade50);
              Color borderColor = isFullyPaid
                  ? AppColors.success.withValues(alpha: 0.4)
                  : (isZeroPaid ? Colors.red.shade300 : Colors.amber.shade400);
              Color textColor = isFullyPaid
                  ? AppColors.success
                  : (isZeroPaid ? Colors.red.shade800 : Colors.amber.shade900);
              IconData icon = isFullyPaid
                  ? Icons.check_circle_outline
                  : (isZeroPaid ? Icons.pending_actions : Icons.hourglass_bottom);

              String statusTitle;
              String statusSubtitle;
              if (isFullyPaid) {
                statusTitle = 'مسدد بالكامل (${paid.toStringAsFixed(0)} ${AppStringsAr.currencyShort})';
                statusSubtitle = 'لا توجد مبالغ آجلة على هذا الكشف';
              } else if (isZeroPaid) {
                statusTitle = 'مبلغ آجل بالكامل (${remaining.toStringAsFixed(0)} ${AppStringsAr.currencyShort})';
                statusSubtitle = 'سيتم ترحيل كامل المبلغ كمديونية ومستحق على حساب العميل';
              } else {
                statusTitle = 'سداد جزئي - متبقي آجل (${remaining.toStringAsFixed(0)} ${AppStringsAr.currencyShort})';
                statusSubtitle = 'تم دفع ${paid.toStringAsFixed(0)} وسيرحل المتبقي كمديونية على حساب العميل';
              }

              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: bgColor,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: borderColor),
                ),
                child: Row(
                  children: [
                    Icon(icon, color: textColor, size: 24),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            statusTitle,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: textColor,
                            ),
                          ),
                          Text(
                            statusSubtitle,
                            style: TextStyle(fontSize: 11, color: textColor.withValues(alpha: 0.85)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 14),
            Obx(
              () => Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: controller.showCostInPrescription.value
                      ? AppColors.secondaryLight
                      : Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: controller.showCostInPrescription.value
                        ? AppColors.primary.withValues(alpha: 0.3)
                        : Colors.grey.shade300,
                  ),
                ),
                child: Row(
                  children: [
                    Icon(
                      controller.showCostInPrescription.value
                          ? Icons.receipt_long
                          : Icons.money_off,
                      color: controller.showCostInPrescription.value
                          ? AppColors.primary
                          : Colors.grey.shade600,
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'إظهار أتعاب الكشف في الروشتة المطبوعة',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: controller.showCostInPrescription.value
                                  ? AppColors.primaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            controller.showCostInPrescription.value
                                ? 'سيظهر مبلغ الأتعاب في أسفل الروشتة'
                                : 'مخفي: لن يظهر المبلغ في الروشتة (روشتة علاجية فقط)',
                            style: TextStyle(
                              fontSize: 11,
                              color: controller.showCostInPrescription.value
                                  ? AppColors.primaryDark.withValues(alpha: 0.8)
                                  : Colors.grey.shade600,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch.adaptive(
                      value: controller.showCostInPrescription.value,
                      activeTrackColor: AppColors.primary,
                      onChanged: (val) => controller.showCostInPrescription.value = val,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
