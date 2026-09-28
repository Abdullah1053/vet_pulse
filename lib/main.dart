import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:get/get.dart';
import 'core/constants/app_strings_ar.dart';
import 'core/constants/app_theme.dart';
import 'data/database/database_helper.dart';
import 'modules/auth/controllers/auth_controller.dart';
import 'routes/app_pages.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize SQLite Database Engine & seed initial clinic data
  await DatabaseHelper.instance.database;

  // Initialize global services
  Get.put<AuthController>(AuthController(), permanent: true);

  runApp(const VetPulseApp());
}

class VetPulseApp extends StatelessWidget {
  const VetPulseApp({super.key});

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
      initialRoute: AppPages.initial,
      getPages: AppPages.routes,
      defaultTransition: Transition.fadeIn,
    );
  }
}
