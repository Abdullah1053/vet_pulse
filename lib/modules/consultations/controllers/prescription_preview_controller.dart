import 'dart:typed_data';
import 'package:flutter/material.dart' show debugPrint;
import 'package:get/get.dart';
import '../../../data/models/clinic_model.dart';
import '../../../data/models/consultation_model.dart';
import '../../../data/models/follow_up_model.dart';
import '../../../data/models/surgery_model.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/consultation_repository.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../data/repositories/surgery_repository.dart';
import '../utils/prescription_pdf_helper.dart';
import 'consultation_controller.dart';
import 'new_consultation_controller.dart';

class PrescriptionPreviewController extends GetxController {
  final SurgeryRepository surgeryRepo;
  final AppointmentRepository appointmentRepo;
  final ConsultationRepository consultationRepo;
  final PetRepository petRepo;

  PrescriptionPreviewController({
    SurgeryRepository? surgeryRepo,
    AppointmentRepository? appointmentRepo,
    ConsultationRepository? consultationRepo,
    PetRepository? petRepo,
  })  : surgeryRepo = surgeryRepo ??
            (Get.isRegistered<SurgeryRepository>()
                ? Get.find<SurgeryRepository>()
                : Get.put(SurgeryRepository(), permanent: true)),
        appointmentRepo = appointmentRepo ??
            (Get.isRegistered<AppointmentRepository>()
                ? Get.find<AppointmentRepository>()
                : Get.put(AppointmentRepository(), permanent: true)),
        consultationRepo = consultationRepo ??
            (Get.isRegistered<ConsultationRepository>()
                ? Get.find<ConsultationRepository>()
                : Get.put(ConsultationRepository(), permanent: true)),
        petRepo = petRepo ??
            (Get.isRegistered<PetRepository>()
                ? Get.find<PetRepository>()
                : Get.put(PetRepository(), permanent: true));

  final Rxn<ConsultationModel> consultation = Rxn<ConsultationModel>();
  final RxBool showCost = true.obs;
  final Rxn<SurgeryModel> scheduledSurgery = Rxn<SurgeryModel>();
  final RxList<FollowUpModel> followUpSessions = <FollowUpModel>[].obs;
  final RxBool isLoading = true.obs;
  final RxInt selectedTabIndex = 0.obs;

  @override
  void onInit() {
    super.onInit();
    loadReportData();
  }

  Future<void> loadReportData() async {
    isLoading.value = true;
    try {
      final args = Get.arguments;

      bool initialShowCost = true;
      if (Get.isRegistered<NewConsultationController>()) {
        initialShowCost = Get.find<NewConsultationController>().showCostInPrescription.value;
      } else if (Get.isRegistered<ConsultationController>()) {
        initialShowCost = Get.find<ConsultationController>().showCostInPrescription.value;
      }

      if (args is Map) {
        if (args['consultation'] is ConsultationModel) {
          consultation.value = args['consultation'] as ConsultationModel;
        }
        if (args['showCost'] is bool) {
          initialShowCost = args['showCost'] as bool;
        }
        if (args['scheduledSurgery'] is SurgeryModel) {
          scheduledSurgery.value = args['scheduledSurgery'] as SurgeryModel;
        }
        if (args['followUpSessions'] is List<FollowUpModel>) {
          followUpSessions.assignAll(args['followUpSessions'] as List<FollowUpModel>);
        }
      } else if (args is ConsultationModel) {
        consultation.value = args;
      } else if (Get.isRegistered<NewConsultationController>() &&
          Get.find<NewConsultationController>().lastCreatedConsultation.value != null) {
        consultation.value = Get.find<NewConsultationController>().lastCreatedConsultation.value;
      } else if (Get.isRegistered<ConsultationController>() &&
          Get.find<ConsultationController>().lastCreatedConsultation.value != null) {
        consultation.value = Get.find<ConsultationController>().lastCreatedConsultation.value;
      }

      showCost.value = initialShowCost;

      final c = consultation.value;
      if (c != null && c.petId > 0) {
        // Query linked surgery if not passed in arguments
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

        // Query linked follow-ups if not passed in arguments
        if (followUpSessions.isEmpty && c.id != null) {
          final followUps = await appointmentRepo.getFollowUpsForPet(c.petId);
          final matchedFollowUps = followUps.where((f) => f.consultationId != null && f.consultationId == c.id).toList();
          if (matchedFollowUps.isNotEmpty) {
            followUpSessions.assignAll(matchedFollowUps);
          }
        }
      }
    } catch (e) {
      debugPrint('Error loading prescription report data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  void toggleShowCost(bool val) {
    showCost.value = val;
    if (Get.isRegistered<ConsultationController>()) {
      Get.find<ConsultationController>().showCostInPrescription.value = val;
    }
    if (Get.isRegistered<NewConsultationController>()) {
      Get.find<NewConsultationController>().showCostInPrescription.value = val;
    }
  }

  void setTabIndex(int idx) {
    selectedTabIndex.value = idx;
  }

  Future<Uint8List> getPdfBytes(ClinicModel? clinic) {
    final c = consultation.value;
    if (c == null) return Future.value(Uint8List(0));
    return PrescriptionPdfHelper.generatePrescriptionPdf(
      consultation: c,
      clinic: clinic,
      showCost: showCost.value,
      scheduledSurgery: scheduledSurgery.value,
      followUpSessions: followUpSessions.toList(),
    );
  }

  Future<void> sharePdf(ClinicModel? clinic) async {
    final c = consultation.value;
    if (c == null) return;
    await PrescriptionPdfHelper.sharePdfFile(
      consultation: c,
      clinic: clinic,
      showCost: showCost.value,
      scheduledSurgery: scheduledSurgery.value,
      followUpSessions: followUpSessions.toList(),
    );
  }

  Future<void> shareWhatsApp(ClinicModel? clinic) async {
    final c = consultation.value;
    if (c == null) return;
    await PrescriptionPdfHelper.shareOnWhatsApp(
      consultation: c,
      clinic: clinic,
      showCost: showCost.value,
      scheduledSurgery: scheduledSurgery.value,
      followUpSessions: followUpSessions.toList(),
    );
  }
}
