import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/models/surgery_model.dart';
import '../../../data/models/user_model.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../data/repositories/surgery_repository.dart';

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
    if (doctors.isNotEmpty) {
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

  Future<void> toggleChecklist(SurgeryModel surgery) async {
    final nextState = !surgery.preOpChecklistPassed;
    await _surgeryRepo.togglePreOpChecklist(surgery.id!, nextState);
    loadSurgeries();
    Get.snackbar(
      nextState ? 'تم اجتياز الفحص' : 'تم إلغاء الاعتماد',
      nextState ? 'تم تأكيد اكتمال قائمة التحقق قبل الجراحة' : 'قائمة التحقق معلقة',
      backgroundColor: nextState ? Colors.green.shade100 : Colors.amber.shade100,
    );
  }

  Future<void> updateStatus(int id, String status) async {
    await _surgeryRepo.updateSurgeryStatus(id, status);
    loadSurgeries();
    Get.snackbar('تم', 'تم تحديث حالة العملية', backgroundColor: Colors.green.shade100);
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
      clearForm();
      await loadSurgeries();
      Get.back();
      Get.snackbar('نجاح', 'تم حجز موعد العملية الجراحية بنجاح', backgroundColor: Colors.green.shade100);
    } finally {
      isLoading.value = false;
    }
  }

  void clearForm() {
    selectedPet.value = null;
    surgeryNameController.clear();
    scheduledDateController.clear();
    postOpNotesController.clear();
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
