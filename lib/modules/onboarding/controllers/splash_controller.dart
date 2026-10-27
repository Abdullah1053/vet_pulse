import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/license_service.dart';
import '../../../routes/app_routes.dart';

class SplashController extends GetxController
    with GetSingleTickerProviderStateMixin {
  late final AnimationController animationController;
  late final Animation<double> scaleAnimation;
  late final Animation<double> fadeAnimation;

  @override
  void onInit() {
    super.onInit();

    animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    );

    scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(
        parent: animationController,
        curve: Curves.easeOutBack,
      ),
    );

    fadeAnimation = CurvedAnimation(
      parent: animationController,
      curve: Curves.easeOut,
    );

    animationController.forward();

    _evaluateRouting();
  }

  Future<void> _evaluateRouting() async {
    await Future.delayed(const Duration(milliseconds: 1400));

    final license = LicenseService.to;
    await license.checkLicenseValidity();

    if (!license.onboardingCompleted.value) {
      Get.offAllNamed(AppRoutes.onboarding);
    } else if (!license.isLicenseActive.value) {
      Get.offAllNamed(AppRoutes.activation);
    } else if (!license.clinicSetupCompleted.value) {
      Get.offAllNamed(AppRoutes.clinicSetup);
    } else {
      Get.offAllNamed(AppRoutes.login);
    }
  }

  @override
  void onClose() {
    animationController.dispose();
    super.onClose();
  }
}
