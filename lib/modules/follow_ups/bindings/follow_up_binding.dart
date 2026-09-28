import 'package:get/get.dart';
import '../controllers/follow_up_controller.dart';

class FollowUpBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<FollowUpController>(() => FollowUpController());
  }
}
