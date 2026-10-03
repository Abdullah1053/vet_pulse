import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vet_pulse/data/database/database_helper.dart';
import 'package:vet_pulse/data/database/database_tables.dart';
import 'package:vet_pulse/data/database/demo_data_seeder.dart';
import 'package:vet_pulse/data/repositories/financial_repository.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('DemoDataSeeder seeds and resets database cleanly without SQLite errors', () async {
    final db = await DatabaseHelper.instance.database;

    // Reset to pristine demo state
    await DemoDataSeeder.resetDemoData();

    // Verify Owners
    final owners = await db.query(DatabaseTables.tableOwners);
    expect(owners.length, greaterThanOrEqualTo(4));

    // Verify Pets
    final pets = await db.query(DatabaseTables.tablePets);
    expect(pets.length, greaterThanOrEqualTo(4));

    // Verify Consultations
    final consultations = await db.query(DatabaseTables.tableConsultations);
    expect(consultations.length, greaterThanOrEqualTo(2));

    // Verify Prescriptions
    final prescriptions = await db.query(DatabaseTables.tablePrescriptions);
    expect(prescriptions.length, greaterThanOrEqualTo(3));
    expect(prescriptions.first['dosage'], isNotEmpty);
    expect(prescriptions.first['duration_days'], greaterThan(0));
    expect(prescriptions.first['quantity_dispensed'], greaterThan(0));

    // Verify Surgeries
    final surgeries = await db.query(DatabaseTables.tableSurgeries);
    expect(surgeries.length, greaterThanOrEqualTo(2));

    // Verify Follow-ups
    final followUps = await db.query(DatabaseTables.tableFollowUps);
    expect(followUps.length, greaterThanOrEqualTo(3));
    expect(followUps.first['status'], 'pending');
    expect(followUps.first['scheduled_time'], isNotNull);

    // Verify Expenses
    final expenses = await db.query(DatabaseTables.tableExpenses);
    expect(expenses.length, greaterThanOrEqualTo(4));

    // Verify Financial Transactions
    final transactions = await db.query(DatabaseTables.tableTransactions);
    expect(transactions.length, greaterThanOrEqualTo(6));

    // Verify Financial Repository Summary
    final finRepo = FinancialRepository();
    final summary = await finRepo.getFinancialSummary();
    expect(summary['totalExpenses'], greaterThan(0));
    expect(summary['totalIncome'], greaterThan(0));

    // Verify Owner Account Statement (Ahmad Al-Shami debt = 10,000 YER)
    final firstOwnerId = owners.first['id'] as int;
    final owner1Statement = await finRepo.getOwnerAccountSummary(firstOwnerId);
    expect(owner1Statement, isNotNull);
    expect(owner1Statement!.totalBilled, greaterThanOrEqualTo(41500));
    expect(owner1Statement.balanceDue, equals(10000.0));
    expect(owner1Statement.hasDebt, isTrue);

    // Test resetDemoData (verifies deletions order and re-seeding)
    await DemoDataSeeder.resetDemoData();

    final followUpsAfterReset = await db.query(DatabaseTables.tableFollowUps);
    expect(followUpsAfterReset.length, greaterThanOrEqualTo(3));

    final expensesAfterReset = await db.query(DatabaseTables.tableExpenses);
    expect(expensesAfterReset.length, greaterThanOrEqualTo(4));
  });
}
