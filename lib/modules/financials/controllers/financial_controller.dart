import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/services/data_sync_service.dart';
import '../../../data/models/account_statement_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/financial_transaction_model.dart';
import '../../../data/models/owner_model.dart';
import '../../../data/repositories/financial_repository.dart';
import '../../../data/repositories/pet_repository.dart';

class FinancialController extends GetxController {
  final FinancialRepository _repo = FinancialRepository();
  final PetRepository _petRepo = PetRepository();

  final RxBool isLoading = true.obs;

  // Summary KPIs
  final RxDouble totalIncome = 0.0.obs;
  final RxDouble totalExpenses = 0.0.obs;
  final RxDouble netProfit = 0.0.obs;
  final RxDouble totalDebts = 0.0.obs;
  final RxInt consultCount = 0.obs;
  final RxDouble consultTotal = 0.0.obs;
  final RxInt surgCount = 0.obs;
  final RxDouble surgTotal = 0.0.obs;

  // All unfiltered records cached in memory for seamless 0ms instant filtering
  final RxList<FinancialTransactionModel> allTransactions = <FinancialTransactionModel>[].obs;
  final RxList<ExpenseModel> allExpenses = <ExpenseModel>[].obs;
  final RxList<OwnerAccountSummary> ownersAccounts = <OwnerAccountSummary>[].obs;
  final RxList<OwnerModel> allOwners = <OwnerModel>[].obs;

  // Filters
  final RxString selectedExpenseCategory = 'all'.obs;
  final RxString selectedTxType = 'all'.obs;
  final RxString clientSearchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    loadFinancialData();
  }

  Future<void> loadFinancialData({bool isSilent = false}) async {
    if (!isSilent && allTransactions.isEmpty && allExpenses.isEmpty) {
      isLoading.value = true;
    }
    try {
      // 1. Load summary KPIs
      final summary = await _repo.getFinancialSummary();
      totalIncome.value = summary['totalIncome'] ?? 0.0;
      totalExpenses.value = summary['totalExpenses'] ?? 0.0;
      netProfit.value = summary['netProfit'] ?? 0.0;
      totalDebts.value = summary['totalDebts'] ?? 0.0;
      consultCount.value = summary['consultCount'] ?? 0;
      consultTotal.value = summary['consultTotal'] ?? 0.0;
      surgCount.value = summary['surgCount'] ?? 0;
      surgTotal.value = summary['surgTotal'] ?? 0.0;

      // 2. Load all transactions for in-memory instant filtering
      final txList = await _repo.getAllTransactions(limit: 500);
      allTransactions.assignAll(txList);

      // 3. Load all expenses for in-memory instant filtering
      final expList = await _repo.getAllExpenses();
      allExpenses.assignAll(expList);

      // 4. Load owners & account balances
      final ownersList = await _petRepo.getAllOwners();
      allOwners.assignAll(ownersList);

      final accountsList = await _repo.getAllOwnersBalances();
      ownersAccounts.assignAll(accountsList);

      // Update totalDebts from owners balances if higher
      final sumOwnerDebts = accountsList.fold<double>(0.0, (acc, item) => acc + (item.balanceDue > 0 ? item.balanceDue : 0));
      if (sumOwnerDebts > totalDebts.value) {
        totalDebts.value = sumOwnerDebts;
      }
    } catch (e) {
      debugPrint('[FinancialController] Error loading financial data: $e');
    } finally {
      isLoading.value = false;
    }
  }

  // Instant in-memory filters without any loading indicators or screen reloading
  List<FinancialTransactionModel> get filteredTransactions {
    final type = selectedTxType.value;
    if (type == 'all') return allTransactions;
    return allTransactions.where((t) => t.transactionType == type).toList();
  }

  List<ExpenseModel> get filteredExpenses {
    final cat = selectedExpenseCategory.value;
    if (cat == 'all') return allExpenses;
    return allExpenses.where((e) => e.category == cat).toList();
  }

  void filterExpenses(String category) {
    selectedExpenseCategory.value = category;
  }

  void filterTransactions(String type) {
    selectedTxType.value = type;
  }

  List<OwnerAccountSummary> get filteredOwnersAccounts {
    final q = clientSearchQuery.value.trim().toLowerCase();
    if (q.isEmpty) {
      return ownersAccounts;
    }
    return ownersAccounts.where((acc) {
      return acc.ownerName.toLowerCase().contains(q) ||
          acc.phonePrimary.contains(q) ||
          (acc.phoneSecondary != null && acc.phoneSecondary!.contains(q));
    }).toList();
  }

  // --- ACTIONS ---

  Future<bool> addExpense({
    required String title,
    required String category,
    required double amount,
    required String expenseDate,
    String? notes,
  }) async {
    try {
      final expense = ExpenseModel(
        title: title,
        category: category,
        amount: amount,
        expenseDate: expenseDate,
        notes: notes,
      );
      await _repo.insertExpense(expense);
      await loadFinancialData(isSilent: true);
      DataSyncService.notifyAllChanged();

      Get.snackbar(
        'تم تسجيل المصروف بنجاح',
        'تم تسجيل سند الصرف بقيمة ${amount.toStringAsFixed(0)} ر.ي وإضافته للمصروفات',
        backgroundColor: AppColors.success.withValues(alpha: 0.2),
        colorText: AppColors.success,
        duration: const Duration(seconds: 3),
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر حفظ المصروف: $e',
        backgroundColor: AppColors.criticalBackground,
        colorText: AppColors.critical,
      );
      return false;
    }
  }

  Future<void> deleteExpense(int id) async {
    try {
      await _repo.deleteExpense(id);
      await loadFinancialData(isSilent: true);
      DataSyncService.notifyAllChanged();
      Get.snackbar(
        'تم الحذف',
        'تم حذف سند الصرف بنجاح وتحديث الرصيد',
        backgroundColor: Colors.grey.shade200,
      );
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر حذف المصروف: $e');
    }
  }

  Future<bool> recordClientPayment({
    required int ownerId,
    required double amount,
    int? petId,
    String paymentMethod = 'cash',
    String? notes,
  }) async {
    try {
      await _repo.recordClientPayment(
        ownerId: ownerId,
        amount: amount,
        petId: petId,
        paymentMethod: paymentMethod,
        notes: notes,
      );
      await loadFinancialData(isSilent: true);
      DataSyncService.notifyAllChanged();

      Get.snackbar(
        'تم تسجيل سند القبض بنجاح',
        'تم قيد دفعة نقدية بقيمة ${amount.toStringAsFixed(0)} ر.ي في حساب العميل',
        backgroundColor: AppColors.success.withValues(alpha: 0.2),
        colorText: AppColors.success,
        duration: const Duration(seconds: 3),
      );
      return true;
    } catch (e) {
      Get.snackbar(
        'خطأ',
        'تعذر قيد الدفعة: $e',
        backgroundColor: AppColors.criticalBackground,
        colorText: AppColors.critical,
      );
      return false;
    }
  }
}
