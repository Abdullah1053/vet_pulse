import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/follow_up_model.dart';

class SurgeryFollowUpController extends GetxController {
  final RxBool needFollowUp = true.obs;
  final followUpDateController = TextEditingController();
  final followUpTimeController = TextEditingController(text: '10:00 ص');
  final followUpReasonController = TextEditingController(text: 'معاينة التئام الجرح الجراحي وفك الغرز');
  final followUpNotesController = TextEditingController(text: 'إحضار الحيوان لفحص الشفاء وإزالة خيوط الجراحة');

  @override
  void onInit() {
    super.onInit();
    final defaultFollowUp = DateTime.now().add(const Duration(days: 7));
    followUpDateController.text = defaultFollowUp.toIso8601String().substring(0, 10);
  }

  FollowUpModel? buildFollowUp(int petId) {
    if (!needFollowUp.value || followUpDateController.text.trim().isEmpty) {
      return null;
    }
    return FollowUpModel(
      petId: petId,
      scheduledDate: followUpDateController.text.trim(),
      scheduledTime: followUpTimeController.text.trim(),
      reason: followUpReasonController.text.trim(),
      notes: followUpNotesController.text.trim(),
    );
  }

  @override
  void onClose() {
    followUpDateController.dispose();
    followUpTimeController.dispose();
    followUpReasonController.dispose();
    followUpNotesController.dispose();
    super.onClose();
  }
}
