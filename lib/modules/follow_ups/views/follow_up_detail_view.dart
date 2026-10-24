import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_payment_methods.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/follow_up_model.dart';
import '../../../routes/app_routes.dart';
import '../../consultations/widgets/clinic_treatments_section.dart';
import '../controllers/follow_up_detail_controller.dart';

class FollowUpDetailView extends GetView<FollowUpDetailController> {
  const FollowUpDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('تفاصيل وجلسة المراجعة'),
        actions: [
          IconButton(
            icon: const Icon(Icons.print_outlined),
            tooltip: 'طباعة التقرير',
            onPressed: controller.printFollowUpReport,
          ),
          IconButton(
            icon: const Icon(Icons.share_outlined),
            tooltip: 'مشاركة ملف PDF',
            onPressed: controller.sharePdf,
          ),
          IconButton(
            icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
            tooltip: 'مشاركة عبر واتساب',
            onPressed: controller.shareWhatsApp,
          ),
        ],
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final item = controller.followUp.value;
        if (item == null) {
          return const Center(child: Text('لم يتم العثور على بيانات المراجعة'));
        }

        final consult = controller.consultation.value;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Patient & Owner Header Banner
              _buildPatientOwnerBanner(item),
              const SizedBox(height: 14),

              // 2. Current Follow-Up Status Card
              _buildAppointmentStatusCard(item),
              const SizedBox(height: 14),

              // 3. Original Consultation & Treatment Plan Context
              if (consult != null) ...[
                _buildOriginalContextCard(consult),
                const SizedBox(height: 14),
              ],

              // 4. Follow-Up Journey Timeline Card
              _buildJourneyTimelineCard(),
              const SizedBox(height: 14),

              // 5. In-Clinic Treatment & Injections for current session
              if (item.isPending) ...[
                const ClinicTreatmentsSection(),
                const SizedBox(height: 14),

                // Clinical Examination Notes for Today's Visit
                Card(
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.edit_note, color: AppColors.primary, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'ملاحظات الفحص السريري لجلسة اليوم',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 10),
                        CustomTextField(
                          label: 'نتائج الفحص وملاحظات التعافي',
                          hint: 'اكتب ملاحظات فحص المريض وحالته السريرية أثناء جلسة اليوم...',
                          controller: controller.clinicalNotesController,
                          maxLines: 3,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 14),

                // 6. Financial Billing Card
                _buildBillingCard(),
                const SizedBox(height: 14),

                // 7. Schedule Additional Follow-Up Session
                _buildNextFollowUpCard(context),
                const SizedBox(height: 14),
              ] else if (item.isCompleted) ...[
                _buildCompletedSummaryCard(),
                const SizedBox(height: 14),
              ],

              // 8. Rescheduling / Missed Follow-Up Section
              if (item.isMissed || controller.showRescheduleCard.value) ...[
                _buildRescheduleCard(context, item),
                const SizedBox(height: 14),
              ],

