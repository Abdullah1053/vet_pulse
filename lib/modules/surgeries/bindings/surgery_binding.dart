import 'package:get/get.dart';
import '../controllers/surgery_controller.dart';

class SurgeryBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<SurgeryController>(() => SurgeryController());
  }
}
