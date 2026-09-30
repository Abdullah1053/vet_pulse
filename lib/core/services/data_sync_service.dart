import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../modules/dashboard/controllers/dashboard_controller.dart';
import '../../modules/dashboard/services/alerts_service.dart';
import '../../modules/patients/controllers/patient_controller.dart';
import '../../modules/consultations/controllers/consultations_list_controller.dart';
import '../../modules/surgeries/controllers/surgery_controller.dart';
import '../../modules/follow_ups/controllers/follow_up_controller.dart';
import '../../modules/pharmacy/controllers/pharmacy_controller.dart';

/// Central reactive data synchronizer that ensures all screens, cards,
/// badges, and lists update immediately across the app without manual refresh.
class DataSyncService {
  static void notifyAllChanged() {
    debugPrint('[DataSyncService] notifyAllChanged');
    if (Get.isRegistered<ConsultationsListController>()) {
      Get.find<ConsultationsListController>().loadConsultations();
    }
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().loadDashboardData();
    }
    if (Get.isRegistered<PharmacyController>()) {
      Get.find<PharmacyController>().loadMedicines();
    }
    if (Get.isRegistered<SurgeryController>()) {
      Get.find<SurgeryController>().loadSurgeries();
      Get.find<SurgeryController>().loadPets();
    }
    if (Get.isRegistered<FollowUpController>()) {
      Get.find<FollowUpController>().loadFollowUps();
      Get.find<FollowUpController>().loadPets();
    }
    if (Get.isRegistered<AlertsController>()) {
      Get.find<AlertsController>().refreshAlerts();
    }
    if (Get.isRegistered<PatientController>()) {
      final pc = Get.find<PatientController>();
      pc.loadPatients();
      pc.loadOwners();
    }
  }

  static void notifyConsultationChanged({int? petId}) {
    debugPrint('[DataSyncService] notifyConsultationChanged (petId: $petId)');
    if (Get.isRegistered<ConsultationsListController>()) {
      Get.find<ConsultationsListController>().loadConsultations();
    }
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().loadDashboardData();
    }
    if (Get.isRegistered<PharmacyController>()) {
      Get.find<PharmacyController>().loadMedicines();
    }
    if (Get.isRegistered<SurgeryController>()) {
      Get.find<SurgeryController>().loadSurgeries();
    }
    if (Get.isRegistered<FollowUpController>()) {
      Get.find<FollowUpController>().loadFollowUps();
    }
    if (Get.isRegistered<AlertsController>()) {
      Get.find<AlertsController>().refreshAlerts();
    }
    if (Get.isRegistered<PatientController>()) {
      final pc = Get.find<PatientController>();
      pc.loadPatients();
      if (petId != null && pc.selectedPet.value?.id == petId) {
        pc.loadPetFullProfile(petId);
      }
    }
  }

  static void notifyPatientChanged({int? petId}) {
    debugPrint('[DataSyncService] notifyPatientChanged (petId: $petId)');
    if (Get.isRegistered<PatientController>()) {
      final pc = Get.find<PatientController>();
      pc.loadPatients();
      pc.loadOwners();
      if (petId != null && pc.selectedPet.value?.id == petId) {
        pc.loadPetFullProfile(petId);
      }
    }
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().loadDashboardData();
    }
    if (Get.isRegistered<SurgeryController>()) {
      Get.find<SurgeryController>().loadPets();
    }
    if (Get.isRegistered<FollowUpController>()) {
      Get.find<FollowUpController>().loadPets();
    }
  }

  static void notifySurgeryChanged({int? petId}) {
    debugPrint('[DataSyncService] notifySurgeryChanged (petId: $petId)');
    if (Get.isRegistered<SurgeryController>()) {
      Get.find<SurgeryController>().loadSurgeries();
    }
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().loadDashboardData();
    }
    if (Get.isRegistered<AlertsController>()) {
      Get.find<AlertsController>().refreshAlerts();
    }
    if (Get.isRegistered<PatientController>()) {
      final pc = Get.find<PatientController>();
      if (petId != null && pc.selectedPet.value?.id == petId) {
        pc.loadPetFullProfile(petId);
      }
    }
  }

  static void notifyFollowUpChanged({int? petId}) {
    debugPrint('[DataSyncService] notifyFollowUpChanged (petId: $petId)');
    if (Get.isRegistered<FollowUpController>()) {
      Get.find<FollowUpController>().loadFollowUps();
    }
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().loadDashboardData();
    }
    if (Get.isRegistered<AlertsController>()) {
      Get.find<AlertsController>().refreshAlerts();
    }
    if (Get.isRegistered<PatientController>()) {
      final pc = Get.find<PatientController>();
      if (petId != null && pc.selectedPet.value?.id == petId) {
        pc.loadPetFullProfile(petId);
      }
    }
  }

  static void notifyInventoryChanged() {
    debugPrint('[DataSyncService] notifyInventoryChanged');
    if (Get.isRegistered<PharmacyController>()) {
      Get.find<PharmacyController>().loadMedicines();
    }
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().loadDashboardData();
    }
  }

  static void refreshAll() {
    debugPrint('[DataSyncService] refreshAll');
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().loadDashboardData();
    }
    if (Get.isRegistered<PatientController>()) {
      Get.find<PatientController>().loadPatients();
    }
    if (Get.isRegistered<ConsultationsListController>()) {
      Get.find<ConsultationsListController>().loadConsultations();
    }
    if (Get.isRegistered<SurgeryController>()) {
      Get.find<SurgeryController>().loadSurgeries();
    }
    if (Get.isRegistered<FollowUpController>()) {
      Get.find<FollowUpController>().loadFollowUps();
    }
    if (Get.isRegistered<PharmacyController>()) {
      Get.find<PharmacyController>().loadMedicines();
    }
    if (Get.isRegistered<AlertsController>()) {
      Get.find<AlertsController>().refreshAlerts();
    }
  }
}
