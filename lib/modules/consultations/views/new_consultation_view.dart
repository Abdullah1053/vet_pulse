import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/primary_button.dart';
import '../controllers/new_consultation_controller.dart';
import '../widgets/clinic_treatments_section.dart';
import '../widgets/consultation_financial_section.dart';
import '../widgets/dosage_calculator_dialog.dart';
import '../widgets/home_prescriptions_section.dart';
import '../widgets/patient_info_section.dart';
import '../widgets/soap_notes_section.dart';
import '../widgets/surgery_scheduling_section.dart';
import '../widgets/treatment_plan_section.dart';
import '../widgets/vitals_section.dart';

class NewConsultationView extends GetView<NewConsultationController> {
  const NewConsultationView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStringsAr.newConsultation),
        actions: [
          IconButton(
            tooltip: AppStringsAr.dosageCalculator,
            icon: const Icon(Icons.calculate_outlined),
            onPressed: () => DosageCalculatorDialog.show(context),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Obx(
          () => PrimaryButton(
            text: 'حفظ الكشف الطبي وصرف الأدوية والروشتة',
            icon: Icons.check_circle_outline,
            isLoading: controller.isLoading.value,
            onPressed: controller.saveConsultation,
          ),
        ),
      ),
      body: const SingleChildScrollView(
        padding: EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            PatientInfoSection(),
            SizedBox(height: 16),
            VitalsSection(),
            SizedBox(height: 16),
            SoapNotesSection(),
            SizedBox(height: 16),
            ClinicTreatmentsSection(),
            SizedBox(height: 16),
            HomePrescriptionsSection(),
            SizedBox(height: 16),
            SurgerySchedulingSection(),
            SizedBox(height: 16),
            TreatmentPlanSection(),
            SizedBox(height: 16),
            ConsultationFinancialSection(),
            SizedBox(height: 24),
          ],
        ),
      ),
    );
  }
}
