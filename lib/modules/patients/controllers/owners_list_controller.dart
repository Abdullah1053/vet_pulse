import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/services/device_contact_service.dart';
import '../../../data/repositories/pet_repository.dart';

class OwnersListController extends GetxController {
  final PetRepository _petRepo;

  OwnersListController([PetRepository? petRepo])
      : _petRepo = petRepo ??
            (Get.isRegistered<PetRepository>()
                ? Get.find<PetRepository>()
                : Get.put(PetRepository(), permanent: true));

  final RxList<Map<String, dynamic>> owners = <Map<String, dynamic>>[].obs;
  final RxList<Map<String, dynamic>> filteredOwners = <Map<String, dynamic>>[].obs;
  final RxBool isLoading = false.obs;
  final searchController = TextEditingController();

  int get totalPetsCount => owners.fold<int>(
        0,
        (sum, o) => sum + (o['pets_count'] as int? ?? 0),
      );

  @override
  void onInit() {
    super.onInit();
    loadOwners();
  }

  Future<void> loadOwners() async {
    isLoading.value = true;
    try {
      final list = await _petRepo.getOwnersWithPetCounts();
      owners.assignAll(list);
      applyFilter();
    } finally {
      isLoading.value = false;
    }
  }

  void onSearch(String q) {
    applyFilter();
  }

  void clearSearch() {
    searchController.clear();
    applyFilter();
  }

  void applyFilter() {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      filteredOwners.assignAll(owners);
      return;
    }
    filteredOwners.assignAll(owners.where((o) {
      final name = (o['full_name'] as String? ?? '').toLowerCase();
      final phone = (o['phone_primary'] as String? ?? '').toLowerCase();
      final addr = (o['address'] as String? ?? '').toLowerCase();
      return name.contains(query) || phone.contains(query) || addr.contains(query);
    }).toList());
  }

  Future<void> callOwner([String? phone]) async {
    if (phone == null || phone.isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final uri = Uri.parse('tel:$clean');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> whatsappOwner([String? phone, String? name]) async {
    if (phone == null || phone.isEmpty) return;
    final clean = phone.replaceAll(RegExp(r'\D'), '');
    final targetName = name ?? '';
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

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
