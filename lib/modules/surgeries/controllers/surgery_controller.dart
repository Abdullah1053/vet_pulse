import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/models/surgery_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../data/repositories/surgery_repository.dart';
import '../../../core/services/data_sync_service.dart';

class SurgeryController extends GetxController {
  final SurgeryRepository _surgeryRepo = SurgeryRepository();
  final PetRepository _petRepo = PetRepository();
  final AuthRepository _authRepo = AuthRepository();

  final RxList<SurgeryModel> surgeries = <SurgeryModel>[].obs;
  final RxList<PetModel> pets = <PetModel>[].obs;
  final RxList<UserModel> doctors = <UserModel>[].obs;
  final RxBool isLoading = false.obs;

  // New Surgery Form Controllers
  final Rx<PetModel?> selectedPet = Rx<PetModel?>(null);
  final Rx<UserModel?> selectedSurgeon = Rx<UserModel?>(null);
  final surgeryNameController = TextEditingController();
  final categoryController = TextEditingController(text: AppStringsAr.categoryElective);
  final scheduledDateController = TextEditingController();
  final scheduledTimeController = TextEditingController(text: '09:00 ص');
  final anesthesiaController = TextEditingController(text: 'إيزوفلوران / كيتامين');
  final postOpNotesController = TextEditingController();
  final costController = TextEditingController(text: '350');

  // Pre-op Checklist observables for booking or view
  final RxBool checkFasting = false.obs;
  final RxBool checkBloodWork = false.obs;
  final RxBool checkConsent = false.obs;

  // Edit Mode
  final RxBool isEditing = false.obs;
  final Rx<int?> editingId = Rx<int?>(null);

  @override
  void onInit() {
    super.onInit();
    loadSurgeries();
    loadPetsAndDoctors();
  }

