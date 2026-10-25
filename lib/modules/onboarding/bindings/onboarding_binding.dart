import 'package:get/get.dart';
import '../controllers/activation_controller.dart';
import '../controllers/onboarding_controller.dart';

class OnboardingBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<OnboardingController>(() => OnboardingController());
  }
}

class ActivationBinding extends Bindings {
  @override
  void dependencies() {
    Get.lazyPut<ActivationController>(() => ActivationController());
  }
}
