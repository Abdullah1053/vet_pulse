import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_payment_methods.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../routes/app_routes.dart';
import '../../consultations/widgets/clinic_treatments_section.dart';
import '../../consultations/widgets/home_prescriptions_section.dart';
import '../controllers/complete_surgery_controller.dart';
import '../widgets/surgery_follow_up_card.dart';

class CompleteSurgeryView extends GetView<CompleteSurgeryController> {
  const CompleteSurgeryView({super.key});

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      if (!controller.isInitialized.value || controller.surgery.value == null) {
        return Scaffold(
          appBar: AppBar(title: const Text('تقرير إتمام العملية الجراحية')),
          body: const Center(child: Text('لم يتم تمرير بيانات العملية')),
        );
      }

      final surgery = controller.surgery.value!;

      return Scaffold(
        appBar: AppBar(
          title: const Text('تقرير إتمام العملية والتخريج الجراحي'),
        ),
        bottomNavigationBar: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Obx(() => PrimaryButton(
                text: controller.isSaving.value ? 'جاري الحفظ...' : 'اعتماد إتمام العملية وحفظ التقرير',
                icon: Icons.task_alt,
                isLoading: controller.isSaving.value,
                onPressed: controller.isSaving.value ? null : controller.submitCompletion,
              )),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Surgery summary banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.secondaryLight,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            surgery.surgeryName,
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: Colors.blue.shade300),
                          ),
                          child: Text(
                            surgery.surgeryCategory ?? 'جراحة عامة',
                            style: TextStyle(fontSize: 12, color: Colors.blue.shade800, fontWeight: FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 16),
                    Row(
                      children: [
                        const Icon(Icons.pets, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'المريض: ${surgery.petName ?? "غير محدد"} (${surgery.petSpecies ?? ""})',
                          style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                        ),
                        const Spacer(),
                        InkWell(
                          onTap: () => Get.toNamed(AppRoutes.patientDetail, arguments: surgery.petId),
                          child: const Row(
                            children: [
                              Text('عرض الملف الطبي',
                                  style: TextStyle(color: AppColors.primary, fontSize: 12, fontWeight: FontWeight.bold)),
                              SizedBox(width: 2),
                              Icon(Icons.arrow_forward_ios, size: 10, color: AppColors.primary),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.person, size: 16, color: AppColors.textSecondary),
                        const SizedBox(width: 6),
                        Text(
                          'المالك: ${surgery.ownerName ?? "غير محدد"}',
                          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Card 1: Surgical Outcomes & Clinical Notes
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.notes, color: AppColors.primary, size: 20),
                          SizedBox(width: 8),
                          Text('نتائج العملية الجراحية وملاحظات الجراح',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'تقرير نتائج الجراحة *',
                        hint: 'مثال: تمت العملية بنجاح، استئصال تام بدون نزيف، إغلاق الجرح بطبقتين...',
                        controller: controller.outcomeNotesController,
                        maxLines: 3,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'حالة الإفاقة والتخدير',
                        hint: 'حالة العلامات الحيوية عند الإفاقة',
                        controller: controller.recoveryStatusController,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'ملاحظات المضاعفات (إن وجدت)',
                        hint: 'اكتب "لا توجد" أو اذكر أي مضاعفات للمتابعة',
                        controller: controller.complicationsController,
                        maxLines: 2,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card 2: Owner Home-Care Instructions
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.home_work_outlined, color: AppColors.accent, size: 20),
                          SizedBox(width: 8),
                          Text('تعليمات وإرشادات الرعاية المنزلية للمالك',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 6),
                      const Text(
                        'هذه التعليمات سترفق بملف المريض ويمكن إرسالها للمالك عبر واتساب لضمان التئام الجرح',
                        style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      const SizedBox(height: 14),
                      CustomTextField(
                        label: 'تعليمات الرعاية المنزلية للمالك *',
                        hint: 'إرشادات النظافة، طوق الحماية، التغذية، ومراقبة الجرح...',
                        controller: controller.homeCareInstructionsController,
                        maxLines: 5,
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Card 3: In-Clinic Administered Injections & Treatments
              const ClinicTreatmentsSection(),
              const SizedBox(height: 16),

              // Card 4: Prescribed Home Medications
              const HomePrescriptionsSection(),
              const SizedBox(height: 16),

              // Card 5: Post-Op Follow-up Booking Sub-view
              const SurgeryFollowUpCard(),
              const SizedBox(height: 16),

              // Card 4: Final Cost Settlement & Billing
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Row(
                        children: [
                          Icon(Icons.payments_outlined, color: Colors.teal, size: 20),
                          SizedBox(width: 8),
                          Text('المحاسبة والتسوية المالية للعملية الجراحية',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Obx(() => DropdownButtonFormField<String>(
                            initialValue: controller.selectedPaymentMethod.value,
                            decoration: const InputDecoration(
                              labelText: 'طريقة السداد *',
                              prefixIcon: Icon(Icons.account_balance_wallet_outlined),
                            ),
                            items: AppPaymentMethods.billingOptions.map((opt) {
                              String label = opt;
                              if (opt == AppPaymentMethods.cash) label = 'نقداً (كاش)';
                              if (opt == AppPaymentMethods.deferred) label = 'آجل (ذمم / دفع لاحق)';
                              if (opt == AppPaymentMethods.kuraimi) label = 'بنك الكريمي';
                              if (opt == AppPaymentMethods.jawali) label = 'محفظة جوالي';
                              if (opt == AppPaymentMethods.jeeb) label = 'محفظة جيب';
                              if (opt == AppPaymentMethods.floosak) label = 'محفظة فلوسك';
                              return DropdownMenuItem(value: opt, child: Text(label));
                            }).toList(),
                            onChanged: (val) {
                              if (val != null) controller.setPaymentMethod(val);
                            },
                          )),
                      const SizedBox(height: 12),
                      CustomTextField(
                        label: 'التكلفة الإجمالية للعملية (${AppStringsAr.currencyShort})',
                        hint: '35000',
                        controller: controller.finalCostController,
                        keyboardType: TextInputType.number,
                      ),
                      Obx(() {
                        if (controller.isDeferredPayment) {
                          return const SizedBox.shrink();
                        }
                        return Column(
                          children: [
                            const SizedBox(height: 12),
                            CustomTextField(
                              label: 'المبلغ المسدد الآن (${AppStringsAr.currencyShort})',
                              hint: '35000',
                              controller: controller.paidAmountController,
                              keyboardType: TextInputType.number,
                            ),
                          ],
                        );
                      }),
                      const SizedBox(height: 12),
                      // Live remaining calculation banner for surgery
                      Obx(() {
                        final cost = double.tryParse(controller.finalCostController.text.trim()) ?? 0.0;
                        final remaining = controller.remainingAmount.value;
                        final isDeferred = controller.isDeferredPayment;
                        final paid = isDeferred ? 0.0 : (double.tryParse(controller.paidAmountController.text.trim()) ?? 0.0);
                        final isFullyPaid = !isDeferred && remaining <= 0.001;

                        Color bgColor = isFullyPaid
                            ? AppColors.success.withValues(alpha: 0.1)
                            : (isDeferred || paid <= 0.001 ? Colors.red.shade50 : Colors.amber.shade50);
                        Color borderColor = isFullyPaid
                            ? AppColors.success.withValues(alpha: 0.4)
                            : (isDeferred || paid <= 0.001 ? Colors.red.shade300 : Colors.amber.shade400);
                        Color textColor = isFullyPaid
                            ? AppColors.success
                            : (isDeferred || paid <= 0.001 ? Colors.red.shade800 : Colors.amber.shade900);
                        IconData icon = isFullyPaid
                            ? Icons.check_circle_outline
                            : (isDeferred || paid <= 0.001 ? Icons.pending_actions : Icons.hourglass_bottom);

                        String statusTitle;
                        String statusSubtitle;
                        if (isDeferred) {
                          statusTitle = 'مبلغ آجل بالكامل (${cost.toStringAsFixed(0)} ${AppStringsAr.currencyShort})';
                          statusSubtitle = 'سيتم ترحيل كامل تكلفة العملية كمديونية على حساب العميل';
                        } else if (isFullyPaid) {
                          statusTitle = 'مسدد بالكامل (${paid.toStringAsFixed(0)} ${AppStringsAr.currencyShort})';
                          statusSubtitle = 'لا توجد مبالغ متبقية على هذه العملية';
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
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      );
    });
  }
}