              // 9. Bottom Actions
              _buildActionButtons(item),
              const SizedBox(height: 24),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildPatientOwnerBanner(FollowUpModel item) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 24,
                  backgroundColor: AppColors.secondaryLight,
                  child: const Icon(Icons.pets, size: 26, color: AppColors.primary),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${item.petName ?? "المريض"} (${item.petSpecies ?? ""})',
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: AppColors.primaryDark),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'المالك: ${item.ownerName ?? "غير محدد"} - هاتف: ${item.ownerPhone ?? "-"}',
                        style: const TextStyle(fontSize: 12.5, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                TextButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.patientDetail, arguments: item.petId),
                  icon: const Icon(Icons.badge_outlined, size: 16),
                  label: const Text('الملف الطبي للمريض', style: TextStyle(fontSize: 12)),
                ),
                TextButton.icon(
                  onPressed: () => Get.toNamed(AppRoutes.ownerAccountStatement, arguments: item.petId),
                  icon: const Icon(Icons.account_balance_wallet_outlined, size: 16),
                  label: const Text('كشف حساب المالك', style: TextStyle(fontSize: 12)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAppointmentStatusCard(FollowUpModel item) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event, color: AppColors.primary, size: 20),
                    const SizedBox(width: 8),
                    Text(
                      'موعد الجلسة: ${item.scheduledDate}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                StatusChip(
                  label: item.statusDisplayArabic,
                  type: item.isCompleted
                      ? ChipStatusType.success
                      : (item.isMissed || item.isOverdue
                          ? ChipStatusType.critical
                          : (item.isToday ? ChipStatusType.warning : ChipStatusType.info)),
                ),
              ],
            ),
            if (item.scheduledTime != null) ...[
              const SizedBox(height: 6),
              Row(
                children: [
                  const Icon(Icons.access_time, size: 14, color: AppColors.textSecondary),
                  const SizedBox(width: 6),
                  Text('الوقت المجدول: ${item.scheduledTime!}', style: const TextStyle(fontSize: 13)),
                ],
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'السبب: ${item.reason}',
              style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13.5, color: AppColors.darkNeutral),
            ),
            if (item.notes != null && item.notes!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey.shade300),
                ),
                child: Text(
                  item.notes!,
                  style: const TextStyle(fontSize: 12, color: AppColors.textPrimary),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildOriginalContextCard(dynamic consult) {
    return Card(
      color: AppColors.secondaryLight.withValues(alpha: 0.35),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.history_edu, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'سياق الكشف الأصلي وخطة العلاج',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.primaryDark),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text('التشخيص الأساسي: ${consult.diagnosis}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
            if (consult.symptoms?.isNotEmpty == true) ...[
              const SizedBox(height: 4),
              Text('الأعراض والشكوى: ${consult.symptoms}', style: const TextStyle(fontSize: 12, color: AppColors.textSecondary)),
            ],
            if (consult.prescriptions.isNotEmpty) ...[
              const SizedBox(height: 8),
              const Text('العلاجات الموصوفة سابقاً وتتطلب متابعة:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12)),
              const SizedBox(height: 4),
              ...consult.prescriptions.map((p) => Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2.0),
                    child: Row(
                      children: [
                        const Icon(Icons.circle, size: 6, color: AppColors.primary),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            '${p.displayName} (${p.dosage} - ${p.frequency} - ${p.durationDays} يوم)',
                            style: const TextStyle(fontSize: 11.5),
                          ),
                        ),
                      ],
                    ),
                  )),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildJourneyTimelineCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.timeline, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'مسار وسجل جلسات المتابعة (Timeline)',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Text(
                  '${controller.petFollowUps.length} جلسات',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (controller.petFollowUps.isEmpty)
              const Text('لا توجد جلسات أخرى مسجلة', style: TextStyle(fontSize: 12, color: AppColors.textSecondary))
            else
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: controller.petFollowUps.length,
                separatorBuilder: (_, _) => const SizedBox(height: 10),
                itemBuilder: (context, idx) {
                  final s = controller.petFollowUps[idx];
                  final isCurrent = s.id == controller.followUp.value?.id;
                  return Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: isCurrent ? AppColors.primary.withValues(alpha: 0.08) : Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: isCurrent ? AppColors.primary : Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          s.isCompleted
                              ? Icons.check_circle
                              : (s.isMissed ? Icons.cancel : Icons.schedule),
                          size: 18,
                          color: s.isCompleted
                              ? AppColors.success
                              : (s.isMissed ? AppColors.critical : AppColors.primary),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${s.scheduledDate} ${s.scheduledTime ?? ""}: ${s.reason}',
                                style: TextStyle(
                                  fontWeight: isCurrent ? FontWeight.bold : FontWeight.w600,
                                  fontSize: 12,
                                  color: isCurrent ? AppColors.primaryDark : AppColors.textPrimary,
                                ),
                              ),
                              if (s.notes?.isNotEmpty == true)
                                Text(
                                  s.notes!,
                                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                            ],
                          ),
                        ),
                        StatusChip(
                          label: s.statusDisplayArabic,
                          type: s.isCompleted
                              ? ChipStatusType.success
                              : (s.isMissed ? ChipStatusType.critical : ChipStatusType.info),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBillingCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.payments_outlined, color: AppColors.primary, size: 20),
                SizedBox(width: 8),
                Text(
                  'أتعاب المراجعة والتحصيل المالي',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
              ],
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'أتعاب الكشف والعلاجات',
              hint: '0',
              controller: controller.costController,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              prefixIcon: const Icon(Icons.attach_money),
            ),
            const SizedBox(height: 12),
            Obx(() => DropdownButtonFormField<String>(
                  initialValue: controller.selectedPaymentMethod.value,
                  decoration: const InputDecoration(labelText: 'طريقة الدفع'),
                  items: AppPaymentMethods.billingOptions.map((opt) {
                    return DropdownMenuItem(value: opt, child: Text(opt));
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) controller.setPaymentMethod(val);
                  },
                )),
            const SizedBox(height: 12),
            Obx(() {
              if (controller.isDeferred) {
                return Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: const Text(
                    'تم اختيار الدفع الآجل (ذمم مدينة) - سيتم ترحيل كامل المبلغ إلى حساب العميل',
                    style: TextStyle(fontSize: 12, color: Colors.brown, fontWeight: FontWeight.bold),
                  ),
                );
              }
              return CustomTextField(
                label: 'المبلغ المدفوع الآن',
                hint: '0',
                controller: controller.paidAmountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                prefixIcon: const Icon(Icons.price_check),
              );
            }),
            const SizedBox(height: 10),
            Obx(() => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('المبلغ المتبقي ديناً:', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                    Text(
                      '${controller.remainingAmount.value.toStringAsFixed(0)} ${AppStringsAr.currencyShort}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: controller.remainingAmount.value > 0 ? AppColors.critical : AppColors.success,
                      ),
                    ),
                  ],
                )),
          ],
        ),
      ),
    );
  }

  Widget _buildNextFollowUpCard(BuildContext context) {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Row(
                  children: [
                    Icon(Icons.event_repeat, color: AppColors.primary, size: 20),
                    SizedBox(width: 8),
                    Text(
                      'جدولة موعد مراجعة إضافي لاحق',
                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                    ),
                  ],
                ),
                Obx(() => Switch.adaptive(
                      value: controller.scheduleNextFollowUp.value,
                      activeTrackColor: AppColors.primary,
                      onChanged: (v) => controller.scheduleNextFollowUp.value = v,
                    )),
              ],
            ),
            Obx(() {
              if (!controller.scheduleNextFollowUp.value) return const SizedBox.shrink();
              return Column(
                children: [
                  const SizedBox(height: 12),
                  CustomTextField(
                    label: 'تاريخ المراجعة القادمة',
                    hint: 'YYYY-MM-DD',
                    controller: controller.nextDateController,
                    readOnly: true,
                    prefixIcon: const Icon(Icons.calendar_today),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now().add(const Duration(days: 3)),
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) {
                        controller.nextDateController.text = picked.toIso8601String().substring(0, 10);
                      }
                    },
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    label: 'الوقت المحدد',
                    hint: '10:00 ص',
                    controller: controller.nextTimeController,
                    prefixIcon: const Icon(Icons.access_time),
                  ),
                  const SizedBox(height: 10),
                  CustomTextField(
                    label: 'سبب المراجعة الإضافية',
                    hint: 'فك غرز / فحص بعد العلاج',
                    controller: controller.nextReasonController,
                  ),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildCompletedSummaryCard() {
    final fin = controller.financialSummary.value;
    return Card(
      color: Colors.green.shade50.withValues(alpha: 0.6),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.green.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade800, size: 22),
                const SizedBox(width: 8),
                Text(
                  'تمت المراجعة بنجاح',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.green.shade900),
                ),
              ],
            ),
            if (fin != null && (fin['totalCost'] ?? 0) > 0) ...[
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('التكلفة: ${(fin["totalCost"] as num).toStringAsFixed(0)} ${AppStringsAr.currencyShort}', style: const TextStyle(fontWeight: FontWeight.w600)),
                  Text('المدفوع: ${(fin["paidAmount"] as num).toStringAsFixed(0)} ${AppStringsAr.currencyShort}'),
                  Text(
                    'المتبقي: ${(fin["remainingAmount"] as num).toStringAsFixed(0)} ${AppStringsAr.currencyShort}',
                    style: TextStyle(fontWeight: FontWeight.bold, color: (fin['remainingAmount'] ?? 0) > 0 ? AppColors.critical : AppColors.success),
                  ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.printFollowUpReport,
                    icon: const Icon(Icons.print, size: 16),
                    label: const Text('طباعة التقرير (PDF)', style: TextStyle(fontSize: 12)),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF25D366), foregroundColor: Colors.white),
                    onPressed: controller.shareWhatsApp,
                    icon: const Icon(Icons.chat, size: 16),
                    label: const Text('مشاركة واتساب', style: TextStyle(fontSize: 12)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRescheduleCard(BuildContext context, FollowUpModel item) {
    return Card(
      color: Colors.orange.shade50.withValues(alpha: 0.7),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.orange.shade300),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.event_repeat, color: Colors.orange.shade900, size: 22),
                const SizedBox(width: 8),
                Text(
                  'استئناف / إعادة جدولة خطة المتابعة',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14.5, color: Colors.orange.shade900),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'يمكنك إعادة استئناف سلسلة المتابعة وتحديد تاريخ بدء جديد وعدد الجلسات مع الاحتفاظ بالسجل السابق للموعد الفائت.',
              style: TextStyle(fontSize: 12, color: AppColors.textSecondary),
            ),
            const SizedBox(height: 12),
            CustomTextField(
              label: 'تاريخ البدء الجديد',
              hint: 'YYYY-MM-DD',
              controller: controller.newStartDateController,
              readOnly: true,
              prefixIcon: const Icon(Icons.calendar_today),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime.now().subtract(const Duration(days: 7)),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) {
                  controller.newStartDateController.text = picked.toIso8601String().substring(0, 10);
                }
              },
            ),
            const SizedBox(height: 10),
            CustomTextField(
              label: 'الوقت المحدد',
              hint: '10:00 ص',
              controller: controller.newTimeController,
              prefixIcon: const Icon(Icons.access_time),
            ),
            const SizedBox(height: 10),
            CustomTextField(
              label: 'عدد الجلسات / الأيام المتتالية',
              hint: 'مثال: 3',
              controller: controller.newDaysCountController,
              keyboardType: TextInputType.number,
              prefixIcon: const Icon(Icons.repeat),
            ),
            const SizedBox(height: 12),
            PrimaryButton(
              text: 'تأكيد استئناف وجدولة الجلسات الجديدة',
              icon: Icons.check,
              isLoading: controller.isSubmitting.value,
              onPressed: controller.submitReschedule,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons(FollowUpModel item) {
    if (item.isPending) {
      return Column(
        children: [
          PrimaryButton(
            text: 'إتمام المراجعة وحفظ العلاجات',
            icon: Icons.check_circle_outline,
            isLoading: controller.isSubmitting.value,
            onPressed: controller.completeFollowUp,
          ),
          const SizedBox(height: 10),
          OutlinedButton.icon(
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.critical,
              side: const BorderSide(color: AppColors.critical),
              minimumSize: const Size.fromHeight(48),
            ),
            onPressed: controller.markAsMissed,
            icon: const Icon(Icons.cancel_outlined, size: 18),
            label: const Text('تسجيل عدم حضور المريض (فائتة / لم يحضر)', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      );
    } else if (item.isMissed && !controller.showRescheduleCard.value) {
      return ElevatedButton.icon(
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.orange.shade800,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
        ),
        onPressed: () => controller.showRescheduleCard.value = true,
        icon: const Icon(Icons.event_repeat),
        label: const Text('استئناف / إعادة جدولة خطة المتابعة', style: TextStyle(fontWeight: FontWeight.bold)),
      );
    }
    return const SizedBox.shrink();
  }
}
