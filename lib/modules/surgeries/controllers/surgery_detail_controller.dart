import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/data_sync_service.dart';
import '../../../data/models/clinic_model.dart';
import '../../../data/models/follow_up_model.dart';
import '../../../data/models/surgery_model.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/surgery_repository.dart';
import '../../../routes/app_routes.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/surgery_form_controller.dart';
import '../utils/surgery_pdf_helper.dart';

class SurgeryDetailController extends GetxController {
  final SurgeryRepository _surgeryRepo;
  final AppointmentRepository _appointmentRepo;

  SurgeryDetailController({
    SurgeryRepository? surgeryRepo,
    AppointmentRepository? appointmentRepo,
  })  : _surgeryRepo = surgeryRepo ??
            (Get.isRegistered<SurgeryRepository>()
                ? Get.find<SurgeryRepository>()
                : Get.put(SurgeryRepository(), permanent: true)),
        _appointmentRepo = appointmentRepo ??
            (Get.isRegistered<AppointmentRepository>()
                ? Get.find<AppointmentRepository>()
                : Get.put(AppointmentRepository(), permanent: true));

  final Rxn<SurgeryModel> surgery = Rxn<SurgeryModel>();
  final RxBool isLoading = false.obs;
  final Rxn<Map<String, dynamic>> financialSummary = Rxn<Map<String, dynamic>>();
  final RxList<FollowUpModel> followUps = <FollowUpModel>[].obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is SurgeryModel) {
      surgery.value = args;
      loadAdditionalData(args.id);
    } else if (args is int) {
      loadSurgeryById(args);
    }
  }

  Future<void> loadSurgeryById(int id) async {
    isLoading.value = true;
    try {
      final s = await _surgeryRepo.getSurgeryById(id);
      surgery.value = s;
      await loadAdditionalData(id);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> loadAdditionalData(int? surgeryId) async {
    if (surgeryId == null) return;
    try {
      final s = surgery.value;
      if (s != null && s.petId > 0) {
        final allFollowUps = await _appointmentRepo.getFollowUpsForPet(s.petId);
        followUps.assignAll(allFollowUps);
      }
      final fin = await _surgeryRepo.getSurgeryFinancialSummary(surgeryId);
      financialSummary.value = fin;
    } catch (e) {
      debugPrint('[SurgeryDetailController] Error loading additional data: $e');
    }
  }

  Future<void> reload() async {
    final s = surgery.value;
    if (s?.id != null) {
      final updated = await _surgeryRepo.getSurgeryById(s!.id!);
      if (updated != null) {
        surgery.value = updated;
      }
      await loadAdditionalData(s.id);
    }
  }

  Future<void> togglePreOpChecklist() async {
    final s = surgery.value;
    if (s?.id == null) return;
    final nextState = !s!.preOpChecklistPassed;
    await _surgeryRepo.togglePreOpChecklist(s.id!, nextState);
    surgery.value = s.copyWith(preOpChecklistPassed: nextState);
    DataSyncService.notifySurgeryChanged(petId: s.petId);
    if (Get.context != null) {
      Get.snackbar(
        nextState ? 'تم اعتماد المعايير' : 'تم إلغاء الاعتماد',
        nextState ? 'تم استيفاء معايير الأمان قبل الجراحة' : 'معايير ما قبل الجراحة معلقة',
        backgroundColor: nextState ? Colors.green.shade100 : Colors.amber.shade100,
      );
    }
  }

  Future<void> startSurgery() async {
    final s = surgery.value;
    if (s?.id == null) return;
    await _surgeryRepo.updateSurgeryStatus(s!.id!, 'in_progress');
    surgery.value = s.copyWith(status: 'in_progress');
    DataSyncService.notifySurgeryChanged(petId: s.petId);
    if (Get.context != null) {
      Get.snackbar('بدء العملية', 'تم تغيير حالة العملية إلى: جارية الآن', backgroundColor: Colors.blue.shade100);
    }
  }

  Future<void> markNoShow() async {
    final s = surgery.value;
    if (s?.id == null) return;
    const note = '[لم يحضر الموعد] لم يحضر المريض للجراحة في الموعد المحدد';
    await _surgeryRepo.cancelSurgery(s!.id!, cancelReason: note);
    surgery.value = s.copyWith(
      status: 'cancelled',
      postOpNotes: s.postOpNotes != null && s.postOpNotes!.isNotEmpty
          ? '$note\n${s.postOpNotes}'
          : note,
    );
    DataSyncService.notifySurgeryChanged(petId: s.petId);
    if (Get.context != null) {
      Get.snackbar('تم التسجيل', 'تم تسجيل عدم حضور المريض بنجاح', backgroundColor: Colors.amber.shade100);
    }
  }

  Future<void> cancelSurgery(String reason) async {
    final s = surgery.value;
    if (s?.id == null) return;
    await _surgeryRepo.cancelSurgery(s!.id!, cancelReason: reason);
    surgery.value = s.copyWith(
      status: 'cancelled',
      postOpNotes: s.postOpNotes != null && s.postOpNotes!.isNotEmpty
          ? '$reason\n${s.postOpNotes}'
          : reason,
    );
    DataSyncService.notifySurgeryChanged(petId: s.petId);
    if (Get.context != null) {
      Get.snackbar('تم الإلغاء', 'تم إلغاء العملية الجراحية مع حفظ السجل', backgroundColor: Colors.amber.shade100);
    }
  }

  void navigateToEdit() {
    final s = surgery.value;
    if (s == null) return;
    if (Get.isRegistered<AuthController>() &&
        !Get.find<AuthController>().checkPermission((u) => u.canPerformSurgeries, 'تعديل العملية متاح للأطباء فقط')) {
      return;
    }
    if (Get.isRegistered<SurgeryFormController>()) {
      Get.find<SurgeryFormController>().initEditSurgery(s);
    }
    Get.toNamed(AppRoutes.newSurgery)?.then((_) => reload());
  }

  void navigateToComplete() {
    final s = surgery.value;
    if (s == null) return;
    if (Get.isRegistered<AuthController>() &&
        !Get.find<AuthController>().checkPermission((u) => u.canPerformSurgeries, 'إتمام العملية متاح للأطباء فقط')) {
      return;
    }
    Get.toNamed(AppRoutes.completeSurgery, arguments: s)?.then((res) {
      if (res == true) reload();
    });
  }

  ClinicModel? get _clinic =>
      Get.isRegistered<AuthController>() ? Get.find<AuthController>().clinicInfo.value : null;

  Future<void> printReport() async {
    final s = surgery.value;
    if (s == null) return;
    await SurgeryPdfHelper.printSurgeryPdf(
      surgery: s,
      clinic: _clinic,
      followUp: followUps.isNotEmpty ? followUps.first : null,
      financialSummary: financialSummary.value,
    );
  }

  Future<void> shareReportPdf() async {
    final s = surgery.value;
    if (s == null) return;
    await SurgeryPdfHelper.shareSurgeryPdfFile(
      surgery: s,
      clinic: _clinic,
      followUp: followUps.isNotEmpty ? followUps.first : null,
      financialSummary: financialSummary.value,
    );
  }

  Future<void> shareOnWhatsApp() async {
    final s = surgery.value;
    if (s == null) return;
    await SurgeryPdfHelper.shareSurgeryOnWhatsApp(
      surgery: s,
      clinic: _clinic,
      followUp: followUps.isNotEmpty ? followUps.first : null,
      financialSummary: financialSummary.value,
    );
  }
}
