import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../data/models/follow_up_model.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/auth_repository.dart';
import '../../../data/repositories/pet_repository.dart';

class FollowUpController extends GetxController {
  final AppointmentRepository _appointmentRepo = AppointmentRepository();
  final PetRepository _petRepo = PetRepository();
  final AuthRepository _authRepo = AuthRepository();

  final RxList<FollowUpModel> followUps = <FollowUpModel>[].obs;
  final RxList<PetModel> pets = <PetModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString currentFilter = 'today'.obs; // overdue, today, upcoming

  // Form Controllers
  final Rx<PetModel?> selectedPet = Rx<PetModel?>(null);
  final scheduledDateController = TextEditingController();
  final scheduledTimeController = TextEditingController(text: '10:00 ص');
  final reasonController = TextEditingController(text: AppStringsAr.reasonRecheck);
  final notesController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadFollowUps();
    loadPets();
  }

  Future<void> loadPets() async {
    pets.assignAll(await _petRepo.getAllPets());
  }

  Future<void> loadFollowUps() async {
    isLoading.value = true;
    try {
      final list = await _appointmentRepo.getFollowUpsByFilter(currentFilter.value);
      followUps.assignAll(list);
    } finally {
      isLoading.value = false;
    }
  }

  void setFilter(String filter) {
    currentFilter.value = filter;
    loadFollowUps();
  }

  Future<void> markStatus(int id, String status) async {
    await _appointmentRepo.updateFollowUpStatus(id, status);
    loadFollowUps();
    Get.snackbar('تم', 'تم تحديث حالة الموعد', backgroundColor: Colors.green.shade100);
  }

  Future<void> sendWhatsAppReminder(FollowUpModel followUp) async {
    if (followUp.ownerPhone == null || followUp.ownerPhone!.isEmpty) {
      Get.snackbar('تنبيه', 'رقم هاتف المالك غير متوفر', backgroundColor: Colors.amber.shade100);
      return;
    }

    final clinic = await _authRepo.getClinicInfo();
    final cleanPhone = followUp.ownerPhone!.replaceAll(RegExp(r'\D'), '');

    final buffer = StringBuffer();
    buffer.writeln('🐾 *تذكير بموعد مراجعة بيطرية*');
    buffer.writeln('من: *${clinic?.clinicName ?? "عيادة بيطرية"}*');
    buffer.writeln('--------------------------------');
    buffer.writeln('عزيزي المربي: نود تذكيركم بموعد مراجعة حيوانكم الأليف *(${followUp.petName ?? "المريض"})*.');
    buffer.writeln('📅 *التاريخ:* ${followUp.scheduledDate}');
    if (followUp.scheduledTime != null) {
      buffer.writeln('⏰ *الوقت:* ${followUp.scheduledTime}');
    }
    buffer.writeln('🩺 *السبب:* ${followUp.reason}');
    if (clinic?.phone != null) {
      buffer.writeln('📞 للاستفسار أو التعديل: ${clinic!.phone}');
    }
    buffer.writeln('نتطلع لرؤيتكم بصحة وعافية.');

    final encoded = Uri.encodeComponent(buffer.toString());
    final uri = Uri.parse('whatsapp://send?phone=$cleanPhone&text=$encoded');

    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
      if (followUp.id != null) {
        await _appointmentRepo.markReminderSent(followUp.id!);
        loadFollowUps();
      }
    } else {
      Get.snackbar('تنبيه', 'تعذر فتح تطبيق واتساب', backgroundColor: Colors.amber.shade100);
    }
  }

  Future<void> scheduleFollowUp() async {
    if (selectedPet.value == null || selectedPet.value!.id == null) {
      Get.snackbar('تنبيه', 'يرجى اختيار المريض أولاً', backgroundColor: Colors.amber.shade100);
      return;
    }

    final date = scheduledDateController.text.trim();
    if (date.isEmpty) {
      Get.snackbar('تنبيه', 'يرجى تحديد تاريخ المراجعة', backgroundColor: Colors.amber.shade100);
      return;
    }

    isLoading.value = true;
    try {
      final model = FollowUpModel(
        petId: selectedPet.value!.id!,
        scheduledDate: date,
        scheduledTime: scheduledTimeController.text.trim(),
        reason: reasonController.text.trim(),
        notes: notesController.text.trim(),
      );

      await _appointmentRepo.insertFollowUp(model);
      clearForm();
      await loadFollowUps();
      Get.back();
      Get.snackbar('تم', 'تمت جدولة موعد المراجعة بنجاح', backgroundColor: Colors.green.shade100);
    } finally {
      isLoading.value = false;
    }
  }

  void clearForm() {
    selectedPet.value = null;
    scheduledDateController.clear();
    notesController.clear();
  }

  @override
  void onClose() {
    scheduledDateController.dispose();
    scheduledTimeController.dispose();
    reasonController.dispose();
    notesController.dispose();
    super.onClose();
  }
}
