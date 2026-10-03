import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vet_pulse/data/database/database_helper.dart';
import 'package:vet_pulse/data/database/database_tables.dart';
import 'package:vet_pulse/data/database/demo_data_seeder.dart';
import 'package:vet_pulse/data/models/clinic_model.dart';
import 'package:vet_pulse/data/models/expense_model.dart';
import 'package:vet_pulse/data/repositories/financial_repository.dart';
import 'package:vet_pulse/modules/financials/utils/financial_statement_pdf_helper.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  setUpAll(() async {
    await DemoDataSeeder.resetDemoData();
  });

  group('Financial & Account Statement Tests', () {
    final repo = FinancialRepository();

    test('Financial summary calculates correct KPIs', () async {
      final summary = await repo.getFinancialSummary();
      expect(summary['totalIncome'], greaterThan(0));
      expect(summary['totalExpenses'], greaterThan(0));
      expect(summary['totalDebts'], greaterThanOrEqualTo(10000.0));
    });

    test('Inserting new expense reflects in ledger and summary', () async {
      final now = DateTime.now();
      final dateStr = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

      final expense = ExpenseModel(
        title: 'شراء مطهرات ومعقمات جراحية',
        category: 'medical_supplies',
        amount: 15000.0,
        expenseDate: dateStr,
        notes: 'شراء عاجل',
      );

      final id = await repo.insertExpense(expense);
      expect(id, greaterThan(0));

      final allExpenses = await repo.getAllExpenses();
      expect(allExpenses.any((e) => e.id == id), isTrue);

      // Clean up
      await repo.deleteExpense(id);
    });

    test('Client payment voucher updates balance due in account statement', () async {
      final db = await DatabaseHelper.instance.database;
      final owners = await db.query(DatabaseTables.tableOwners);
      final firstOwnerId = owners.first['id'] as int;

      final initialStatement = await repo.getOwnerAccountSummary(firstOwnerId);
      expect(initialStatement, isNotNull);
      final initialBalance = initialStatement!.balanceDue;

      // Record 5,000 YER payment for Owner
      await repo.recordClientPayment(
        ownerId: firstOwnerId,
        amount: 5000.0,
        paymentMethod: 'cash',
        notes: 'سداد جزئي للاختبار',
      );

      final updatedStatement = await repo.getOwnerAccountSummary(firstOwnerId);
      expect(updatedStatement, isNotNull);
      expect(updatedStatement!.totalPaid, equals(initialStatement.totalPaid + 5000.0));
      expect(updatedStatement.balanceDue, equals(initialBalance - 5000.0));
    });

    test('FinancialStatementPdfHelper generates PDF without exceptions', () async {
      final db = await DatabaseHelper.instance.database;
      final owners = await db.query(DatabaseTables.tableOwners);
      final firstOwnerId = owners.first['id'] as int;

      final statement = await repo.getOwnerAccountSummary(firstOwnerId);
      expect(statement, isNotNull);

      final clinic = ClinicModel(
        id: 1,
        clinicName: 'عيادة نبض البيطرية التجريبية',
        doctorName: 'د. عبدالله خالد السالم',
        phone: '0777123456',
        address: 'صنعاء - حدة',
        licenseNumber: 'VET-2026',
      );

      final pdfBytes = await FinancialStatementPdfHelper.generateStatementPdf(
        summary: statement!,
        clinic: clinic,
      );

      expect(pdfBytes, isNotEmpty);
      expect(pdfBytes.length, greaterThan(1000));
    });
  });
}
