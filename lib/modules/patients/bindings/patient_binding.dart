import 'package:get/get.dart';
import '../../../data/repositories/appointment_repository.dart';
import '../../../data/repositories/consultation_repository.dart';
import '../../../data/repositories/financial_repository.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../data/repositories/surgery_repository.dart';
import '../controllers/add_patient_controller.dart';
import '../controllers/owner_controller.dart';
import '../controllers/patient_detail_controller.dart';
import '../controllers/patient_list_controller.dart';

class PatientBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PetRepository>(() => PetRepository());
    Get.lazyPut<ConsultationRepository>(() => ConsultationRepository());
    Get.lazyPut<SurgeryRepository>(() => SurgeryRepository());
    Get.lazyPut<AppointmentRepository>(() => AppointmentRepository());
    Get.lazyPut<FinancialRepository>(() => FinancialRepository());

    Get.lazyPut<PatientListController>(
      () => PatientListController(Get.find<PetRepository>()),
    );
    Get.lazyPut<PatientDetailController>(
      () => PatientDetailController(
        Get.find<PetRepository>(),
        Get.find<ConsultationRepository>(),
        Get.find<SurgeryRepository>(),
        Get.find<AppointmentRepository>(),
      ),
    );
    Get.lazyPut<AddPatientController>(
      () => AddPatientController(Get.find<PetRepository>()),
    );
    Get.lazyPut<OwnerController>(
      () => OwnerController(
        Get.find<PetRepository>(),
        Get.find<FinancialRepository>(),
      ),
    );
  }
}
