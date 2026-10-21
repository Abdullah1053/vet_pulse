import 'package:get/get.dart';
import '../../../data/repositories/backup_repository.dart';
import '../../../data/repositories/financial_repository.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../data/services/database_backup_service.dart';
import '../controllers/backup_controller.dart';

class BackupBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<PetRepository>(() => PetRepository(), fenix: true);
    Get.lazyPut<FinancialRepository>(() => FinancialRepository(), fenix: true);
    Get.lazyPut<BackupRepository>(() => BackupRepository());
    Get.lazyPut<BackupController>(
      () => BackupController(
        backupRepository: Get.find<BackupRepository>(),
        backupService: DatabaseBackupService.instance,
      ),
    );
  }
}
