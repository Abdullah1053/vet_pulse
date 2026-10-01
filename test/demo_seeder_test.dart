import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:vet_pulse/data/database/database_helper.dart';
import 'package:vet_pulse/data/database/database_tables.dart';
import 'package:vet_pulse/data/database/demo_data_seeder.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('DemoDataSeeder seeds and resets database cleanly without SQLite errors', () async {
    final db = await DatabaseHelper.instance.database;

    // Run seeder
    await DemoDataSeeder.populateDemoData();

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

    // Test resetDemoData (verifies deletions order and re-seeding)
    await DemoDataSeeder.resetDemoData();

    final followUpsAfterReset = await db.query(DatabaseTables.tableFollowUps);
    expect(followUpsAfterReset.length, greaterThanOrEqualTo(3));
  });
}
