import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/services/data_sync_service.dart';
import '../../../data/models/consultation_model.dart';
import '../../../data/repositories/consultation_repository.dart';
import '../../../data/repositories/pet_repository.dart';

class ConsultationDetailController extends GetxController {
  final ConsultationRepository consultationRepo;
  final PetRepository petRepo;

  ConsultationDetailController({
    ConsultationRepository? consultationRepo,
    PetRepository? petRepo,
  })  : consultationRepo = consultationRepo ?? Get.find<ConsultationRepository>(),
        petRepo = petRepo ?? Get.find<PetRepository>();

  final Rxn<ConsultationModel> consultation = Rxn<ConsultationModel>();
  final RxBool isLoading = true.obs;

  @override
  void onInit() {
    super.onInit();
    loadConsultation();
  }

  Future<void> loadConsultation([ConsultationModel? initial]) async {
    isLoading.value = true;
    try {
      if (initial != null) {
        var item = initial;
        if (item.ownerId == null && item.petId > 0) {
          final pet = await petRepo.getPetById(item.petId);
          if (pet?.ownerId != null) {
            item = item.copyWith(ownerId: pet!.ownerId);
          }
        }
        consultation.value = item;
        return;
      }

      final arg = Get.arguments;
      if (arg is ConsultationModel) {
        var item = arg;
        if (item.ownerId == null && item.petId > 0) {
          final pet = await petRepo.getPetById(item.petId);
          if (pet?.ownerId != null) {
            item = item.copyWith(ownerId: pet!.ownerId);
          }
        }
        consultation.value = item;
      } else if (arg is int) {
        final item = await consultationRepo.getConsultationById(arg);
        consultation.value = item;
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> confirmDelete(BuildContext context) async {
    final item = consultation.value;
    if (item == null || item.id == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: AppColors.critical),
            SizedBox(width: 8),
            Text('حذف الكشف السريري'),
          ],
        ),
        content: const Text(
          'هل أنت متأكد من حذف هذا الكشف السريري بالكامل؟\nسيتم إرجاع كميات الأدوية المصروفة من العيادة إلى مخزون الصيدلية تلقائياً.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text(AppStringsAr.cancel),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.critical,
              foregroundColor: Colors.white,
            ),
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text(AppStringsAr.delete),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await deleteConsultation(item.id!);
      DataSyncService.notifyConsultationChanged(petId: item.petId);
      Get.back();
      Get.snackbar(
        'تم الحذف',
        'تم حذف الكشف السريري وإعادة كميات الأدوية إلى المخزون بنجاح',
        backgroundColor: Colors.green.shade100,
      );
    }
  }

  Future<void> deleteConsultation(int id) async {
    await consultationRepo.deleteConsultation(id);
    if (consultation.value?.id == id) {
      consultation.value = null;
    }
  }
}
