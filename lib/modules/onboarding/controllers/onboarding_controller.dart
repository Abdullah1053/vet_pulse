import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/services/license_service.dart';
import '../../../routes/app_routes.dart';

class OnboardingSlide {
  final String title;
  final String description;
  final IconData icon;
  final List<String> highlights;

  const OnboardingSlide({
    required this.title,
    required this.description,
    required this.icon,
    required this.highlights,
  });
}

class OnboardingController extends GetxController {
  final PageController pageController = PageController();
  final RxInt currentPage = 0.obs;

  final List<OnboardingSlide> slides = const [
    OnboardingSlide(
      title: 'الرعاية السريرية المتكاملة والتشخيص SOAP',
      description:
          'ملفات طبية شاملة لجميع الحيوانات الأليفة، وفحوصات سريرية دقيقة وفق منهجية SOAP المعتمدة، وتوثيق العلاجات داخل العيادة، مع تصدير تلقائي للروشتات الطبية ومشاركتها عبر واتساب.',
      icon: Icons.medical_services_rounded,
      highlights: [
        'سجل طبي تراكمي يشمل الحساسية وتاريخ الأوزان',
        'تشخيص سريري وفق منهجية SOAP المعتمدة عالمياً',
        'إصدار روشتات إلكترونية ومشاركتها فوراً عبر واتساب',
      ],
    ),
    OnboardingSlide(
      title: 'الجناح الجراحي وجدولة المراجعات الذكية',
      description:
          'جدولة دقيقة للعمليات الجراحية، وقوائم التحقق والسلامة قبل وبعد التخدير، ورحلة متابعة سريرية متقدمة مع إشعارات وتنبيهات هاتفية قبل الموعد بـ (12 ساعة، 6 ساعات، وساعة واحدة).',
      icon: Icons.healing_rounded,
      highlights: [
        'تقويم جراحي ذكي وإدارة بروتوكولات التخدير والتعافي',
        'قوائم تدقيق السلامة الجراحية لمنع الأخطاء الطبية',
        'إشعارات وتنبيهات هاتفية تلقائية للمربين والعيادة',
      ],
    ),
    OnboardingSlide(
      title: 'إدارة الصيدلية والمحاسبة المالية والنسخ الاحتياطي',
      description:
          'نظام المخزون المزدوج (المستودع ورفوف العيادة) مع الخصم التلقائي، وحسابات العملاء (نقداً وآجل)، وتوثيق الدفعات وسندات القبض، مع نسخ احتياطي محلي مشفر واستعادة فورية للبيانات.',
      icon: Icons.inventory_2_rounded,
      highlights: [
        'مخزون مزدوج وخصم تلقائي مع مراقبة تواريخ الصلاحية',
        'كشوفات حسابات المربين وسندات القبض النقدية والآجلة',
        'نسخ احتياطي محلي مشفر واستعادة فورية للبيانات',
      ],
    ),
  ];

  void onPageChanged(int index) {
    currentPage.value = index;
  }

  void nextPage() {
    if (currentPage.value < slides.length - 1) {
      pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      finishOnboarding();
    }
  }

  void skip() {
    finishOnboarding();
  }

  Future<void> finishOnboarding() async {
    await LicenseService.to.completeOnboarding();
    Get.offAllNamed(AppRoutes.activation);
  }

  @override
  void onClose() {
    pageController.dispose();
    super.onClose();
  }
}
