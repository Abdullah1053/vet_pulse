abstract class AppRoutes {
  AppRoutes._();

  static const login = '/login';
  static const clinicSetup = '/clinic-setup';
  static const pinLock = '/pin-lock';
  static const dashboard = '/dashboard';

  static const patientList = '/patients';
  static const patientDetail = '/patients/detail';
  static const addPatient = '/patients/add';

  static const consultations = '/consultations';
  static const newConsultation = '/consultations/new';
  static const consultationDetail = '/consultations/detail';
  static const prescriptionPreview = '/consultations/prescription-preview';

  static const owners = '/owners';
  static const ownerDetail = '/owners/detail';

  static const weeklyReports = '/reports/weekly';

  static const inventoryList = '/pharmacy';
  static const addMedicine = '/pharmacy/add';
  static const stockTransfer = '/pharmacy/transfer';

  static const followUps = '/follow-ups';

  static const surgeries = '/surgeries';
  static const newSurgery = '/surgeries/new';
  static const completeSurgery = '/surgeries/complete';

  static const usersManagement = '/users';
}
