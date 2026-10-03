import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/widgets/empty_state_view.dart';
import '../../../data/models/account_statement_model.dart';
import '../../../data/models/expense_model.dart';
import '../../../data/models/financial_transaction_model.dart';
import '../../../routes/app_routes.dart';
import '../controllers/financial_controller.dart';

class FinancialDashboardView extends StatelessWidget {
  const FinancialDashboardView({super.key});

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(FinancialController());

    return DefaultTabController(
      length: 3,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('الإدارة المالية والحسابات العامة'),
          actions: [
            IconButton(
              tooltip: AppStringsAr.refresh,
              icon: const Icon(Icons.refresh),
              onPressed: controller.loadFinancialData,
            ),
          ],
          bottom: const TabBar(
            indicatorColor: Colors.white,
            indicatorWeight: 3,
            labelColor: Colors.white,
            unselectedLabelColor: Colors.white70,
            labelStyle: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            tabs: [
              Tab(icon: Icon(Icons.receipt_long, size: 20), text: 'الحركات المالية'),
              Tab(icon: Icon(Icons.shopping_bag_outlined, size: 20), text: 'سجل المصروفات'),
              Tab(icon: Icon(Icons.people_outline, size: 20), text: 'كشوفات المربين والديون'),
            ],
          ),
        ),
        body: Obx(() {
          if (controller.isLoading.value) {
            return const Center(child: CircularProgressIndicator());
          }

          return Column(
            children: [
              // Top KPI Summary Cards & Action Buttons
              Container(
                color: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Column(
                  children: [
                    _buildKpiGrid(context, controller),
                    const SizedBox(height: 12),
                    _buildQuickActionButtons(context, controller),
                  ],
                ),
              ),
              const Divider(height: 1, thickness: 1),

              // TabBarViews
              Expanded(
                child: TabBarView(
                  children: [
                    // Tab 1: Transactions
                    _buildTransactionsTab(context, controller),

                    // Tab 2: Expenses
                    _buildExpensesTab(context, controller),

                    // Tab 3: Owners Accounts & Debts
                    _buildOwnersAccountsTab(context, controller),
                  ],
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  // --- TOP KPIS ---

  Widget _buildKpiGrid(BuildContext context, FinancialController controller) {
    return Row(
      children: [
        // Total Incomes
        Expanded(
          child: _buildKpiCard(
            title: 'إجمالي الإيرادات',
            amount: '${controller.totalIncome.value.toStringAsFixed(0)} ر.ي',
            icon: Icons.trending_up,
            color: const Color(0xFF2A9D8F),
            bgColor: const Color(0xFFE8F6F4),
          ),
        ),
        const SizedBox(width: 8),

        // Total Expenses
        Expanded(
          child: _buildKpiCard(
            title: 'إجمالي المصروفات',
            amount: '${controller.totalExpenses.value.toStringAsFixed(0)} ر.ي',
            icon: Icons.trending_down,
            color: const Color(0xFFE76F51),
            bgColor: const Color(0xFFFDEEE9),
          ),
        ),
        const SizedBox(width: 8),

        // Net Profit
        Expanded(
          child: _buildKpiCard(
            title: 'صافي الأرباح',
            amount: '${controller.netProfit.value.toStringAsFixed(0)} ر.ي',
            icon: Icons.account_balance_wallet,
            color: controller.netProfit.value >= 0 ? AppColors.primary : AppColors.critical,
            bgColor: controller.netProfit.value >= 0 ? AppColors.secondary.withValues(alpha: 0.1) : AppColors.criticalBackground,
          ),
        ),
        const SizedBox(width: 8),

        // Total Debts
        Expanded(
          child: _buildKpiCard(
            title: 'ديون المربين',
            amount: '${controller.totalDebts.value.toStringAsFixed(0)} ر.ي',
            icon: Icons.assignment_late_outlined,
            color: controller.totalDebts.value > 0 ? Colors.amber.shade900 : Colors.teal,
            bgColor: controller.totalDebts.value > 0 ? Colors.amber.shade50 : Colors.teal.shade50,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String title,
    required String amount,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.bold, color: color),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            amount,
            style: TextStyle(
              fontSize: 13.5,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuickActionButtons(BuildContext context, FinancialController controller) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showAddExpenseDialog(context, controller),
            icon: const Icon(Icons.add_shopping_cart, size: 18),
            label: const Text('تسجيل سند صرف (مصروف)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE76F51),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: () => _showAddPaymentDialog(context, controller),
            icon: const Icon(Icons.add_card, size: 18),
            label: const Text('تسجيل سند قبض (دفعة)', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5)),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A9D8F),
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 10),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
            ),
          ),
        ),
      ],
    );
  }

  // --- TAB 1: TRANSACTIONS ---

  Widget _buildTransactionsTab(BuildContext context, FinancialController controller) {
    final list = controller.transactions;

    return Column(
      children: [
        // Filter Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'الكل',
                  isSelected: controller.selectedTxType.value == 'all',
                  onSelected: () => controller.filterTransactions('all'),
                ),
                _buildFilterChip(
                  label: 'الإيرادات والخدمات',
                  isSelected: controller.selectedTxType.value == 'income',
                  onSelected: () => controller.filterTransactions('income'),
                ),
                _buildFilterChip(
                  label: 'سندات القبض (الدفعات)',
                  isSelected: controller.selectedTxType.value == 'payment',
                  onSelected: () => controller.filterTransactions('payment'),
                ),
                _buildFilterChip(
                  label: 'المصروفات',
                  isSelected: controller.selectedTxType.value == 'expense',
                  onSelected: () => controller.filterTransactions('expense'),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: list.isEmpty
              ? const EmptyStateView(
                  title: 'لا توجد حركات مالية',
                  subtitle: 'سجل العمليات والكشوفات والدفعات سيظهر هنا',
                  icon: Icons.receipt_long,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final tx = list[index];
                    return _buildTransactionCard(context, tx);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTransactionCard(BuildContext context, FinancialTransactionModel tx) {
    final isExpense = tx.transactionType == 'expense';
    final isPayment = tx.transactionType == 'payment';

    final Color badgeColor = isExpense
        ? const Color(0xFFE76F51)
        : (isPayment ? const Color(0xFF2A9D8F) : AppColors.primary);

    final IconData badgeIcon = isExpense
        ? Icons.arrow_outward
        : (isPayment ? Icons.arrow_downward : Icons.medical_services_outlined);

    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: badgeColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(badgeIcon, color: badgeColor, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tx.categoryDisplayArabic,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                      Text(
                        '${tx.amount.toStringAsFixed(0)} ر.ي',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: isExpense ? const Color(0xFFE76F51) : const Color(0xFF2A9D8F),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        tx.ownerName != null
                            ? '${tx.ownerName} ${tx.petName != null ? "(${tx.petName})" : ""}'
                            : (tx.notes ?? 'مصروف عيادة عام'),
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                      Text(
                        tx.transactionDate.length >= 10 ? tx.transactionDate.substring(0, 10) : tx.transactionDate,
                        style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  if (tx.hasRemainingDebt) ...[
                    const SizedBox(height: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: AppColors.criticalBackground,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'متبقي دين مستحق: ${tx.remainingAmount.toStringAsFixed(0)} ر.ي',
                        style: const TextStyle(
                          fontSize: 10.5,
                          fontWeight: FontWeight.bold,
                          color: AppColors.critical,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 2: EXPENSES ---

  Widget _buildExpensesTab(BuildContext context, FinancialController controller) {
    final list = controller.expenses;

    return Column(
      children: [
        // Category Filter Chips
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  label: 'الكل',
                  isSelected: controller.selectedExpenseCategory.value == 'all',
                  onSelected: () => controller.filterExpenses('all'),
                ),
                _buildFilterChip(
                  label: 'تشغيلية',
                  isSelected: controller.selectedExpenseCategory.value == 'operating',
                  onSelected: () => controller.filterExpenses('operating'),
                ),
                _buildFilterChip(
                  label: 'مستلزمات طبية',
                  isSelected: controller.selectedExpenseCategory.value == 'medical_supplies',
                  onSelected: () => controller.filterExpenses('medical_supplies'),
                ),
                _buildFilterChip(
                  label: 'أدوية ومخزون',
                  isSelected: controller.selectedExpenseCategory.value == 'medicines',
                  onSelected: () => controller.filterExpenses('medicines'),
                ),
                _buildFilterChip(
                  label: 'صيانة ومعدات',
                  isSelected: controller.selectedExpenseCategory.value == 'maintenance',
                  onSelected: () => controller.filterExpenses('maintenance'),
                ),
                _buildFilterChip(
                  label: 'إيجار',
                  isSelected: controller.selectedExpenseCategory.value == 'rent',
                  onSelected: () => controller.filterExpenses('rent'),
                ),
              ],
            ),
          ),
        ),

        Expanded(
          child: list.isEmpty
              ? const EmptyStateView(
                  title: 'لا توجد مصروفات مسجلة',
                  subtitle: 'يمكنك إضافة مصروف أو فاتورة جديدة عبر زر "تسجيل سند صرف"',
                  icon: Icons.shopping_cart_outlined,
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: list.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final exp = list[index];
                    return _buildExpenseCard(context, controller, exp);
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildExpenseCard(
    BuildContext context,
    FinancialController controller,
    ExpenseModel exp,
  ) {
    return Card(
      elevation: 1.5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: const Color(0xFFE76F51).withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.receipt, color: Color(0xFFE76F51), size: 22),
        ),
        title: Text(exp.title, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    exp.categoryDisplayArabic,
                    style: TextStyle(fontSize: 10, color: Colors.grey.shade800),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  exp.expenseDate,
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
            if (exp.notes != null && exp.notes!.isNotEmpty) ...[
              const SizedBox(height: 3),
              Text(
                exp.notes!,
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              '${exp.amount.toStringAsFixed(0)} ر.ي',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: Color(0xFFE76F51),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
              onPressed: () {
                Get.defaultDialog(
                  title: 'تأكيد الحذف',
                  middleText: 'هل تريد بالتأكيد حذف هذا المصروف؟',
                  textConfirm: 'نعم، احذف',
                  textCancel: 'إلغاء',
                  confirmTextColor: Colors.white,
                  buttonColor: Colors.red,
                  onConfirm: () {
                    Get.back();
                    if (exp.id != null) controller.deleteExpense(exp.id!);
                  },
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // --- TAB 3: OWNERS ACCOUNTS & DEBTS ---

  Widget _buildOwnersAccountsTab(BuildContext context, FinancialController controller) {
    return Column(
      children: [
        // Search Bar
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'بحث باسم المربي أو رقم الهاتف...',
              prefixIcon: const Icon(Icons.search),
              contentPadding: const EdgeInsets.symmetric(vertical: 0, horizontal: 14),
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
              filled: true,
              fillColor: Colors.grey.shade100,
            ),
            onChanged: (val) => controller.clientSearchQuery.value = val,
          ),
        ),

        Expanded(
          child: Obx(() {
            final list = controller.filteredOwnersAccounts;
            if (list.isEmpty) {
              return const EmptyStateView(
                title: 'لا يوجد مربين مطابقين للبحث',
                subtitle: 'تأكد من كتابة الاسم أو رقم الهاتف بشكل صحيح',
                icon: Icons.person_search_outlined,
              );
            }

            return ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: list.length,
              separatorBuilder: (context, index) => const SizedBox(height: 10),
              itemBuilder: (context, index) {
                final acc = list[index];
                return _buildOwnerAccountCard(context, controller, acc);
              },
            );
          }),
        ),
      ],
    );
  }

  Widget _buildOwnerAccountCard(
    BuildContext context,
    FinancialController controller,
    OwnerAccountSummary acc,
  ) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.1),
                  child: const Icon(Icons.person, color: AppColors.primary, size: 22),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        acc.ownerName,
                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                      Text(
                        acc.phonePrimary,
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: acc.hasDebt ? AppColors.criticalBackground : AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    acc.hasDebt
                        ? 'دين: ${acc.balanceDue.toStringAsFixed(0)} ر.ي'
                        : 'خالص (0 ر.ي)',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: acc.hasDebt ? AppColors.critical : AppColors.success,
                    ),
                  ),
                ),
              ],
            ),
            const Divider(height: 18),

            // Financial mini stats
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildSmallStat('المطالبات (مدين)', '${acc.totalBilled.toStringAsFixed(0)} ر.ي'),
                _buildSmallStat('المسدد (دائن)', '${acc.totalPaid.toStringAsFixed(0)} ر.ي'),
                _buildSmallStat('عدد الحركات', '${acc.statementItems.length} حركة'),
              ],
            ),
            const SizedBox(height: 12),

            // View Detailed Statement Button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () {
                  Get.toNamed(
                    AppRoutes.ownerAccountStatement,
                    arguments: acc.ownerId,
                  )?.then((_) => controller.loadFinancialData());
                },
                icon: const Icon(Icons.description_outlined, size: 16),
                label: const Text(
                  'عرض كشف الحساب المالي التفصيلي (PDF & طباعة)',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12.5),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSmallStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 10.5, color: AppColors.textSecondary)),
        const SizedBox(height: 2),
        Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onSelected,
  }) {
    return Padding(
      padding: const EdgeInsets.only(left: 8),
      child: FilterChip(
        label: Text(label),
        selected: isSelected,
        onSelected: (_) => onSelected(),
        selectedColor: AppColors.primary.withValues(alpha: 0.15),
        checkmarkColor: AppColors.primary,
        labelStyle: TextStyle(
          color: isSelected ? AppColors.primary : Colors.grey.shade700,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          fontSize: 12,
        ),
      ),
    );
  }

  // --- DIALOGS ---

  void _showAddExpenseDialog(BuildContext context, FinancialController controller) {
    final titleController = TextEditingController();
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String category = 'operating';

    final now = DateTime.now();
    final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.shopping_cart_checkout, color: Color(0xFFE76F51)),
            SizedBox(width: 8),
            Text('تسجيل سند صرف ومصروف جديد'),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: titleController,
                    decoration: const InputDecoration(
                      labelText: 'بيان المصروف / الفاتورة *',
                      hintText: 'مثال: فاتورة كهرباء، شراء شاش ومستلزمات...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: category,
                    decoration: const InputDecoration(
                      labelText: 'تصنيف المصروف *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'operating', child: Text('مصاريف تشغيلية (كهرباء/طاقة/إنترنت)')),
                      DropdownMenuItem(value: 'medical_supplies', child: Text('مستلزمات طبية وتخدير وتعقيم')),
                      DropdownMenuItem(value: 'medicines', child: Text('طلبية أدوية ومخزون صيدلية')),
                      DropdownMenuItem(value: 'maintenance', child: Text('صيانة أجهزة ومعايرة')),
                      DropdownMenuItem(value: 'rent', child: Text('إيجار مقر العيادة')),
                      DropdownMenuItem(value: 'salaries', child: Text('رواتب ومكافآت')),
                      DropdownMenuItem(value: 'other', child: Text('مصروفات نثرية أخرى')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => category = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ المدفوع (ر.ي) *',
                      hintText: 'مثال: 45000',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات إضافية (اختياري)',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFE76F51),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              final title = titleController.text.trim();
              final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
              if (title.isEmpty || amt <= 0) {
                Get.snackbar('خطأ', 'يرجى إدخال بيان المصروف ومبلغ صحيح');
                return;
              }
              Get.back();
              controller.addExpense(
                title: title,
                category: category,
                amount: amt,
                expenseDate: dateStr,
                notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
              );
            },
            child: const Text('حفظ سند الصرف'),
          ),
        ],
      ),
    );
  }

