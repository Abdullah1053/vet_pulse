import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'core/constants/app_strings_ar.dart';
import 'core/constants/app_theme.dart';
import 'core/services/license_service.dart';
import 'core/services/notification_service.dart';
import 'data/database/database_helper.dart';
import 'modules/auth/controllers/auth_controller.dart';
import 'routes/app_pages.dart';
import 'routes/app_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite Database Engine & seed initial clinic data
  await DatabaseHelper.instance.database;

  // Initialize global services
  final licenseService = await Get.putAsync(() => LicenseService().init(), permanent: true);
  Get.put<NotificationService>(NotificationService(), permanent: true);
  Get.put<AuthController>(AuthController(), permanent: true);

  // Dynamic Initial Startup Routing Guard
  final String initialRoute;
  if (!licenseService.onboardingCompleted.value) {
    initialRoute = AppRoutes.onboarding;
  } else if (!licenseService.isLicenseActive.value) {
    initialRoute = AppRoutes.activation;
  } else if (!licenseService.clinicSetupCompleted.value) {
    initialRoute = AppRoutes.clinicSetup;
  } else {
    initialRoute = AppRoutes.login;
  }

  runApp(VetPulseApp(initialRoute: initialRoute));
}

class VetPulseApp extends StatelessWidget {
  final String initialRoute;
  const VetPulseApp({super.key, this.initialRoute = AppRoutes.login});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: AppStringsAr.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,

      // Native Arabic RTL Configuration
      locale: const Locale('ar', 'SA'),
      fallbackLocale: const Locale('ar', 'SA'),
      supportedLocales: const [
        Locale('ar', 'SA'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      // Navigation & Routes
      initialRoute: initialRoute,
      getPages: AppPages.routes,
      defaultTransition: Transition.fadeIn,
    );
  }
}
