import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_payment_methods.dart';
import '../../../data/models/clinic_model.dart';
import '../../../data/models/consultation_model.dart';
import '../../../data/models/follow_up_model.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/consultation_repository.dart';
import '../../../data/repositories/inventory_repository.dart';
import '../../consultations/controllers/prescription_item_controller.dart';
import '../utils/follow_up_pdf_helper.dart';

class FollowUpDetailController extends GetxController {
  final AppointmentRepository _appointmentRepo;
  final ConsultationRepository _consultationRepo;
  final InventoryRepository _inventoryRepo;
  final AuthRepository _authRepo;

  FollowUpDetailController({
    AppointmentRepository? appointmentRepo,
    ConsultationRepository? consultationRepo,
    InventoryRepository? inventoryRepo,
    AuthRepository? authRepo,
  })  : _appointmentRepo = appointmentRepo ??
            (Get.isRegistered<AppointmentRepository>()
                ? Get.find<AppointmentRepository>()
                : Get.put(AppointmentRepository(), permanent: true)),
        _consultationRepo = consultationRepo ??
            (Get.isRegistered<ConsultationRepository>()
                ? Get.find<ConsultationRepository>()
                : Get.put(ConsultationRepository(), permanent: true)),
        _inventoryRepo = inventoryRepo ??
            (Get.isRegistered<InventoryRepository>()
                ? Get.find<InventoryRepository>()
                : Get.put(InventoryRepository(), permanent: true)),
        _authRepo = authRepo ??
            (Get.isRegistered<AuthRepository>()
                ? Get.find<AuthRepository>()
                : Get.put(AuthRepository(), permanent: true));

  // Prescription Item Controller for selecting clinic treatments/injections
  late final PrescriptionItemController prescriptionItemController;

  final Rxn<FollowUpModel> followUp = Rxn<FollowUpModel>();
  final Rxn<ConsultationModel> consultation = Rxn<ConsultationModel>();
  final RxList<FollowUpModel> petFollowUps = <FollowUpModel>[].obs;
  final Rxn<Map<String, dynamic>> financialSummary = Rxn<Map<String, dynamic>>();
  final Rxn<ClinicModel> clinicInfo = Rxn<ClinicModel>();

  final RxBool isLoading = true.obs;
  final RxBool isSubmitting = false.obs;

  // Follow-up Examination & Notes
  final clinicalNotesController = TextEditingController();

  // Financial Billing
  final costController = TextEditingController();
  final paidAmountController = TextEditingController();
  final RxString selectedPaymentMethod = AppPaymentMethods.cash.obs;
  final RxDouble remainingAmount = 0.0.obs;

  bool get isDeferred => selectedPaymentMethod.value == AppPaymentMethods.deferred;

  // Next Follow-Up Option
  final RxBool scheduleNextFollowUp = false.obs;
  final nextDateController = TextEditingController();
  final nextTimeController = TextEditingController(text: '10:00 ص');
  final nextReasonController = TextEditingController(text: 'متابعة الحالة السريرية');
  final nextNotesController = TextEditingController();

  // Missed Follow-Up / Reschedule Series
  final RxBool showRescheduleCard = false.obs;
  final newStartDateController = TextEditingController();
  final newTimeController = TextEditingController(text: '10:00 ص');
  final newDaysCountController = TextEditingController(text: '3');

  @override
  void onInit() {
    super.onInit();
    prescriptionItemController = Get.isRegistered<PrescriptionItemController>()
        ? Get.find<PrescriptionItemController>()
        : Get.put(PrescriptionItemController(inventoryRepo: _inventoryRepo));

    costController.addListener(calculateRemaining);
    paidAmountController.addListener(calculateRemaining);

    // Default next follow-up date to 3 days from today
    nextDateController.text = DateTime.now().add(const Duration(days: 3)).toIso8601String().substring(0, 10);
    newStartDateController.text = DateTime.now().toIso8601String().substring(0, 10);

    loadData();
  }