  void _showAddPaymentDialog(BuildContext context, FinancialController controller) {
    int? selectedOwnerId = controller.allOwners.isNotEmpty ? controller.allOwners.first.id : null;
    final amountController = TextEditingController();
    final notesController = TextEditingController();
    String paymentMethod = 'cash';

    Get.dialog(
      AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.add_card, color: Color(0xFF2A9D8F)),
            SizedBox(width: 8),
            Text('تسجيل سند قبض / تحصيل دفعة'),
          ],
        ),
        content: StatefulBuilder(
          builder: (context, setState) {
            return SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  DropdownButtonFormField<int>(
                    initialValue: selectedOwnerId,
                    decoration: const InputDecoration(
                      labelText: 'اختر العميل / المربي *',
                      border: OutlineInputBorder(),
                    ),
                    items: controller.allOwners.map((o) {
                      return DropdownMenuItem<int>(
                        value: o.id,
                        child: Text('${o.fullName} (${o.phonePrimary})'),
                      );
                    }).toList(),
                    onChanged: (val) {
                      if (val != null) setState(() => selectedOwnerId = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: 'المبلغ المحصل (ر.ي) *',
                      hintText: 'مثال: 15000',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String>(
                    initialValue: paymentMethod,
                    decoration: const InputDecoration(
                      labelText: 'طريقة الدفع *',
                      border: OutlineInputBorder(),
                    ),
                    items: const [
                      DropdownMenuItem(value: 'cash', child: Text('نقداً (كاش)')),
                      DropdownMenuItem(value: 'bank_transfer', child: Text('تحويل بنكي / محفظة إلكترونية')),
                    ],
                    onChanged: (val) {
                      if (val != null) setState(() => paymentMethod = val);
                    },
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: notesController,
                    decoration: const InputDecoration(
                      labelText: 'ملاحظات السند (اختياري)',
                      hintText: 'دفعة سداد حساب...',
                      border: OutlineInputBorder(),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('إلغاء')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF2A9D8F),
              foregroundColor: Colors.white,
            ),
            onPressed: () {
              if (selectedOwnerId == null) {
                Get.snackbar('خطأ', 'يرجى اختيار المربي أولاً');
                return;
              }
              final amt = double.tryParse(amountController.text.trim()) ?? 0.0;
              if (amt <= 0) {
                Get.snackbar('خطأ', 'يرجى إدخال مبلغ صحيح');
                return;
              }
              Get.back();
              controller.recordClientPayment(
                ownerId: selectedOwnerId!,
                amount: amt,
                paymentMethod: paymentMethod,
                notes: notesController.text.trim().isEmpty ? null : notesController.text.trim(),
              );
            },
            child: const Text('حفظ سند القبض'),
          ),
        ],
      ),
    );
  }
}
