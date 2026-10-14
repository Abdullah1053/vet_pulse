import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_payment_methods.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../core/widgets/status_chip.dart';
import '../../../data/models/account_statement_model.dart';
import '../../../data/models/owner_model.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/repositories/financial_repository.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../core/services/device_contact_service.dart';
import '../../../routes/app_routes.dart';

class OwnerDetailController extends GetxController {
  final PetRepository _petRepo = PetRepository();
  final FinancialRepository _financialRepo = FinancialRepository();

  final Rx<OwnerModel?> owner = Rx<OwnerModel?>(null);
  final RxList<PetModel> pets = <PetModel>[].obs;
  final Rx<OwnerAccountSummary?> accountSummary = Rx<OwnerAccountSummary?>(
    null,
  );
  final RxBool isLoading = true.obs;

  late int ownerId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is int) {
      ownerId = args;
      loadOwnerData();
    } else {
      Get.back();
    }
  }

  Future<void> loadOwnerData() async {
    isLoading.value = true;
    try {
      final o = await _petRepo.getOwnerById(ownerId);
      owner.value = o;
      final petList = await _petRepo.getPetsByOwnerId(ownerId);
      pets.assignAll(petList);
      final s = await _financialRepo.getOwnerAccountSummary(ownerId);
      accountSummary.value = s;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> callOwner() async {
    final phone = owner.value?.phonePrimary;
    if (phone == null) return;
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> whatsappOwner() async {
    final phone = owner.value?.phonePrimary;
    if (phone == null) return;
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final name = owner.value?.fullName ?? '';
    final uri = Uri.parse(
      'whatsapp://send?phone=$clean&text=${Uri.encodeComponent("مرحباً أ/ $name")}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> saveOwnerToPhoneContacts() async {
    final o = owner.value;
    if (o == null) return;
    await DeviceContactService.saveOwnerToContacts(
      name: o.fullName,
      phone: o.phonePrimary,
    );
  }

  void openAccountStatement() {
    Get.toNamed(
      AppRoutes.ownerAccountStatement,
      arguments: ownerId,
    )?.then((_) => loadOwnerData());
  }

  void showAddPaymentDialog() {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String paymentMethod = AppPaymentMethods.cash;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: AppColors.success),
            const SizedBox(width: 8),
            Text('سند قبض لحساب: ${owner.value?.fullName ?? ""}'),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: 'المبلغ المسدد (ر.ي) *',
                    hintText: 'مثال: 10000',
                    prefixIcon: Icon(Icons.money),
                    border: OutlineInputBorder(),
                  ),
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<String>(
                  isExpanded: true,
                  initialValue: paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'طريقة التحصيل *',
                    border: OutlineInputBorder(),
                  ),
                  items: AppPaymentMethods.fixedOptions.map((opt) {
                    IconData icon;
                    switch (opt) {
                      case AppPaymentMethods.jawali:
                      case AppPaymentMethods.jeeb:
                      case AppPaymentMethods.floosak:
                        icon = Icons.phone_android;
                        break;
                      case AppPaymentMethods.kuraimi:
                        icon = Icons.account_balance;
                        break;
                      case AppPaymentMethods.cash:
                      default:
                        icon = Icons.payments_outlined;
                        break;
                    }
                    return DropdownMenuItem<String>(
                      value: opt,
                      child: Row(
                        children: [
                          Icon(icon, size: 20, color: AppColors.primary),
                          const SizedBox(width: 8),
                          Text(
                            opt,
                            style: const TextStyle(fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (val) {
                    if (val != null) setState(() => paymentMethod = val);
                  },
                ),
                const SizedBox(height: 14),
                TextField(
                  controller: notesController,
                  decoration: const InputDecoration(
                    labelText: 'ملاحظات السند (اختياري)',
                    hintText: 'سداد رسوم فحص أو خدمات بيطرية...',
                    border: OutlineInputBorder(),
                  ),
                ),
              ],
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.white,
            ),
            onPressed: () async {
              final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
              if (amt <= 0) {
                Get.snackbar('خطأ', 'يرجى إدخال مبلغ صحيح');
                return;
              }
              Get.back();
              await _financialRepo.recordClientPayment(
                ownerId: ownerId,
                amount: amt,
                paymentMethod: paymentMethod,
                notes: notesController.text.trim().isEmpty
                    ? null
                    : notesController.text.trim(),
              );
              await loadOwnerData();
              Get.snackbar(
                'تم حفظ سند القبض',
                'تم قيد دفعة بقيمة ${amt.toStringAsFixed(0)} ر.ي عبر ($paymentMethod) لحساب المربي',
                backgroundColor: AppColors.success.withValues(alpha: 0.2),
                colorText: AppColors.success,
              );
            },
            child: const Text('حفظ سند القبض'),
          ),
        ],
      ),
    );
  }
}

class OwnerDetailView extends StatelessWidget {
  const OwnerDetailView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(OwnerDetailController());

    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(controller.owner.value?.fullName ?? 'تفاصيل المربي'),
        ),
        actions: [
          IconButton(
            tooltip: AppStringsAr.refresh,
            icon: const Icon(Icons.refresh),
            onPressed: controller.loadOwnerData,
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add),
        label: const Text(
          'إضافة حيوان لهذا المربي',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        onPressed: () {
          Get.toNamed(
            AppRoutes.addPatient,
          )?.then((_) => controller.loadOwnerData());
        },
      ),
      body: Obx(() {
        if (controller.isLoading.value) {
          return const Center(child: CircularProgressIndicator());
        }

        final owner = controller.owner.value;
        if (owner == null) {
          return const Center(child: Text('لم يتم العثور على بيانات المربي'));
        }

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Owner Information Card
              Card(
                elevation: 3,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(18.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          CircleAvatar(
                            radius: 30,
                            backgroundColor: AppColors.primary,
                            child: const Icon(
                              Icons.person,
                              size: 36,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  owner.fullName,
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 18,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'مسجل بالنظام منذ: ${owner.createdAt != null && owner.createdAt!.length >= 10 ? owner.createdAt!.substring(0, 10) : "غير محدد"}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppColors.textSecondary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const Divider(height: 24),

                      // Contact Details
                      _buildInfoRow(
                        Icons.phone,
                        'رقم الهاتف',
                        owner.phonePrimary,
                      ),
                      if (owner.address != null &&
                          owner.address!.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        _buildInfoRow(
                          Icons.location_on_outlined,
                          'العنوان',
                          owner.address!,
                        ),
                      ],

                      const SizedBox(height: 16),
                      // Quick Action Buttons
                      Row(
                        children: [
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: controller.callOwner,
                              icon: const Icon(Icons.call, size: 18),
                              label: const Text('اتصال '),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.success,
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: controller.whatsappOwner,
                              icon: const Icon(Icons.chat, size: 18),
                              label: const Text('واتساب'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF25D366),
                                foregroundColor: Colors.white,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: controller.saveOwnerToPhoneContacts,
                          icon: const Icon(Icons.contact_phone_outlined, size: 18),
                          label: const Text('حفظ المربي في جهات اتصال الهاتف'),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.primary,
                            side: BorderSide(color: AppColors.primary.withValues(alpha: 0.5)),
                            padding: const EdgeInsets.symmetric(vertical: 9),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Owner Financial Statement & Balance Card
              _buildFinancialSummaryCard(context, controller),
              const SizedBox(height: 16),

              // Registered Pets Section
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'الحيوانات التابعة لهذا المربي (${controller.pets.length})',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                        color: AppColors.darkNeutral,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  TextButton.icon(
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('إضافة حيوان'),
                    onPressed: () {
                      Get.toNamed(
                        AppRoutes.addPatient,
                      )?.then((_) => controller.loadOwnerData());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 8),

              if (controller.pets.isEmpty)
                EmptyStateView(
                  icon: Icons.pets,
                  title: 'لا يوجد حيوانات أليفة مسجلة',
                  subtitle:
                      'يمكنك إضافة قط أو كلب أو حيوان أليف لهذا المربي الآن',
                  actionText: 'إضافة أول حيوان',
                  onAction: () {
                    Get.toNamed(
                      AppRoutes.addPatient,
                    )?.then((_) => controller.loadOwnerData());
                  },
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: controller.pets.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 12),
                  itemBuilder: (context, index) {
                    final pet = controller.pets[index];
                    return Card(
                      elevation: 2,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          // Seamlessly navigate to pet details
                          Get.toNamed(
                            AppRoutes.patientDetail,
                            arguments: pet.id,
                          )?.then((_) => controller.loadOwnerData());
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor:
                                            AppColors.secondaryLight,
                                        child: const Icon(
                                          Icons.pets,
                                          color: AppColors.primary,
                                          size: 24,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            pet.name,
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                          Text(
                                            '${pet.species} ${pet.breed != null ? "• ${pet.breed}" : ""}',
                                            style: const TextStyle(
                                              fontSize: 12,
                                              color: AppColors.textSecondary,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  StatusChip(
                                    label: pet.genderDisplayArabic,
                                    type: pet.gender == 'female'
                                        ? ChipStatusType.info
                                        : ChipStatusType.neutral,
                                  ),
                                ],
                              ),
                              const Divider(height: 20),

                              Row(
                                children: [
                                  const Icon(
                                    Icons.cake_outlined,
                                    size: 14,
                                    color: AppColors.primary,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'العمر: ${pet.ageDisplayArabic}',
                                    style: const TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  if (pet.latestWeight != null) ...[
                                    const SizedBox(width: 16),
                                    const Icon(
                                      Icons.monitor_weight_outlined,
                                      size: 14,
                                      color: AppColors.primary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'الوزن: ${pet.latestWeight} كجم',
                                      style: const TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ],
                              ),

                              if (pet.microchipNumber != null &&
                                  pet.microchipNumber!.isNotEmpty) ...[
                                const SizedBox(height: 6),
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.qr_code,
                                      size: 14,
                                      color: AppColors.textSecondary,
                                    ),
                                    const SizedBox(width: 6),
                                    Text(
                                      'رقم الشريحة: ${pet.microchipNumber}',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        color: AppColors.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                              const SizedBox(height: 12),

                              // Quick pet action links
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  TextButton.icon(
                                    icon: const Icon(
                                      Icons.medical_services_outlined,
                                      size: 16,
                                    ),
                                    label: const Text('كشف سريري جديد'),
                                    onPressed: () {
                                      Get.toNamed(
                                        AppRoutes.newConsultation,
                                        arguments: pet.id,
                                      );
                                    },
                                  ),
                                  ElevatedButton(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: AppColors.primary,
                                      foregroundColor: Colors.white,
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 12,
                                        vertical: 6,
                                      ),
                                    ),
                                    onPressed: () {
                                      Get.toNamed(
                                        AppRoutes.patientDetail,
                                        arguments: pet.id,
                                      )?.then(
                                        (_) => controller.loadOwnerData(),
                                      );
                                    },
                                    child: const Row(
                                      children: [
                                        Text('الملف الطبي'),
                                        SizedBox(width: 4),
                                        Icon(Icons.arrow_forward_ios, size: 12),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                ),
            ],
          ),
        );
      }),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Text(
          '$label: ',
          style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
        ),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: AppColors.darkNeutral,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialSummaryCard(
    BuildContext context,
    OwnerDetailController controller,
  ) {
    return Obx(() {
      final s = controller.accountSummary.value;
      if (s == null) return const SizedBox.shrink();

      return Card(
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 10),
                        const Expanded(
                          child: Text(
                            'الوضعية المالية',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: s.hasDebt
                          ? Colors.red.withValues(alpha: 0.15)
                          : AppColors.success.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      s.hasDebt
                          ? 'عليه ديون: ${s.balanceDue.toStringAsFixed(0)} ر.ي'
                          : 'الحساب خالص ومسدد',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: s.hasDebt ? Colors.red.shade800 : AppColors.success,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // 3 pills: Billed, Paid, Status
              Row(
                children: [
                  Expanded(
                    child: _buildFinancialPill(
                      'إجمالي الخدمات',
                      '${s.totalBilled.toStringAsFixed(0)} ر.ي',
                      Colors.blue.shade800,
                      Colors.blue.shade50,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildFinancialPill(
                      'إجمالي المسدد',
                      '${s.totalPaid.toStringAsFixed(0)} ر.ي',
                      Colors.green.shade800,
                      Colors.green.shade50,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: s.hasDebt
                        ? _buildFinancialPill(
                            'المتبقي آجل',
                            '${s.balanceDue.toStringAsFixed(0)} ر.ي',
                            Colors.red.shade800,
                            Colors.red.shade50,
                          )
                        : _buildFinancialPill(
                            'حالة الحساب',
                            'خالص ومسدد',
                            AppColors.success,
                            AppColors.success.withValues(alpha: 0.1),
                          ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: controller.openAccountStatement,
                      icon: const Icon(Icons.description_outlined, size: 16),
                      label: const Text(
                        'كشف الحساب (PDF/طباعة)',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: controller.showAddPaymentDialog,
                      icon: const Icon(Icons.add_card, size: 16),
                      label: const Text(
                        'سند قبض',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Full Financial Process Track Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: () => _showFinancialProcessTimeline(context, controller),
                  icon: const Icon(Icons.timeline_rounded, size: 18),
                  label: const Text(
                    'مسار وتتبع العمليات المالية والزيارات ⏱️',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    backgroundColor: AppColors.primary.withValues(alpha: 0.04),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    });
  }

  Widget _buildFinancialPill(
    String title,
    String value,
    Color color,
    Color bg,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        children: [
          Text(title, style: TextStyle(fontSize: 9.5, color: color)),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTimelineFilterChip(String value, String label, RxString currentFilter) {
    return Obx(() {
      final isSelected = currentFilter.value == value;
      return InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: () => currentFilter.value = value,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.primary : Colors.grey.shade100,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? AppColors.primary : Colors.grey.shade300,
            ),
          ),
          child: Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: isSelected ? Colors.white : Colors.black87,
            ),
          ),
        ),
      );
    });
  }

  void _showFinancialProcessTimeline(
    BuildContext context,
    OwnerDetailController controller,
  ) {
    final s = controller.accountSummary.value;
    final items = s?.statementItems ?? [];
    final filter = 'all'.obs;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        return Container(
          height: MediaQuery.of(context).size.height * 0.88,
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Sheet handle
              Center(
                child: Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),

              // Header
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.1),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.timeline_rounded, color: AppColors.primary, size: 22),
                        ),
                        const SizedBox(width: 12),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'مسار وتتبع العمليات المالية والزيارات',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'سجل الحركات من البداية حتى الآن (${controller.owner.value?.fullName ?? ""})',
                              style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                            ),
                          ],
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(ctx).pop(),
                    ),
                  ],
                ),
              ),

              // Summary bar
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: Colors.grey.shade200),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        children: [
                          const Text('إجمالي المطالبات', style: TextStyle(fontSize: 10, color: Colors.black54)),
                          const SizedBox(height: 2),
                          Text(
                            '${s?.totalBilled.toStringAsFixed(0) ?? 0} ر.ي',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.blue),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 24, width: 1, color: Colors.grey.shade300),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('إجمالي المسدد', style: TextStyle(fontSize: 10, color: Colors.black54)),
                          const SizedBox(height: 2),
                          Text(
                            '${s?.totalPaid.toStringAsFixed(0) ?? 0} ر.ي',
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Colors.green),
                          ),
                        ],
                      ),
                    ),
                    Container(height: 24, width: 1, color: Colors.grey.shade300),
                    Expanded(
                      child: Column(
                        children: [
                          const Text('الرصيد المتبقي', style: TextStyle(fontSize: 10, color: Colors.black54)),
                          const SizedBox(height: 2),
                          Text(
                            (s != null && s.hasDebt)
                                ? '${s.balanceDue.toStringAsFixed(0)} ر.ي دَين'
                                : '0 ر.ي (خالص)',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: (s != null && s.hasDebt) ? Colors.red.shade700 : Colors.teal,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Filter Tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                child: Row(
                  children: [
                    _buildTimelineFilterChip('all', 'جميع الحركات (${items.length})', filter),
                    const SizedBox(width: 8),
                    _buildTimelineFilterChip('paid', 'زيارات مدفوعة', filter),
                    const SizedBox(width: 8),
                    _buildTimelineFilterChip('unpaid', 'زيارات آجلة / غير مدفوعة', filter),
                    const SizedBox(width: 8),
                    _buildTimelineFilterChip('payment', 'سندات قبض', filter),
                  ],
                ),
              ),
              const Divider(height: 12),

              // Timeline List
              Expanded(
                child: Obx(() {
                  final activeFilter = filter.value;
                  final filteredItems = items.where((item) {
                    final isPayment = item.type == 'payment';
                    final isVisit = !isPayment;
                    final isFullyPaid = isVisit && (item.debit > 0 && item.credit >= item.debit);
                    final isUnpaid = isVisit && (item.debit > item.credit);

                    if (activeFilter == 'paid') return isFullyPaid;
                    if (activeFilter == 'unpaid') return isUnpaid;
                    if (activeFilter == 'payment') return isPayment;
                    return true;
                  }).toList();

                  if (filteredItems.isEmpty) {
                    return Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 48, color: Colors.grey.shade300),
                            const SizedBox(height: 12),
                            const Text(
                              'لا توجد عمليات تطابق التصنيف المختار',
                              style: TextStyle(color: Colors.black54, fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    );
                  }

                  return ListView.builder(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
                    itemCount: filteredItems.length,
                    itemBuilder: (context, idx) {
                      final item = filteredItems[idx];
                      final isLast = idx == filteredItems.length - 1;
                      return _buildTimelineItem(item, idx + 1, isLast);
                    },
                  );
                }),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTimelineItem(AccountStatementItem item, int sequence, bool isLast) {
    final isPayment = item.type == 'payment';
    final isVisit = !isPayment;
    final isFullyPaid = isVisit && (item.debit > 0 && item.credit >= item.debit);
    final isUnpaid = isVisit && (item.debit > item.credit);
    final remainingDebt = item.debit - item.credit;

    Color nodeColor;
    Color nodeBg;
    IconData nodeIcon;
    Color cardBg;
    Color cardBorder;
    Widget statusBadge;

    if (isPayment) {
      nodeColor = Colors.blue.shade700;
      nodeBg = Colors.blue.shade50;
      nodeIcon = Icons.payments_outlined;
      cardBg = const Color(0xFFF6F9FE);
      cardBorder = Colors.blue.shade200;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.blue.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'سند قبض 💵',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.blue.shade900,
          ),
        ),
      );
    } else if (isFullyPaid) {
      nodeColor = Colors.green.shade700;
      nodeBg = Colors.green.shade50;
      nodeIcon = Icons.check_circle_outline;
      cardBg = const Color(0xFFF3FBF6);
      cardBorder = Colors.green.shade300;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.green.shade100,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(
          'مدفوعة بالكامل ✅',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.green.shade900,
          ),
        ),
      );
    } else {
      // Unpaid or partially paid visit
      nodeColor = Colors.red.shade700;
      nodeBg = Colors.red.shade50;
      nodeIcon = Icons.warning_amber_rounded;
      cardBg = const Color(0xFFFFF7F7);
      cardBorder = Colors.red.shade300;
      statusBadge = Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.red.shade200),
        ),
        child: Text(
          item.credit > 0
              ? 'متبقي دين: ${remainingDebt.toStringAsFixed(0)} ر.ي ⚠️'
              : 'غير مدفوعة (آجلة) ⚠️',
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: Colors.red.shade900,
          ),
        ),
      );
    }

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Timeline Rail
          Column(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: nodeBg,
                  shape: BoxShape.circle,
                  border: Border.all(color: nodeColor, width: 2),
                ),
                child: Icon(nodeIcon, size: 16, color: nodeColor),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: Colors.grey.shade300,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),

          // Main Card
          Expanded(
            child: Padding(
              padding: EdgeInsets.only(bottom: isLast ? 0 : 16),
              child: Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: cardBg,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: cardBorder, width: 1.2),
                  boxShadow: [
                    BoxShadow(
                      color: nodeColor.withValues(alpha: 0.05),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Top row: sequence, date, badge
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade200,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                '#$sequence',
                                style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.calendar_today_outlined, size: 13, color: AppColors.textSecondary),
                            const SizedBox(width: 4),
                            Text(
                              item.date,
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                        statusBadge,
                      ],
                    ),
                    const SizedBox(height: 8),

                    // Service or Payment Title
                    Text(
                      item.description,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: AppColors.darkNeutral,
                      ),
                    ),

                    // Pet Name if available
                    if (item.petName != null && item.petName!.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          const Icon(Icons.pets, size: 14, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Text(
                            'المريض: ${item.petName}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ],

                    const Divider(height: 16),

                    // Financial Breakdown Row
                    if (isPayment)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'طريقة الدفع: ${item.paymentMethod ?? "نقداً"}',
                            style: const TextStyle(fontSize: 12, color: Colors.black87),
                          ),
                          Text(
                            '+${item.credit.toStringAsFixed(0)} ر.ي',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue.shade900,
                            ),
                          ),
                        ],
                      )
                    else
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'إجمالي الخدمة: ${item.debit.toStringAsFixed(0)} ر.ي',
                                style: const TextStyle(fontSize: 11.5, color: Colors.black87),
                              ),
                              Text(
                                'المدفوع: ${item.credit.toStringAsFixed(0)} ر.ي',
                                style: TextStyle(
                                  fontSize: 11.5,
                                  fontWeight: FontWeight.w600,
                                  color: isFullyPaid ? Colors.green.shade800 : Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          if (isUnpaid)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text(
                                    'متبقي كدين',
                                    style: TextStyle(fontSize: 9.5, color: Colors.red),
                                  ),
                                  Text(
                                    '${remainingDebt.toStringAsFixed(0)} ر.ي',
                                    style: TextStyle(
                                      fontSize: 13,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red.shade900,
                                    ),
                                  ),
                                ],
                              ),
                            )
                          else
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                'خالصة ومسددة',
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green.shade900,
                                ),
                              ),
                            ),
                        ],
                      ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
