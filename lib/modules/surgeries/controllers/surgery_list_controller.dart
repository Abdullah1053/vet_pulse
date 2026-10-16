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

  Future<void> deleteSurgery(int id, {int? petId}) async {
    await _surgeryRepo.deleteSurgery(id);
    await loadSurgeries();
    DataSyncService.notifySurgeryChanged(petId: petId);
    if (Get.context != null) {
      Get.snackbar('تم الحذف', 'تم حذف حجز العملية الجراحية بنجاح', backgroundColor: Colors.green.shade100);
    }
  }
}
