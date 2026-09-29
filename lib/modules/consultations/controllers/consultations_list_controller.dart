import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../data/models/consultation_model.dart';
import '../../../data/repositories/consultation_repository.dart';

class ConsultationsListController extends GetxController {
  final ConsultationRepository _consultationRepo = ConsultationRepository();

  final RxList<ConsultationModel> allConsultations = <ConsultationModel>[].obs;
  final RxList<ConsultationModel> filteredConsultations = <ConsultationModel>[].obs;
  final RxBool isLoading = false.obs;

  final searchController = TextEditingController();
  final RxString selectedFilter = 'all'.obs; // all, today, this_week, this_month

  @override
  void onInit() {
    super.onInit();
    loadConsultations();
  }

  Future<void> loadConsultations() async {
    isLoading.value = true;
    try {
      final list = await _consultationRepo.getAllConsultations();
      allConsultations.assignAll(list);
      applyFilter();
    } finally {
      isLoading.value = false;
    }
  }

  void onSearchChanged(String query) {
    applyFilter();
  }

  void setFilter(String filter) {
    selectedFilter.value = filter;
    applyFilter();
  }

  void applyFilter() {
    final query = searchController.text.trim().toLowerCase();
    final now = DateTime.now();
    final todayStr = now.toIso8601String().substring(0, 10);

    List<ConsultationModel> results = List.from(allConsultations);

    // Apply time filter
    if (selectedFilter.value == 'today') {
      results = results.where((c) => c.visitDate.startsWith(todayStr)).toList();
    } else if (selectedFilter.value == 'this_week') {
      final weekAgo = now.subtract(const Duration(days: 7));
      results = results.where((c) {
        final d = DateTime.tryParse(c.visitDate);
        return d != null && d.isAfter(weekAgo);
      }).toList();
    } else if (selectedFilter.value == 'this_month') {
      final monthAgo = now.subtract(const Duration(days: 30));
      results = results.where((c) {
        final d = DateTime.tryParse(c.visitDate);
        return d != null && d.isAfter(monthAgo);
      }).toList();
    }

    // Apply text search query
    if (query.isNotEmpty) {
      results = results.where((c) {
        final pet = (c.petName ?? '').toLowerCase();
        final owner = (c.ownerName ?? '').toLowerCase();
        final diag = c.diagnosis.toLowerCase();
        final complaint = (c.symptoms ?? '').toLowerCase();
        return pet.contains(query) || owner.contains(query) || diag.contains(query) || complaint.contains(query);
      }).toList();
    }

    filteredConsultations.assignAll(results);
  }

  Future<void> deleteConsultation(int id) async {
    await _consultationRepo.deleteConsultation(id);
    await loadConsultations();
  }

  @override
  void onClose() {
    searchController.dispose();
    super.onClose();
  }
}
