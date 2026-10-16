import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/pet_model.dart';
import '../../../data/repositories/pet_repository.dart';

class PatientListController extends GetxController {
  final PetRepository _petRepo;

  PatientListController(this._petRepo);

  final RxList<PetModel> patients = <PetModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString selectedSpeciesFilter = 'الكل'.obs;

  final searchController = TextEditingController();

  @override
  void onInit() {
    super.onInit();
    loadPatients();
  }

  Future<void> loadPatients() async {
    isLoading.value = true;
    try {
      final list = await _petRepo.getAllPets();
      patients.assignAll(list);
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> search(String query) async {
    if (query.trim().isEmpty) {
      loadPatients();
      return;
    }
    isLoading.value = true;
    try {
      final results = await _petRepo.searchPets(query);
      patients.assignAll(results);
    } finally {
      isLoading.value = false;
    }
  }

  List<PetModel> get filteredPatients {
    final filter = selectedSpeciesFilter.value;
    if (filter == 'الكل') return patients;
    return patients.where((p) => p.species.contains(filter)).toList();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
