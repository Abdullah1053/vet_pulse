import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';
import '../constants/app_colors.dart';
import '../constants/app_theme.dart';
import 'empty_state_view.dart';
import 'primary_button.dart';
import 'status_chip.dart';

/// Wraps widgets with the official VetPulse theme, Arabic RTL directionality, and scaffold.
class VetPulsePreviewWrapper extends StatelessWidget {
  final Widget child;
  const VetPulsePreviewWrapper({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      home: Directionality(
        textDirection: TextDirection.rtl,
        child: Scaffold(
          backgroundColor: const Color(0xFFF8F9FA),
          body: Center(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: child,
            ),
          ),
        ),
      ),
    );
  }
}

// ==========================================
// 1. STATUS CHIPS PREVIEWS
// ==========================================

@Preview(name: 'Chip - Success (معقم)', group: 'Status Chips')
Widget previewChipSuccess() {
  return const VetPulsePreviewWrapper(
    child: StatusChip(label: 'معقم', type: ChipStatusType.success),
  );
}

@Preview(name: 'Chip - Critical (حساسية مفرطة)', group: 'Status Chips')
Widget previewChipCritical() {
  return const VetPulsePreviewWrapper(
    child: StatusChip(
      label: 'حساسية بنسلين مفرطة',
      type: ChipStatusType.critical,
      icon: Icons.warning_amber_rounded,
    ),
  );
}

@Preview(name: 'Chip - Warning (أوشك على النفاذ)', group: 'Status Chips')
Widget previewChipWarning() {
  return const VetPulsePreviewWrapper(
    child: StatusChip(
      label: 'مخزون حرج (3 عبوات)',
      type: ChipStatusType.warning,
      icon: Icons.priority_high,
    ),
  );
}

@Preview(name: 'Chip - Info (النوع)', group: 'Status Chips')
Widget previewChipInfo() {
  return const VetPulsePreviewWrapper(
    child: StatusChip(label: 'قط شيرازي (Persian)', type: ChipStatusType.info),
  );
}

@Preview(name: 'Chip - Neutral (الجنس)', group: 'Status Chips')
Widget previewChipNeutral() {
  return const VetPulsePreviewWrapper(
    child: StatusChip(label: 'ذكر • 2 سنة و 3 أشهر', type: ChipStatusType.neutral),
  );
}

// ==========================================
// 2. PRIMARY BUTTONS PREVIEWS
// ==========================================

@Preview(name: 'Button - Primary Active', group: 'Buttons')
Widget previewPrimaryButton() {
  return VetPulsePreviewWrapper(
    child: SizedBox(
      width: 320,
      child: PrimaryButton(
        text: 'بدء كشف سريري جديد (SOAP)',
        icon: Icons.medical_services_outlined,
        onPressed: () {},
      ),
    ),
  );
}

@Preview(name: 'Button - Loading State', group: 'Buttons')
Widget previewButtonLoading() {
  return const VetPulsePreviewWrapper(
    child: SizedBox(
      width: 320,
      child: PrimaryButton(
        text: 'حفظ وتوليد الروشتة PDF',
        isLoading: true,
        onPressed: null,
      ),
    ),
  );
}

// ==========================================
// 3. EMPTY STATE VIEW PREVIEWS
// ==========================================

@Preview(name: 'Empty State - No Patients', group: 'Empty States')
Widget previewEmptyPatients() {
  return VetPulsePreviewWrapper(
    child: SizedBox(
      width: 360,
      child: EmptyStateView(
        icon: Icons.pets,
        title: 'لا يوجد حيوانات أليفة مسجلة',
        subtitle: 'قم بإضافة ملف المريض الأول للبدء في تتبع السجل الطبي والكشوفات',
        actionText: 'إضافة مريض جديد',
        onAction: () {},
      ),
    ),
  );
}

@Preview(name: 'Empty State - No Debts', group: 'Empty States')
Widget previewEmptyDebts() {
  return const VetPulsePreviewWrapper(
    child: SizedBox(
      width: 360,
      child: EmptyStateView(
        icon: Icons.check_circle_outline,
        title: 'سجل الحسابات والديون خالص تماماً',
        subtitle: 'جميع المربين مسددين لمستحقات الكشوفات والعمليات السابقة',
      ),
    ),
  );
}

// ==========================================
// 4. CLINICAL CARDS PREVIEWS
// ==========================================

@Preview(name: 'Card - Allergy Warning Banner', group: 'Clinical Cards')
Widget previewAllergyBanner() {
  return VetPulsePreviewWrapper(
    child: Container(
      width: 360,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.criticalBackground,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.critical, width: 1.5),
      ),
      child: const Row(
        children: [
          Icon(Icons.warning_amber_rounded, color: AppColors.critical, size: 28),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'تحذير طبي: حساسية دوائية حرجة',
                  style: TextStyle(
                    color: AppColors.critical,
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 2),
                Text(
                  'يمنع إعطاء مشتقات البنسلين والستربتومايسين نهائياً لهذا المريض',
                  style: TextStyle(
                    color: AppColors.textPrimary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ),
  );
}

@Preview(name: 'Card - KPI Metric Dashboard Card', group: 'Dashboard Cards')
Widget previewKpiMetricCard() {
  return VetPulsePreviewWrapper(
    child: Container(
      width: 180,
      height: 120,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: AppColors.secondaryLight,
                child: Icon(Icons.medical_services_outlined, color: AppColors.primary, size: 18),
              ),
              Text(
                '14',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: AppColors.primary),
              ),
            ],
          ),
          Text(
            'كشوفات اليوم السريرية',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.darkNeutral),
          ),
        ],
      ),
    ),
  );
}

@Preview(name: 'Card - Financial Balance Pill', group: 'Financial Cards')
Widget previewFinancialPills() {
  return VetPulsePreviewWrapper(
    child: Container(
      width: 360,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('المطالبات (مدين)', style: TextStyle(fontSize: 11, color: Colors.blue.shade900)),
                  const SizedBox(height: 2),
                  Text('35,000 ر.ي', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue.shade900)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('المسدد (دائن)', style: TextStyle(fontSize: 11, color: Colors.green.shade900)),
                  const SizedBox(height: 2),
                  Text('25,000 ر.ي', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green.shade900)),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
              decoration: BoxDecoration(
                color: Colors.amber.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('المتبقي (دين)', style: TextStyle(fontSize: 11, color: Colors.amber.shade900)),
                  const SizedBox(height: 2),
                  Text('10,000 ر.ي', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.amber.shade900)),
                ],
              ),
            ),
          ),
        ],
      ),
    ),
  );
}
