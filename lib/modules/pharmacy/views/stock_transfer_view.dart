import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/custom_text_field.dart';
import '../../../core/widgets/primary_button.dart';
import '../controllers/pharmacy_controller.dart';

class StockTransferView extends GetView<PharmacyController> {
  const StockTransferView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStringsAr.stockTransfer),
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
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: const BoxDecoration(
                            color: AppColors.secondaryLight,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.swap_horiz, color: AppColors.primary),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'نقل مخزون داخلي',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                              ),
                              Text(
                                'تحويل مستحضرات من المستودع الرئيسي إلى رف العيادة',
                                style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const Divider(height: 24),

                    // Select Medicine
                    Obx(() {
                      return DropdownButtonFormField<int?>(
                        isExpanded: true,
                        initialValue: controller.selectedMedForTransfer.value?.id,
                        decoration: const InputDecoration(labelText: 'اختر الصنف المراد نقله'),
                        items: controller.medicines.map((m) {
                          return DropdownMenuItem<int?>(
                            value: m.id,
                            child: Text(
                              '${m.tradeName} (المستودع: ${m.warehouseStock} | الرف: ${m.clinicStock})',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          );
                        }).toList(),
                        onChanged: (id) {
                          if (id != null) {
                            controller.selectedMedForTransfer.value =
                                controller.medicines.firstWhere((m) => m.id == id);
                          }
                        },
                      );
                    }),
                    const SizedBox(height: 16),

                    // Current stock status preview
                    Obx(() {
                      final med = controller.selectedMedForTransfer.value;
                      if (med != null) {
                        return Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.background,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: AppColors.border),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceAround,
                            children: [
                              Column(
                                children: [
                                  const Text('رصيد المستودع (المصدر)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${med.warehouseStock}',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                                  ),
                                ],
                              ),
                              const Icon(Icons.arrow_back, color: AppColors.primary),
                              Column(
                                children: [
                                  const Text('رصيد رف العيادة (الوجهة)', style: TextStyle(fontSize: 11, color: AppColors.textSecondary)),
                                  const SizedBox(height: 4),
                                  Text(
                                    '${med.clinicStock}',
                                    style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    }),
                    const SizedBox(height: 16),

                    CustomTextField(
                      label: AppStringsAr.transferAmount,
                      hint: 'مثال: 10',
                      controller: controller.transferQuantityController,
                      keyboardType: TextInputType.number,
                      prefixIcon: const Icon(Icons.pin),
                    ),
                    const SizedBox(height: 24),

                    Obx(() => PrimaryButton(
                          text: 'تأكيد نقل الرصيد',
                          isLoading: controller.isLoading.value,
                          icon: Icons.check,
                          onPressed: controller.transferStock,
                        )),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
