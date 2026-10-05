import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../controllers/pharmacy_controller.dart';

class AddMedicineView extends GetView<PharmacyController> {
  const AddMedicineView({super.key});

  Future<void> _selectExpiryDate(BuildContext context) async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 365)),
      firstDate: DateTime(2020),
      lastDate: DateTime(2035),
    );
    if (picked != null) {
      controller.expiryDateController.text =
          picked.toIso8601String().substring(0, 10);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStringsAr.addMedicine),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'بيانات المستحضر الدوائي',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      label: AppStringsAr.tradeName,
                      hint: 'مثال: أموكسيسيلين كلافولانيك (Synulox)',
                      controller: controller.tradeNameController,
                      prefixIcon: const Icon(Icons.medication),
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: AppStringsAr.scientificName,
                      hint: 'مثال: Amoxicillin + Clavulanic Acid',
                      controller: controller.scientificNameController,
                      prefixIcon: const Icon(Icons.science),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                AppStringsAr.form,
                                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontSize: 13),
                              ),
                              const SizedBox(height: 6),
                              DropdownButtonFormField<String>(
                                isExpanded: true,
                                initialValue: controller.formController.text,
                                decoration: const InputDecoration(),
                                items: const [
                                  DropdownMenuItem(value: AppStringsAr.formTablet, child: Text(AppStringsAr.formTablet, overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: AppStringsAr.formInjection, child: Text(AppStringsAr.formInjection, overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: AppStringsAr.formSyrup, child: Text(AppStringsAr.formSyrup, overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: AppStringsAr.formOintment, child: Text(AppStringsAr.formOintment, overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: AppStringsAr.formVaccine, child: Text(AppStringsAr.formVaccine, overflow: TextOverflow.ellipsis)),
                                  DropdownMenuItem(value: AppStringsAr.formFluid, child: Text(AppStringsAr.formFluid, overflow: TextOverflow.ellipsis)),
                                ],
                                onChanged: (v) {
                                  if (v != null) controller.formController.text = v;
                                },
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: AppStringsAr.concentration,
                            hint: 'مثال: 250mg أو 5mg/ml',
                            controller: controller.concentrationController,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Stock Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'أرصدة التخزين والأسعار',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: 'رصيد رف العيادة',
                            hint: '10',
                            controller: controller.clinicStockController,
                            keyboardType: TextInputType.number,
                            prefixIcon: const Icon(Icons.storefront),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: 'رصيد المستودع الرئيسي',
                            hint: '50',
                            controller: controller.warehouseStockController,
                            keyboardType: TextInputType.number,
                            prefixIcon: const Icon(Icons.warehouse),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    CustomTextField(
                      label: AppStringsAr.minStockAlert,
                      hint: '5',
                      controller: controller.minStockController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.notifications_active),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: AppStringsAr.unitCostPrice,
                            hint: '25.0',
                            controller: controller.costPriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: AppStringsAr.unitSalePrice,
                            hint: '45.0',
                            controller: controller.salePriceController,
                            keyboardType: const TextInputType.numberWithOptions(decimal: true),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: CustomTextField(
                            label: AppStringsAr.expiryDate,
                            hint: 'YYYY-MM-DD',
                            controller: controller.expiryDateController,
                            readOnly: true,
                            onTap: () => _selectExpiryDate(context),
                            prefixIcon: const Icon(Icons.calendar_today),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: CustomTextField(
                            label: AppStringsAr.batchNumber,
                            hint: 'مثال: BATCH-2026',
                            controller: controller.batchNumberController,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            Obx(() => PrimaryButton(
                  text: AppStringsAr.save,
                  isLoading: controller.isLoading.value,
                  icon: Icons.check,
                  onPressed: controller.saveMedicine,
                )),
          ],
        ),
      ),
    );
  }
}
