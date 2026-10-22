import 'package:flutter_test/flutter_test.dart';
import 'package:vet_pulse/data/models/consultation_model.dart';
import 'package:vet_pulse/data/models/medicine_model.dart';
import 'package:vet_pulse/modules/dashboard/controllers/alerts_controller.dart';
import 'package:vet_pulse/modules/dashboard/controllers/dashboard_controller.dart';
import 'package:vet_pulse/data/repositories/consultation_repository.dart';
import 'package:vet_pulse/data/repositories/appointment_repository.dart';
import 'package:vet_pulse/data/repositories/inventory_repository.dart';
import 'package:vet_pulse/data/repositories/surgery_repository.dart';

class FakeConsultationRepo extends ConsultationRepository {
  final List<ConsultationModel> consultations;
  FakeConsultationRepo(this.consultations);

  @override
  Future<List<ConsultationModel>> getAllConsultations() async {
    return consultations;
  }
}

class FakeAppointmentRepo extends AppointmentRepository {
  final List<Map<String, dynamic>> followUps;
  FakeAppointmentRepo(this.followUps);

  @override
  Future<int> getPendingTodayCount() async => followUps.length;

  @override
  Future<List<Map<String, dynamic>>> getPendingFollowUpsForAlerts() async => followUps;
}

class FakeInventoryRepo extends InventoryRepository {
  @override
  Future<List<MedicineModel>> getLowStockMedicines() async => [];

  @override
  Future<List<MedicineModel>> getExpiringOrExpiredMedicines() async => [];
}

class FakeSurgeryRepo extends SurgeryRepository {
  final List<Map<String, dynamic>> surgeries;
  FakeSurgeryRepo([this.surgeries = const []]);

  @override
  Future<int> getTodaySurgeriesCount() async => surgeries.length;

  @override
  Future<List<Map<String, dynamic>>> getScheduledSurgeriesForAlerts() async => surgeries;
}

void main() {
  group('DashboardController - Today\'s Clinical Examinations Only', () {
    test('filters recentConsultations to current date only and syncs todayVisits', () async {
      final todayStr = DateTime.now().toIso8601String().substring(0, 10);
      final yesterdayStr = DateTime.now().subtract(const Duration(days: 1)).toIso8601String().substring(0, 10);
      final tomorrowStr = DateTime.now().add(const Duration(days: 1)).toIso8601String().substring(0, 10);

      final dummyConsultations = [
        ConsultationModel(
          id: 1,
          petId: 1,
          doctorId: 1,
          visitDate: '$todayStr 10:00:00',
          diagnosis: 'فحص دوري اليوم',
        ),
        ConsultationModel(
          id: 2,
          petId: 2,
          doctorId: 1,
          visitDate: '$yesterdayStr 15:00:00',
          diagnosis: 'فحص الأمس',
        ),
        ConsultationModel(
          id: 3,
          petId: 3,
          doctorId: 1,
          visitDate: '$todayStr 14:30:00',
          diagnosis: 'فحص دوري اليوم 2',
        ),
        ConsultationModel(
          id: 4,
          petId: 4,
          doctorId: 1,
          visitDate: '$tomorrowStr 09:00:00',
          diagnosis: 'فحص الغد',
        ),
      ];

      final controller = DashboardController(
        consultationRepo: FakeConsultationRepo(dummyConsultations),
        appointmentRepo: FakeAppointmentRepo([]),
        inventoryRepo: FakeInventoryRepo(),
        surgeryRepo: FakeSurgeryRepo([]),
      );

      await controller.loadDashboardData();

      expect(controller.recentConsultations.length, 2);
      expect(controller.todayVisits.value, 2);
      expect(controller.recentConsultations.every((c) => c.visitDate.startsWith(todayStr)), isTrue);
    });
  });

  group('AlertsController - Due & Overdue Follow-ups and Urgency', () {
    test('categorizes overdue follow-up, today follow-up, and overdue surgery', () async {
      final now = DateTime.now();
      final todayStr = now.toIso8601String().substring(0, 10);
      final overdueStr = now.subtract(const Duration(days: 2)).toIso8601String().substring(0, 10);

      final mockFollowUps = [
        {
          'id': 101,
          'scheduled_date': overdueStr,
          'scheduled_time': '09:00 ص',
          'reason': 'مراجعة تضميد جرح',
          'pet_name': 'بسبوس',
          'pet_species': 'قط',
          'owner_name': 'خالد محمد',
          'owner_phone': '777123456',
        },
        {
          'id': 102,
          'scheduled_date': todayStr,
          'scheduled_time': '11:59 م', // today, > 6 hours away
          'reason': 'مراجعة تطعيم',
          'pet_name': 'روكي',
          'pet_species': 'كلب',
          'owner_name': 'سامي علي',
          'owner_phone': '777654321',
        },
      ];

      final mockSurgeries = [
        {
          'id': 201,
          'scheduled_date': '$overdueStr 08:00:00',
          'surgery_name': 'استئصال ورم',
          'pet_name': 'ماكس',
          'pet_species': 'كلب',
          'owner_name': 'فؤاد سالم',
          'owner_phone': '777987654',
        },
      ];

      final controller = AlertsController(
        appointmentRepo: FakeAppointmentRepo(mockFollowUps),
        surgeryRepo: FakeSurgeryRepo(mockSurgeries),
      );

      await controller.refreshAlerts();

      expect(controller.alerts.length, 3);

      final overdueFollowUp = controller.alerts.firstWhere((a) => a.id == 101 && a.type == 'follow_up');
      expect(overdueFollowUp.urgency, AlertUrgency.pastDue);
      expect(overdueFollowUp.urgencyLabelArabic, 'موعد مراجعة متأخر ومستحق');
      expect(overdueFollowUp.remainingTextArabic, contains('مستحق منذ'));

      final todayFollowUp = controller.alerts.firstWhere((a) => a.id == 102 && a.type == 'follow_up');
      expect(todayFollowUp.urgency, AlertUrgency.dueToday);
      expect(todayFollowUp.urgencyLabelArabic, 'مراجعة مستحقة اليوم');

      final overdueSurgery = controller.alerts.firstWhere((a) => a.id == 201 && a.type == 'surgery');
      expect(overdueSurgery.urgency, AlertUrgency.pastDue);
      expect(overdueSurgery.urgencyLabelArabic, 'موعد متأخر');

      // Test 'due_followups' filter
      controller.setFilter('due_followups');
      final filtered = controller.filteredAlerts;
      expect(filtered.length, 2);
      expect(filtered.every((a) => a.type == 'follow_up'), isTrue);
      expect(filtered.any((a) => a.id == 101), isTrue);
      expect(filtered.any((a) => a.id == 102), isTrue);
      expect(filtered.any((a) => a.id == 201), isFalse);
    });
  });
}