  Future<void> loadPetsAndDoctors() async {
    pets.assignAll(await _petRepo.getAllPets());
    final allUsers = await _authRepo.getAllUsers();
    doctors.assignAll(allUsers.where((u) => u.canPerformSurgeries));
    if (doctors.isNotEmpty && selectedSurgeon.value == null) {
      selectedSurgeon.value = doctors.first;
    }
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

  Future<void> loadPets() async {
    await loadPetsAndDoctors();
  }

  Future<void> toggleChecklist(SurgeryModel surgery) async {
    final nextState = !surgery.preOpChecklistPassed;
    await _surgeryRepo.togglePreOpChecklist(surgery.id!, nextState);
    await loadSurgeries();
    DataSyncService.notifySurgeryChanged(petId: surgery.petId);
    Get.snackbar(
      nextState ? 'تم اجتياز الفحص' : 'تم إلغاء الاعتماد',
      nextState ? 'تم تأكيد اكتمال قائمة التحقق قبل الجراحة' : 'قائمة التحقق معلقة',
      backgroundColor: nextState ? Colors.green.shade100 : Colors.amber.shade100,
    );
  }

  Future<void> updateStatus(int id, String status, {int? petId}) async {
    await _surgeryRepo.updateSurgeryStatus(id, status);
    await loadSurgeries();
    DataSyncService.notifySurgeryChanged(petId: petId);
    Get.snackbar('تم', 'تم تحديث حالة العملية', backgroundColor: Colors.green.shade100);
  }

  Future<void> deleteSurgery(int id, {int? petId}) async {
    await _surgeryRepo.deleteSurgery(id);
    await loadSurgeries();
    DataSyncService.notifySurgeryChanged(petId: petId);
    Get.snackbar('تم الحذف', 'تم حذف حجز العملية الجراحية بنجاح', backgroundColor: Colors.green.shade100);
  }

  void initEditSurgery(SurgeryModel surgery) {
    isEditing.value = true;
    editingId.value = surgery.id;
    if (pets.isNotEmpty) {
      selectedPet.value = pets.firstWhereOrNull((p) => p.id == surgery.petId);
    }
    if (doctors.isNotEmpty) {
      selectedSurgeon.value = doctors.firstWhereOrNull((d) => d.id == surgery.leadSurgeonId);
    }
    surgeryNameController.text = surgery.surgeryName;
    categoryController.text = surgery.surgeryCategory ?? AppStringsAr.categoryElective;

    // Date & Time split
    final parts = surgery.scheduledDate.split(' ');
    if (parts.isNotEmpty) {
      scheduledDateController.text = parts[0];
    }
    if (parts.length > 1) {
      scheduledTimeController.text = parts.sublist(1).join(' ');
    } else {
      scheduledTimeController.text = '09:00 ص';
    }

    anesthesiaController.text = surgery.anesthesiaProtocol ?? '';
    postOpNotesController.text = surgery.postOpNotes ?? '';
    costController.text = (surgery.estimatedCost?.toInt() ?? 15000).toString();

    checkFasting.value = surgery.preOpChecklistPassed;
    checkBloodWork.value = surgery.preOpChecklistPassed;
    checkConsent.value = surgery.preOpChecklistPassed;
  }

  Future<void> saveSurgery() async {
    if (selectedPet.value == null || selectedPet.value!.id == null) {
      Get.snackbar('تنبيه', 'يرجى اختيار المريض أولاً', backgroundColor: Colors.amber.shade100);
      return;
    }

    final name = surgeryNameController.text.trim();
    final date = scheduledDateController.text.trim();

    if (name.isEmpty || date.isEmpty) {
      Get.snackbar('تنبيه', 'اسم العملية وتاريخ الموعد مطلوبان', backgroundColor: Colors.amber.shade100);
      return;
    }

    isLoading.value = true;
    try {
      final fullDateTime = '$date ${scheduledTimeController.text.trim()}';
      final allChecked = checkFasting.value && checkBloodWork.value && checkConsent.value;

      if (isEditing.value && editingId.value != null) {
        final model = SurgeryModel(
          id: editingId.value,
          petId: selectedPet.value!.id!,
          leadSurgeonId: selectedSurgeon.value?.id ?? 1,
          scheduledDate: fullDateTime,
          surgeryName: name,
          surgeryCategory: categoryController.text.trim(),
          preOpChecklistPassed: allChecked,
          anesthesiaProtocol: anesthesiaController.text.trim(),
          postOpNotes: postOpNotesController.text.trim(),
          estimatedCost: double.tryParse(costController.text.trim()) ?? 0.0,
        );
        await _surgeryRepo.updateSurgery(model);
        DataSyncService.notifySurgeryChanged(petId: model.petId);
        Get.back();
        Get.snackbar('نجاح', 'تم تعديل بيانات العملية الجراحية بنجاح', backgroundColor: Colors.green.shade100);
      } else {
        final model = SurgeryModel(
          petId: selectedPet.value!.id!,
          leadSurgeonId: selectedSurgeon.value?.id ?? 1,
          scheduledDate: fullDateTime,
          surgeryName: name,
          surgeryCategory: categoryController.text.trim(),
          preOpChecklistPassed: allChecked,
          anesthesiaProtocol: anesthesiaController.text.trim(),
          postOpNotes: postOpNotesController.text.trim(),
          estimatedCost: double.tryParse(costController.text.trim()) ?? 0.0,
        );

        await _surgeryRepo.insertSurgery(model);
        DataSyncService.notifySurgeryChanged(petId: model.petId);
        Get.back();
        Get.snackbar('نجاح', 'تم حجز موعد العملية الجراحية بنجاح', backgroundColor: Colors.green.shade100);
      }

      clearForm();
      await loadSurgeries();
    } finally {
      isLoading.value = false;
    }
  }

  void clearForm() {
    isEditing.value = false;
    editingId.value = null;
    selectedPet.value = null;
    surgeryNameController.clear();
    scheduledDateController.clear();
    scheduledTimeController.text = '09:00 ص';
    postOpNotesController.clear();
    costController.text = '15000';
    checkFasting.value = false;
    checkBloodWork.value = false;
    checkConsent.value = false;
  }

  @override
  void onClose() {
    surgeryNameController.dispose();
    categoryController.dispose();
    scheduledDateController.dispose();
    scheduledTimeController.dispose();
    anesthesiaController.dispose();
    postOpNotesController.dispose();
    costController.dispose();
    super.onClose();
  }
}
