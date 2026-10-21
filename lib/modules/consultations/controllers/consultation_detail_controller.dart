import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/services/data_sync_service.dart';
import '../../../data/models/consultation_model.dart';
import '../../../data/models/follow_up_model.dart';
import '../../../data/models/surgery_model.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/consultation_repository.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../data/repositories/surgery_repository.dart';

class ConsultationDetailController extends GetxController {
  final ConsultationRepository consultationRepo;
  final PetRepository petRepo;
  final SurgeryRepository surgeryRepo;
  final AppointmentRepository appointmentRepo;

  ConsultationDetailController({
    ConsultationRepository? consultationRepo,
    PetRepository? petRepo,
    SurgeryRepository? surgeryRepo,
    AppointmentRepository? appointmentRepo,
  })  : consultationRepo = consultationRepo ??
            (Get.isRegistered<ConsultationRepository>()
                ? Get.find<ConsultationRepository>()
                : Get.put(ConsultationRepository(), permanent: true)),
        petRepo = petRepo ??
            (Get.isRegistered<PetRepository>()
                ? Get.find<PetRepository>()
                : Get.put(PetRepository(), permanent: true)),
        surgeryRepo = surgeryRepo ??
            (Get.isRegistered<SurgeryRepository>()
                ? Get.find<SurgeryRepository>()
                : Get.put(SurgeryRepository(), permanent: true)),
        appointmentRepo = appointmentRepo ??
            (Get.isRegistered<AppointmentRepository>()
                ? Get.find<AppointmentRepository>()
                : Get.put(AppointmentRepository(), permanent: true));

  final Rxn<ConsultationModel> consultation = Rxn<ConsultationModel>();
  final Rxn<SurgeryModel> scheduledSurgery = Rxn<SurgeryModel>();
  final RxList<FollowUpModel> followUpSessions = <FollowUpModel>[].obs;
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
        await _loadLinkedSurgeryAndFollowUps(item);
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
        await _loadLinkedSurgeryAndFollowUps(item);
      } else if (arg is Map && arg['consultation'] is ConsultationModel) {
        var item = arg['consultation'] as ConsultationModel;
        if (item.ownerId == null && item.petId > 0) {
          final pet = await petRepo.getPetById(item.petId);
          if (pet?.ownerId != null) {
            item = item.copyWith(ownerId: pet!.ownerId);
          }
        }
        consultation.value = item;
        if (arg['scheduledSurgery'] is SurgeryModel) {
          scheduledSurgery.value = arg['scheduledSurgery'] as SurgeryModel;
        }
        if (arg['followUpSessions'] is List<FollowUpModel>) {
          followUpSessions.assignAll(arg['followUpSessions'] as List<FollowUpModel>);
        }
        await _loadLinkedSurgeryAndFollowUps(item);
      } else if (arg is int) {
        final item = await consultationRepo.getConsultationById(arg);
        consultation.value = item;
        if (item != null) {
          await _loadLinkedSurgeryAndFollowUps(item);
        }
      }
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> _loadLinkedSurgeryAndFollowUps(ConsultationModel c) async {
    try {
      if (c.petId > 0) {
        if (scheduledSurgery.value == null) {
          final surgeries = await surgeryRepo.getSurgeriesForPet(c.petId);
          final datePrefix = c.visitDate.length >= 10 ? c.visitDate.substring(0, 10) : c.visitDate;
          final matched = surgeries.where((s) => s.scheduledDate.contains(datePrefix)).toList();
          if (matched.isNotEmpty) {
            scheduledSurgery.value = matched.first;
          } else {
            scheduledSurgery.value = surgeries.firstWhereOrNull((s) => s.status == 'scheduled');
          }
        }

        if (followUpSessions.isEmpty && c.id != null) {
          final followUps = await appointmentRepo.getFollowUpsForPet(c.petId);
          final matchedFollowUps = followUps.where((f) => f.consultationId != null && f.consultationId == c.id).toList();
          if (matchedFollowUps.isNotEmpty) {
            followUpSessions.assignAll(matchedFollowUps);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading linked surgery and follow-ups in detail: $e');
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
