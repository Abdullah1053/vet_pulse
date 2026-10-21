import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_payment_methods.dart';
import '../../../core/services/data_sync_service.dart';
import '../../../core/services/device_contact_service.dart';
import '../../../data/models/account_statement_model.dart';
import '../../../data/models/owner_model.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/repositories/financial_repository.dart';
import '../../../data/repositories/pet_repository.dart';
import '../../../routes/app_routes.dart';

class OwnerDetailController extends GetxController {
  final PetRepository _petRepo;
  final FinancialRepository _financialRepo;

  OwnerDetailController([PetRepository? petRepo, FinancialRepository? financialRepo])
      : _petRepo = petRepo ??
            (Get.isRegistered<PetRepository>()
                ? Get.find<PetRepository>()
                : Get.put(PetRepository(), permanent: true)),
        _financialRepo = financialRepo ??
            (Get.isRegistered<FinancialRepository>()
                ? Get.find<FinancialRepository>()
                : Get.put(FinancialRepository(), permanent: true));

  final Rx<OwnerModel?> owner = Rx<OwnerModel?>(null);
  final RxList<PetModel> pets = <PetModel>[].obs;
  final Rx<OwnerAccountSummary?> accountSummary = Rx<OwnerAccountSummary?>(null);
  final RxBool isLoadingDetail = false.obs;
  int? currentOwnerId;

  @override
  void onInit() {
    super.onInit();
    final args = Get.arguments;
    if (args is int) {
      currentOwnerId = args;
      loadOwnerData(args);
    } else if (args is OwnerModel) {
      currentOwnerId = args.id;
      owner.value = args;
      if (args.id != null) {
        loadOwnerData(args.id!);
      }
    }
  }

  Future<void> loadOwnerData([int? id]) async {
    final targetId = id ?? currentOwnerId;
    if (targetId == null) return;
    currentOwnerId = targetId;

    isLoadingDetail.value = true;
    try {
      final o = await _petRepo.getOwnerById(targetId);
      owner.value = o;
      final petList = await _petRepo.getPetsByOwnerId(targetId);
      pets.assignAll(petList);
      final s = await _financialRepo.getOwnerAccountSummary(targetId);
      accountSummary.value = s;
    } finally {
      isLoadingDetail.value = false;
    }
  }

  Future<void> callOwner([String? phone]) async {
    final targetPhone = phone ?? owner.value?.phonePrimary;
    if (targetPhone == null || targetPhone.isEmpty) return;
    final clean = targetPhone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> whatsappOwner([String? phone, String? name]) async {
    final targetPhone = phone ?? owner.value?.phonePrimary;
    final targetName = name ?? owner.value?.fullName ?? '';
    if (targetPhone == null || targetPhone.isEmpty) return;
    final clean = targetPhone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse(
      'whatsapp://send?phone=$clean&text=${Uri.encodeComponent("مرحباً أ/ $targetName")}',
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> saveToContacts(String name, String phone) async {
    await DeviceContactService.saveOwnerToContacts(name: name, phone: phone);
  }

  Future<void> saveOwnerToPhoneContacts() async {
    final o = owner.value;
    if (o == null) return;
    await saveToContacts(o.fullName, o.phonePrimary);
  }

  void showAddPaymentDialog() {
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    final paymentMethod = AppPaymentMethods.cash.obs;

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Icon(Icons.receipt_long, color: AppColors.success),
            const SizedBox(width: 8),
            Obx(() => Text('سند قبض لحساب: ${owner.value?.fullName ?? ""}')),
          ],
        ),
        content: Column(
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
            Obx(
              () => DropdownButtonFormField<String>(
                isExpanded: true,
                initialValue: paymentMethod.value,
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
                  if (val != null) paymentMethod.value = val;
                },
              ),
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
              await recordPayment(
                amount: amt,
                paymentMethod: paymentMethod.value,
                notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
              );
            },
            child: const Text('حفظ سند القبض'),
          ),
        ],
      ),
    );
  }

  void copyPhoneToClipboard(String phone) {
    Clipboard.setData(ClipboardData(text: phone));
    Get.snackbar(
      'تم النسخ',
      'تم نسخ رقم الهاتف ($phone) إلى الحافظة',
      snackPosition: SnackPosition.BOTTOM,
      duration: const Duration(seconds: 2),
      backgroundColor: Colors.grey.shade800,
      colorText: Colors.white,
    );
  }

  void openAccountStatement() {
    if (currentOwnerId == null) return;
    Get.toNamed(
      AppRoutes.ownerAccountStatement,
      arguments: currentOwnerId,
    )?.then((_) => loadOwnerData());
  }

  Future<void> recordPayment({
    required double amount,
    required String paymentMethod,
    String? notes,
  }) async {
    if (currentOwnerId == null) return;
    try {
      await _financialRepo.recordClientPayment(
        ownerId: currentOwnerId!,
        amount: amount,
        paymentMethod: paymentMethod,
        notes: notes,
      );
      await loadOwnerData();
      DataSyncService.notifyFinancialChanged();
      Get.snackbar(
        'تم حفظ سند القبض',
        'تم قيد دفعة بقيمة ${amount.toStringAsFixed(0)} ر.ي عبر ($paymentMethod) لحساب المربي',
        backgroundColor: AppColors.success.withValues(alpha: 0.2),
        colorText: AppColors.success,
      );
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر تسجيل سند القبض: $e', backgroundColor: AppColors.criticalBackground);
    }
  }
}
