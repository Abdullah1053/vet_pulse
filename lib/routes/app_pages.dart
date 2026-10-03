import 'package:get/get.dart';
import '../modules/auth/bindings/auth_binding.dart';
import '../modules/auth/views/clinic_setup_view.dart';
import '../modules/auth/views/login_view.dart';
import '../modules/auth/views/pin_lock_view.dart';
import '../modules/consultations/bindings/consultation_binding.dart';
import '../modules/consultations/views/consultation_detail_view.dart';
import '../modules/consultations/views/consultations_list_view.dart';
import '../modules/consultations/views/new_consultation_view.dart';
import '../modules/consultations/views/prescription_preview_view.dart';
import '../modules/dashboard/bindings/dashboard_binding.dart';
import '../modules/dashboard/views/dashboard_view.dart';
import '../modules/dashboard/views/weekly_reports_view.dart';
import '../modules/follow_ups/bindings/follow_up_binding.dart';
import '../modules/follow_ups/views/follow_up_calendar_view.dart';
import '../modules/patients/bindings/patient_binding.dart';
import '../modules/patients/views/add_patient_view.dart';
import '../modules/patients/views/owner_detail_view.dart';
import '../modules/patients/views/owners_list_view.dart';
import '../modules/patients/views/patient_detail_view.dart';
import '../modules/patients/views/patient_list_view.dart';
import '../modules/pharmacy/bindings/pharmacy_binding.dart';
import '../modules/pharmacy/views/add_medicine_view.dart';
import '../modules/pharmacy/views/inventory_list_view.dart';
import '../modules/pharmacy/views/stock_transfer_view.dart';
import '../modules/surgeries/bindings/surgery_binding.dart';
import '../modules/surgeries/views/complete_surgery_view.dart';
import '../modules/surgeries/views/new_surgery_view.dart';
import '../modules/surgeries/views/surgery_calendar_view.dart';
import '../modules/users_management/bindings/users_binding.dart';
import '../modules/users_management/views/users_list_view.dart';
import '../modules/financials/bindings/financial_binding.dart';
import '../modules/financials/views/financial_dashboard_view.dart';
import '../modules/financials/views/owner_account_statement_view.dart';
import 'app_routes.dart';

class AppPages {
  AppPages._();

  static const initial = AppRoutes.login;

  static final routes = [
    // Auth
    GetPage(
      name: AppRoutes.login,
      page: () => const LoginView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.pinLock,
      page: () => const PinLockView(),
      binding: AuthBinding(),
    ),
    GetPage(
      name: AppRoutes.clinicSetup,
      page: () => const ClinicSetupView(),
      binding: AuthBinding(),
    ),

    // Dashboard
    GetPage(
      name: AppRoutes.dashboard,
      page: () => const DashboardView(),
      binding: DashboardBinding(),
    ),

    // Patients
    GetPage(
      name: AppRoutes.patientList,
      page: () => const PatientListView(),
      binding: PatientBinding(),
    ),
    GetPage(
      name: AppRoutes.patientDetail,
      page: () => const PatientDetailView(),
      binding: PatientBinding(),
    ),
    GetPage(
      name: AppRoutes.addPatient,
      page: () => const AddPatientView(),
      binding: PatientBinding(),
    ),
    GetPage(
      name: AppRoutes.owners,
      page: () => const OwnersListView(),
    ),
    GetPage(
      name: AppRoutes.ownerDetail,
      page: () => const OwnerDetailView(),
    ),

    // Reports
    GetPage(
      name: AppRoutes.weeklyReports,
      page: () => const WeeklyReportsView(),
    ),

    // Consultations & Prescriptions
    GetPage(
      name: AppRoutes.consultations,
      page: () => const ConsultationsListView(),
    ),
    GetPage(
      name: AppRoutes.newConsultation,
      page: () => const NewConsultationView(),
      binding: ConsultationBinding(),
    ),
    GetPage(
      name: AppRoutes.consultationDetail,
      page: () => const ConsultationDetailView(),
      binding: ConsultationBinding(),
    ),
    GetPage(
      name: AppRoutes.prescriptionPreview,
      page: () => const PrescriptionPreviewView(),
      binding: ConsultationBinding(),
    ),

    // Pharmacy & Inventory
    GetPage(
      name: AppRoutes.inventoryList,
      page: () => const InventoryListView(),
      binding: PharmacyBinding(),
    ),
    GetPage(
      name: AppRoutes.addMedicine,
      page: () => const AddMedicineView(),
      binding: PharmacyBinding(),
    ),
    GetPage(
      name: AppRoutes.stockTransfer,
      page: () => const StockTransferView(),
      binding: PharmacyBinding(),
    ),

    // Follow-ups
    GetPage(
      name: AppRoutes.followUps,
      page: () => const FollowUpCalendarView(),
      binding: FollowUpBinding(),
    ),

    // Surgeries
    GetPage(
      name: AppRoutes.surgeries,
      page: () => const SurgeryCalendarView(),
      binding: SurgeryBinding(),
    ),
    GetPage(
      name: AppRoutes.newSurgery,
      page: () => const NewSurgeryView(),
      binding: SurgeryBinding(),
    ),
    GetPage(
      name: AppRoutes.completeSurgery,
      page: () => const CompleteSurgeryView(),
      binding: SurgeryBinding(),
    ),

    // Users
    GetPage(
      name: AppRoutes.usersManagement,
      page: () => const UsersListView(),
      binding: UsersBinding(),
    ),

    // Financials & Accounting
    GetPage(
      name: AppRoutes.financialDashboard,
      page: () => const FinancialDashboardView(),
      binding: FinancialBinding(),
    ),
    GetPage(
      name: AppRoutes.ownerAccountStatement,
      page: () => const OwnerAccountStatementView(),
    ),
  ];
}
