import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_payment_methods.dart';
import '../../../data/models/surgery_model.dart';
import '../../../data/repositories/surgery_repository.dart';
import 'surgery_follow_up_controller.dart';

class CompleteSurgeryController extends GetxController {
  final SurgeryRepository _surgeryRepo;

  CompleteSurgeryController(this._surgeryRepo);

  final Rx<SurgeryModel?> surgery = Rx<SurgeryModel?>(null);
  final RxBool isInitialized = false.obs;
  final RxBool isSaving = false.obs;

  // 6 TextEditingControllers for Surgical Outcomes and Billing
  final outcomeNotesController = TextEditingController();
  final recoveryStatusController = TextEditingController(text: 'إفاقة طبيعية ومستقرة، استعادة المنعكسات الحيوية');
  final complicationsController = TextEditingController(text: 'لا توجد مضاعفات جراحية أو تخديرية بحمد الله');
  final homeCareInstructionsController = TextEditingController(
    text: '1. تركيب طوق إليزابيث الواقي (E-Collar) لمنع لعق مكان الجرح.\n2. تطهير موضع الخياطة بمحلول معقم مرتين يومياً.\n3. راحة تامة وعزل في مكان دافئ ومنع القفز والحركة العنيفة لمدة 7 أيام.\n4. تقديم كميات ماء وغذاء قليلة ولينة خلال أول 24 ساعة.',
  );
  final finalCostController = TextEditingController();
  final paidAmountController = TextEditingController();

  final RxString selectedPaymentMethod = AppPaymentMethods.cash.obs;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is SurgeryModel) {
      initSurgery(args);
    }
  }

  void initSurgery(SurgeryModel model) {
    surgery.value = model;
    isInitialized.value = true;
    outcomeNotesController.text = 'تمت العملية الجراحية (${model.surgeryName}) بنجاح تام.';
    final cost = model.estimatedCost ?? 0.0;
    finalCostController.text = cost > 0 ? cost.toStringAsFixed(0) : '';
    paidAmountController.text = cost > 0 ? cost.toStringAsFixed(0) : '';
  }

  Future<void> submitCompletion() async {
    final surg = surgery.value;
    if (surg == null) {
      Get.snackbar('خطأ', 'لم يتم العثور على بيانات العملية الجراحية', backgroundColor: Colors.red.shade100);
      return;
    }

    if (outcomeNotesController.text.trim().isEmpty) {
      Get.snackbar('تنبيه', 'يرجى تسجيل تقرير ونتائج العملية الجراحية', backgroundColor: Colors.amber.shade100);
      return;
    }

    isSaving.value = true;
    try {
      final combinedNotes = StringBuffer();
      combinedNotes.writeln('📋 نتائج العملية:');
      combinedNotes.writeln(outcomeNotesController.text.trim());
      combinedNotes.writeln('\n💉 حالة الإفاقة:');
      combinedNotes.writeln(recoveryStatusController.text.trim());
      if (complicationsController.text.trim().isNotEmpty) {
        combinedNotes.writeln('\n⚠️ الملاحظات والمضاعفات:');
        combinedNotes.writeln(complicationsController.text.trim());
      }
      combinedNotes.writeln('\n🏠 تعليمات الرعاية المنزلية للمالك:');
      combinedNotes.writeln(homeCareInstructionsController.text.trim());

      final finalCost = double.tryParse(finalCostController.text.trim()) ?? surg.estimatedCost ?? 0.0;
      final paidAmount = double.tryParse(paidAmountController.text.trim()) ?? finalCost;

      final updatedSurgery = surg.copyWith(
        status: 'completed',
        postOpNotes: combinedNotes.toString(),
        estimatedCost: finalCost,
      );

      final followUpCtrl = Get.isRegistered<SurgeryFollowUpController>() ? Get.find<SurgeryFollowUpController>() : null;
      final followUp = followUpCtrl?.buildFollowUp(surg.petId);

      await _surgeryRepo.completeSurgeryWithBilling(
        surgery: updatedSurgery,
        finalCost: finalCost,
        paidAmount: paidAmount,
        paymentMethod: selectedPaymentMethod.value,
        followUp: followUp,
      );

      Get.back(result: true);
      Get.snackbar(
        'تم إتمام العملية بنجاح',
        'تم تسجيل تقرير العملية الجراحية وقيد المعاملة المالية${followUp != null ? " وحجز موعد المراجعة" : ""} بنجاح',
        backgroundColor: Colors.green.shade100,
        colorText: Colors.green.shade900,
        icon: const Icon(Icons.check_circle, color: Colors.green),
        duration: const Duration(seconds: 4),
      );
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر حفظ تقرير العملية: $e', backgroundColor: Colors.red.shade100);
    } finally {
      isSaving.value = false;
    }
  }

  @override
  void onClose() {
    outcomeNotesController.dispose();
    recoveryStatusController.dispose();
    complicationsController.dispose();
    homeCareInstructionsController.dispose();
    finalCostController.dispose();
    paidAmountController.dispose();
    super.onClose();
  }
}
