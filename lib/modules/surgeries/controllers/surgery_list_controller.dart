import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/data_sync_service.dart';
import '../../../data/models/surgery_model.dart';
import '../../../data/repositories/surgery_repository.dart';

class SurgeryListController extends GetxController {
  final SurgeryRepository _surgeryRepo;

  SurgeryListController(this._surgeryRepo);

  final RxList<SurgeryModel> surgeries = <SurgeryModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedFilter = 'all'.obs;

  List<SurgeryModel> get filteredSurgeries {
    switch (selectedFilter.value) {
      case 'today':
        return surgeries.where((s) => s.isToday && s.status != 'cancelled').toList();
      case 'overdue':
        return surgeries.where((s) => s.isOverdue).toList();
      case 'upcoming':
        return surgeries.where((s) => s.status == 'scheduled' && !s.isToday && !s.isOverdue).toList();
      case 'all':
      default:
        return surgeries;
    }
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
  }

  @override
  void onInit() {
    super.onInit();
    loadSurgeries();
  }

  Future<void> loadSurgeries() async {
    isLoading.value = true;
    try {
      final list = await _surgeryRepo.getAllSurgeries();
      surgeries.assignAll(list);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> toggleChecklist(SurgeryModel surgery) async {
    final nextState = !surgery.preOpChecklistPassed;
    await _surgeryRepo.togglePreOpChecklist(surgery.id!, nextState);
    await loadSurgeries();
    DataSyncService.notifySurgeryChanged(petId: surgery.petId);
    if (Get.context != null) {
      Get.snackbar(
        nextState ? 'تم اجتياز الفحص' : 'تم إلغاء الاعتماد',
        nextState ? 'تم تأكيد اكتمال قائمة التحقق قبل الجراحة' : 'قائمة التحقق معلقة',
        backgroundColor: nextState ? Colors.green.shade100 : Colors.amber.shade100,
      );
    }
  }

  Future<void> updateStatus(int id, String status, {int? petId}) async {
    await _surgeryRepo.updateSurgeryStatus(id, status);
    await loadSurgeries();
    DataSyncService.notifySurgeryChanged(petId: petId);
    if (Get.context != null) {
      Get.snackbar('تم', 'تم تحديث حالة العملية', backgroundColor: Colors.green.shade100);
    }
  }

  Future<void> cancelSurgery(int id, {String? cancelReason, int? petId}) async {
    await _surgeryRepo.cancelSurgery(id, cancelReason: cancelReason);
    await loadSurgeries();
    DataSyncService.notifySurgeryChanged(petId: petId);
    if (Get.context != null) {
      Get.snackbar(
        'تم الإلغاء',
        'تم إلغاء موعد العملية مع الاحتفاظ بالسجل في التاريخ الطبي',
        backgroundColor: Colors.amber.shade100,
      );
    }
  }

  Future<void> markNoShow(int id, {int? petId}) async {
    await _surgeryRepo.cancelSurgery(
      id,
      cancelReason: '[لم يحضر الموعد] لم يحضر المريض للجراحة في الموعد المحدد',
    );
    await loadSurgeries();
    DataSyncService.notifySurgeryChanged(petId: petId);
    if (Get.context != null) {
      Get.snackbar(
        'تم التسجيل',
        'تم تسجيل عدم حضور المريض بنجاح',
        backgroundColor: Colors.amber.shade100,
      );
    }
  }

  Future<void> deleteSurgery(int id, {int? petId}) async {
    await cancelSurgery(id, cancelReason: 'تم إلغاء الحجز بواسطة الطبيب', petId: petId);
  }
}
