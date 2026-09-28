import 'package:flutter_test/flutter_test.dart';
import 'package:vet_pulse/data/models/user_model.dart';
import 'package:vet_pulse/data/models/pet_model.dart';
import 'package:vet_pulse/data/models/medicine_model.dart';
import 'package:vet_pulse/data/models/surgery_model.dart';

void main() {
  group('UserModel & RBAC Permissions', () {
    test('Lead doctor has full clinical and administrative permissions', () {
      final leadDoctor = UserModel(
        id: 1,
        username: 'dr_lead',
        passwordHash: 'hash123',
        fullName: 'د. أحمد محمود',
        role: 'lead_doctor',
        pinCode: '1234',
      );

      expect(leadDoctor.canManageUsers, isTrue);
      expect(leadDoctor.canPerformConsultation, isTrue);
      expect(leadDoctor.canPerformSurgeries, isTrue);
      expect(leadDoctor.canModifyInventory, isTrue);
      expect(leadDoctor.canDeleteRecords, isTrue);
      expect(leadDoctor.roleDisplayArabic, 'طبيب رئيسي');
    });

    test('Assistant vet can diagnose and operate, but cannot manage users', () {
      final assistant = UserModel(
        id: 2,
        username: 'dr_assistant',
        passwordHash: 'hash123',
        fullName: 'د. سارة خالد',
        role: 'assistant_vet',
        pinCode: '5678',
      );

      expect(assistant.canManageUsers, isFalse);
      expect(assistant.canPerformConsultation, isTrue);
      expect(assistant.canPerformSurgeries, isTrue);
      expect(assistant.canDeleteRecords, isFalse);
      expect(assistant.roleDisplayArabic, 'طبيب مساعد');
    });

    test('Receptionist cannot diagnose, operate or manage users', () {
      final receptionist = UserModel(
        id: 3,
        username: 'reception',
        passwordHash: 'hash123',
        fullName: 'أنس إبراهيم',
        role: 'receptionist',
      );

      expect(receptionist.canManageUsers, isFalse);
      expect(receptionist.canPerformConsultation, isFalse);
      expect(receptionist.canPerformSurgeries, isFalse);
      expect(receptionist.canModifyInventory, isFalse);
      expect(receptionist.roleDisplayArabic, 'موظف استقبال');
    });

    test('Pharmacist can manage inventory but cannot diagnose', () {
      final pharmacist = UserModel(
        id: 4,
        username: 'ph_karim',
        passwordHash: 'hash123',
        fullName: 'كريم عبد الله',
        role: 'pharmacist',
      );

      expect(pharmacist.canManageUsers, isFalse);
      expect(pharmacist.canPerformConsultation, isFalse);
      expect(pharmacist.canModifyInventory, isTrue);
      expect(pharmacist.roleDisplayArabic, 'أمين المستودع والصيدلية');
    });

    test('Serialization and deserialization to Map', () {
      final user = UserModel(
        id: 10,
        username: 'test_user',
        passwordHash: 'secret',
        fullName: 'مستخدم تجريبي',
        role: 'lead_doctor',
        pinCode: '0000',
      );

      final map = user.toMap();
      final restored = UserModel.fromMap(map);

      expect(restored.id, 10);
      expect(restored.username, 'test_user');
      expect(restored.role, 'lead_doctor');
      expect(restored.pinCode, '0000');
    });
  });

  group('PetModel Tests', () {
    test('Correctly identifies critical allergies', () {
      final petWithAllergy = PetModel(
        ownerId: 1,
        name: 'بسبوس',
        species: 'cat',
        allergies: 'حساسية مفرطة من البنسلين ومشتقاته',
      );

      expect(petWithAllergy.hasAllergies, isTrue);

      final petWithoutAllergy = PetModel(
        ownerId: 1,
        name: 'ماكس',
        species: 'dog',
        allergies: null,
      );

      expect(petWithoutAllergy.hasAllergies, isFalse);
    });

    test('Pet gender display in Arabic', () {
      final malePet = PetModel(ownerId: 1, name: 'روكي', species: 'dog', gender: 'male');
      final femalePet = PetModel(ownerId: 1, name: 'لولو', species: 'cat', gender: 'female');

      expect(malePet.genderDisplayArabic, 'ذكر');
      expect(femalePet.genderDisplayArabic, 'أنثى');
    });
  });

  group('MedicineModel Dual-Storage Tests', () {
    test('Total stock aggregates clinic shelf and warehouse', () {
      final med = MedicineModel(
        tradeName: 'Amoxicillin 250mg',
        form: 'capsule',
        clinicStock: 15,
        warehouseStock: 85,
        minStockAlert: 10,
        expiryDate: '2026-12-31',
      );

      expect(med.totalStock, 100);
      expect(med.isLowStock, isFalse);
    });

    test('Detects low clinic shelf stock when below threshold', () {
      final lowMed = MedicineModel(
        tradeName: 'Ketamine 10%',
        form: 'injection',
        clinicStock: 3,
        warehouseStock: 20,
        minStockAlert: 5,
        expiryDate: '2026-12-31',
      );

      expect(lowMed.isLowStock, isTrue);
    });
  });

  group('SurgeryModel & Pre-op Safety', () {
    test('Checklist passed verification', () {
      final surgery = SurgeryModel(
        petId: 1,
        leadSurgeonId: 1,
        scheduledDate: DateTime.now().toIso8601String(),
        surgeryName: 'تعقيم قطة أنثى (Spay)',
        preOpChecklistPassed: true,
        status: 'scheduled',
      );

      expect(surgery.preOpChecklistPassed, isTrue);
      expect(surgery.statusDisplayArabic, 'مجدولة');
    });
  });
}
