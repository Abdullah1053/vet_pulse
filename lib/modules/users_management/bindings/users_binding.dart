import 'package:get/get.dart';
import '../../../data/repositories/auth_repository.dart';
import '../controllers/users_controller.dart';

class UsersBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<AuthRepository>(() => AuthRepository());
    Get.lazyPut<UsersController>(() => UsersController(Get.find<AuthRepository>()));
  }
}
