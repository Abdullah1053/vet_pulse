import 'package:flutter/foundation.dart';
import 'package:get/get.dart';
import '../../modules/dashboard/controllers/dashboard_controller.dart';
import '../../modules/dashboard/controllers/weekly_reports_controller.dart';
import '../../modules/dashboard/services/alerts_service.dart';
import '../../modules/patients/controllers/patient_controller.dart';
import '../../modules/consultations/controllers/consultations_list_controller.dart';
import '../../modules/surgeries/controllers/surgery_controller.dart';
import '../../modules/follow_ups/controllers/follow_up_controller.dart';
import '../../modules/pharmacy/controllers/pharmacy_controller.dart';
import '../../modules/financials/controllers/financial_controller.dart';

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
    if (Get.isRegistered<InventoryListController>()) {
      Get.find<InventoryListController>().loadMedicines();
    }
    if (Get.isRegistered<SurgeryListController>()) {
      Get.find<SurgeryListController>().loadSurgeries();
    }
    if (Get.isRegistered<SurgeryFormController>()) {
      Get.find<SurgeryFormController>().loadPetsAndDoctors();
    }
    if (Get.isRegistered<FollowUpController>()) {
      Get.find<FollowUpController>().loadFollowUps();
      Get.find<FollowUpController>().loadPets();
    }
    if (Get.isRegistered<AlertsController>()) {
      Get.find<AlertsController>().refreshAlerts();
    }
    if (Get.isRegistered<PatientListController>()) {
      Get.find<PatientListController>().loadPatients();
    }
    if (Get.isRegistered<PatientDetailController>()) {
      final pdc = Get.find<PatientDetailController>();
      if (pdc.petId != null) {
        pdc.loadPetFullProfile(pdc.petId!);
      }
    }
    if (Get.isRegistered<OwnerController>()) {
      Get.find<OwnerController>().loadOwners();
    }
    if (Get.isRegistered<FinancialDashboardController>()) {
      Get.find<FinancialDashboardController>().loadFinancialData();
    }
    if (Get.isRegistered<WeeklyReportsController>()) {
      Get.find<WeeklyReportsController>().loadWeeklyReport();
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
    if (Get.isRegistered<InventoryListController>()) {
      Get.find<InventoryListController>().loadMedicines();
    }
    if (Get.isRegistered<SurgeryListController>()) {
      Get.find<SurgeryListController>().loadSurgeries();
    }
    if (Get.isRegistered<FollowUpController>()) {
      Get.find<FollowUpController>().loadFollowUps();
    }
    if (Get.isRegistered<AlertsController>()) {
      Get.find<AlertsController>().refreshAlerts();
    }
    if (Get.isRegistered<PatientListController>()) {
      Get.find<PatientListController>().loadPatients();
    }
    if (Get.isRegistered<PatientDetailController>()) {
      final pdc = Get.find<PatientDetailController>();
      if (petId != null && pdc.petId == petId) {
        pdc.loadPetFullProfile(petId);
      }
    }
    if (Get.isRegistered<FinancialDashboardController>()) {
      Get.find<FinancialDashboardController>().loadFinancialData();
    }
    if (Get.isRegistered<OwnerStatementController>()) {
      Get.find<OwnerStatementController>().loadStatement();
    }
    if (Get.isRegistered<OwnerController>()) {
      Get.find<OwnerController>().loadOwnerData();
    }
  }

  static void notifyPatientChanged({int? petId}) {
    debugPrint('[DataSyncService] notifyPatientChanged (petId: $petId)');
    if (Get.isRegistered<PatientListController>()) {
      Get.find<PatientListController>().loadPatients();
    }
    if (Get.isRegistered<OwnerController>()) {
      final oc = Get.find<OwnerController>();
      oc.loadOwners();
      oc.loadOwnerData();
    }
    if (Get.isRegistered<PatientDetailController>()) {
      final pdc = Get.find<PatientDetailController>();
      if (petId != null && pdc.petId == petId) {
        pdc.loadPetFullProfile(petId);
      }
    }
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().loadDashboardData();
    }
    if (Get.isRegistered<SurgeryFormController>()) {
      Get.find<SurgeryFormController>().loadPetsAndDoctors();
    }
    if (Get.isRegistered<FollowUpController>()) {
      Get.find<FollowUpController>().loadPets();
    }
  }

  static void notifySurgeryChanged({int? petId}) {
    debugPrint('[DataSyncService] notifySurgeryChanged (petId: $petId)');
    if (Get.isRegistered<SurgeryListController>()) {
      Get.find<SurgeryListController>().loadSurgeries();
    }
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().loadDashboardData();
    }
    if (Get.isRegistered<AlertsController>()) {
      Get.find<AlertsController>().refreshAlerts();
    }
    if (Get.isRegistered<PatientDetailController>()) {
      final pdc = Get.find<PatientDetailController>();
      if (petId != null && pdc.petId == petId) {
        pdc.loadPetFullProfile(petId);
      }
    }
    if (Get.isRegistered<FinancialDashboardController>()) {
      Get.find<FinancialDashboardController>().loadFinancialData();
    }
    if (Get.isRegistered<OwnerStatementController>()) {
      Get.find<OwnerStatementController>().loadStatement();
    }
    if (Get.isRegistered<OwnerController>()) {
      Get.find<OwnerController>().loadOwnerData();
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
    if (Get.isRegistered<PatientDetailController>()) {
      final pdc = Get.find<PatientDetailController>();
      if (petId != null && pdc.petId == petId) {
        pdc.loadPetFullProfile(petId);
      }
    }
  }

  static void notifyInventoryChanged() {
    debugPrint('[DataSyncService] notifyInventoryChanged');
    if (Get.isRegistered<InventoryListController>()) {
      Get.find<InventoryListController>().loadMedicines();
    }
    if (Get.isRegistered<StockTransferController>()) {
      Get.find<StockTransferController>().loadMedicines();
    }
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().loadDashboardData();
    }
  }

  static void notifyFinancialChanged() {
    debugPrint('[DataSyncService] notifyFinancialChanged');
    if (Get.isRegistered<FinancialDashboardController>()) {
      Get.find<FinancialDashboardController>().loadFinancialData();
    }
    if (Get.isRegistered<OwnerStatementController>()) {
      Get.find<OwnerStatementController>().loadStatement();
    }
    if (Get.isRegistered<OwnerController>()) {
      Get.find<OwnerController>().loadOwnerData();
    }
    if (Get.isRegistered<DashboardController>()) {
      Get.find<DashboardController>().loadDashboardData();
    }
  }

  static void refreshAll() {
    notifyAllChanged();
  }
}