  Future<void> loadData() async {
    isLoading.value = true;
    try {
      clinicInfo.value = await _authRepo.getClinicInfo();

      final args = Get.arguments;
      if (args is FollowUpModel) {
        followUp.value = args;
      } else if (args is int) {
        followUp.value = await _appointmentRepo.getFollowUpById(args);
      } else if (Get.parameters['id'] != null) {
        final id = int.tryParse(Get.parameters['id']!);
        if (id != null) {
          followUp.value = await _appointmentRepo.getFollowUpById(id);
        }
      }

      final current = followUp.value;
      if (current != null) {
        // Load original consultation
        if (current.consultationId != null) {
          consultation.value = await _consultationRepo.getConsultationById(current.consultationId!);
        } else {
          final consults = await _consultationRepo.getConsultationsForPet(current.petId);
          if (consults.isNotEmpty) {
            consultation.value = consults.first;
          }
        }

        // Load all follow-up history for timeline
        petFollowUps.assignAll(await _appointmentRepo.getFollowUpsForPet(current.petId));

        // Load financial summary if completed
        if (current.id != null) {
          financialSummary.value = await _appointmentRepo.getFollowUpFinancialSummary(current.id!);
        }
      }
    } catch (e) {
      debugPrint('[FollowUpDetailController] loadData error: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void calculateRemaining() {
    final cost = double.tryParse(costController.text.trim()) ?? 0.0;
    if (isDeferred) {
      paidAmountController.text = '0';
      remainingAmount.value = cost;
      return;
    }
    final paid = double.tryParse(paidAmountController.text.trim()) ?? 0.0;
    remainingAmount.value = (cost - paid).clamp(0.0, double.infinity);
  }

  void setPaymentMethod(String method) {
    selectedPaymentMethod.value = method;
    calculateRemaining();
  }

  Future<void> completeFollowUp() async {
    final current = followUp.value;
    if (current == null) return;

    final cost = double.tryParse(costController.text.trim()) ?? 0.0;
    final paid = isDeferred ? 0.0 : (double.tryParse(paidAmountController.text.trim()) ?? 0.0);
    final remaining = isDeferred ? cost : remainingAmount.value;

    FollowUpModel? next;
    if (scheduleNextFollowUp.value && nextDateController.text.trim().isNotEmpty) {
      next = FollowUpModel(
        petId: current.petId,
        consultationId: current.consultationId,
        scheduledDate: nextDateController.text.trim(),
        scheduledTime: nextTimeController.text.trim().isNotEmpty ? nextTimeController.text.trim() : null,
        reason: nextReasonController.text.trim().isNotEmpty ? nextReasonController.text.trim() : 'متابعة لاحقة',
        notes: nextNotesController.text.trim().isNotEmpty ? nextNotesController.text.trim() : null,
        status: 'pending',
      );
    }

    isSubmitting.value = true;
    try {
      await _appointmentRepo.completeFollowUpWithTreatment(
        followUp: current,
        clinicalNotes: clinicalNotesController.text.trim(),
        administeredTreatments: prescriptionItemController.clinicTreatments.toList(),
        followUpCost: cost,
        paidAmount: paid,
        remainingAmount: remaining,
        paymentMethod: selectedPaymentMethod.value,
        nextFollowUp: next,
      );

      Get.snackbar(
        'تم بنجاح',
        'تم تسجيل إتمام المراجعة وخصم العلاجات من المخزن وتسجيل المعاملة المالية',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
        duration: const Duration(seconds: 3),
      );

      await loadData();
    } catch (e) {
      debugPrint('[FollowUpDetailController] completeFollowUp error: $e');
      Get.snackbar('خطأ', 'حدث خطأ أثناء حفظ المراجعة: $e', backgroundColor: Colors.red.shade100);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> markAsMissed() async {
    final current = followUp.value;
    if (current == null || current.id == null) return;

    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange),
            SizedBox(width: 8),
            Text('تسجيل عدم حضور المريض'),
          ],
        ),
        content: Text('هل ترغب في تسجيل عدم حضور المريض لموعد المراجعة بتاريخ (${current.scheduledDate}) كفائتة؟'),
        actions: [
          TextButton(onPressed: () => Get.back(result: false), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.orange, foregroundColor: Colors.white),
            onPressed: () => Get.back(result: true),
            child: const Text('تأكيد عدم الحضور'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      isSubmitting.value = true;
      try {
        await _appointmentRepo.markFollowUpMissed(
          current.id!,
          missedNote: 'تغيب عن الحضور في $todayStr',
        );
        Get.snackbar(
          'تم التسجيل',
          'تم تسجيل الموعد كفائت مع الاحتفاظ بالسجل في التاريخ الطبي للمريض',
          backgroundColor: Colors.orange.shade100,
        );
        showRescheduleCard.value = true;
        await loadData();
      } finally {
        isSubmitting.value = false;
      }
    }
  }

  Future<void> submitReschedule() async {
    final current = followUp.value;
    if (current == null) return;

    final startDate = newStartDateController.text.trim();
    if (startDate.isEmpty) {
      Get.snackbar('تنبيه', 'يرجى تحديد تاريخ البدء الجديد', backgroundColor: Colors.amber.shade100);
      return;
    }

    final days = int.tryParse(newDaysCountController.text.trim()) ?? 1;
    if (days < 1) {
      Get.snackbar('تنبيه', 'يرجى إدخال عدد أيام صالح', backgroundColor: Colors.amber.shade100);
      return;
    }

    isSubmitting.value = true;
    try {
      await _appointmentRepo.resumeFollowUpSchedule(
        missedFollowUp: current,
        newStartDate: startDate,
        scheduledTime: newTimeController.text.trim(),
        newDaysCount: days,
      );

      Get.snackbar(
        'تم الاستئناف بنجاح',
        'تمت إعادة جدولة خطة المتابعة ($days جلسات) بدءاً من $startDate',
        backgroundColor: Colors.green.shade100,
      );
      showRescheduleCard.value = false;
      await loadData();
    } catch (e) {
      debugPrint('[FollowUpDetailController] submitReschedule error: $e');
      Get.snackbar('خطأ', 'تعذر استئناف الجدولة: $e', backgroundColor: Colors.red.shade100);
    } finally {
      isSubmitting.value = false;
    }
  }

  Future<void> printFollowUpReport() async {
    final current = followUp.value;
    if (current == null) return;
    await FollowUpPdfHelper.printFollowUpReport(
      followUp: current,
      clinic: clinicInfo.value,
      clinicalNotes: clinicalNotesController.text.trim(),
      administeredTreatments: prescriptionItemController.clinicTreatments.toList(),
      financialSummary: financialSummary.value,
    );
  }

  Future<void> sharePdf() async {
    final current = followUp.value;
    if (current == null) return;
    await FollowUpPdfHelper.sharePdf(
      followUp: current,
      clinic: clinicInfo.value,
      clinicalNotes: clinicalNotesController.text.trim(),
      administeredTreatments: prescriptionItemController.clinicTreatments.toList(),
      financialSummary: financialSummary.value,
    );
  }

  Future<void> shareWhatsApp() async {
    final current = followUp.value;
    if (current == null) return;
    await FollowUpPdfHelper.shareViaWhatsApp(
      followUp: current,
      clinic: clinicInfo.value,
      clinicalNotes: clinicalNotesController.text.trim(),
      administeredTreatments: prescriptionItemController.clinicTreatments.toList(),
    );
  }

  @override
  void onClose() {
    costController.removeListener(calculateRemaining);
    paidAmountController.removeListener(calculateRemaining);
    clinicalNotesController.dispose();
    costController.dispose();
    paidAmountController.dispose();
    nextDateController.dispose();
    nextTimeController.dispose();
    nextReasonController.dispose();
    nextNotesController.dispose();
    newStartDateController.dispose();
    newTimeController.dispose();
    newDaysCountController.dispose();
    super.onClose();
  }
}
