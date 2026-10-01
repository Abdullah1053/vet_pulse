import 'dart:io';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:vet_pulse/core/constants/app_theme.dart';
import 'package:vet_pulse/data/models/consultation_model.dart';
import 'package:vet_pulse/data/models/prescription_model.dart';
import 'package:vet_pulse/modules/consultations/views/consultation_detail_view.dart';

void main() {
  testWidgets('Capture Simba SOAP Consultation Detail Screen', (WidgetTester tester) async {
    // 1. Load Arabic and Material Icon fonts into the test environment
    final tajawalReg = File('assets/fonts/Tajawal-Regular.ttf').readAsBytesSync();
    final tajawalBold = File('assets/fonts/Tajawal-Bold.ttf').readAsBytesSync();
    final materialIcons = File('D:/flutter_windows_3.41.6-stable/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf').readAsBytesSync();

    final fontLoaderTajawal = FontLoader('Tajawal');
    fontLoaderTajawal.addFont(Future.value(ByteData.view(tajawalReg.buffer)));
    await fontLoaderTajawal.load();

    final fontLoaderTajawalBold = FontLoader('Tajawal-Bold');
    fontLoaderTajawalBold.addFont(Future.value(ByteData.view(tajawalBold.buffer)));
    await fontLoaderTajawalBold.load();

    final fontLoaderIcons = FontLoader('MaterialIcons');
    fontLoaderIcons.addFont(Future.value(ByteData.view(materialIcons.buffer)));
    await fontLoaderIcons.load();

    // 2. Set phone viewport size (height 1150 allows showing Vitals + SOAP + Prescriptions beautifully)
    const phoneSize = Size(412, 1150);
    await tester.binding.setSurfaceSize(phoneSize);
    tester.view.physicalSize = phoneSize;
    tester.view.devicePixelRatio = 2.0;

    // 3. Prepare Simba's consultation data
    final simbaConsultation = ConsultationModel(
      id: 1,
      petId: 1,
      doctorId: 1,
      visitDate: '2026-10-01 10:30 ص',
      temperature: 39.2,
      heartRate: 145,
      symptoms: 'خمول متزايد، فقدان للشهية منذ يومين، وتقيؤ متكرر بعد شرب الماء.',
      examinationFindings: 'جفاف خفيف (Dehydration ~5%)، ألم طفيف عند جس البطن، الأغشية المخاطية وردية شاحبة، لا توجد كتل مجسوسة.',
      diagnosis: 'التهاب معوي حاد خفيف (Acute Mild Gastroenteritis)',
      treatmentPlan: 'إعطاء محاليل وريدية داعمة، مضاد قيء حقناً في العيادة، ومضاد حيوي واسع الطيف بالفم للمنزل مع حمية هضمية (Gastrointestinal Diet).',
      visitCost: 6500.0,
      petName: 'سيمبا (Simba)',
      petSpecies: 'قط شيرازي (Persian Cat)',
      doctorName: 'د. عبدالله عبدالمغني (طبيب بيطري أول)',
      ownerName: 'م. أحمد يحيى الشامي',
      prescriptions: [
        PrescriptionModel(
          id: 1,
          consultationId: 1,
          medicineId: 1,
          medicineName: 'Synulox (أموكسيسيلين + كلافولانيك)',
          medicineForm: 'أقراص 125mg',
          dosage: 'نصف قرص (125mg)',
          frequency: 'مرتين يومياً (كل 12 ساعة)',
          durationDays: 5,
          quantityDispensed: 5,
          isClinicAdministered: false,
          instructions: 'يُعطى بعد وجبة طعام خفيفة لتقليل تهيج المعدة. إكمال كامل الكورس العلاجي.',
        ),
        PrescriptionModel(
          id: 2,
          consultationId: 1,
          medicineId: 2,
          medicineName: 'Metacam (ميلوكسيكام حقن)',
          medicineForm: 'محلول حقن 5mg/ml',
          dosage: '0.4 ml',
          frequency: 'مرة واحدة بالعيادة',
          durationDays: 1,
          quantityDispensed: 1,
          isClinicAdministered: true,
          instructions: 'حُقنت بالعيادة لتسكين الألم وخفض الحرارة المرتفعة (39.2°C).',
        ),
      ],
    );

    final repaintKey = GlobalKey();

    // 4. Pump Widget
    await tester.pumpWidget(
      GetMaterialApp(
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme.copyWith(
          textTheme: AppTheme.lightTheme.textTheme.apply(fontFamily: 'Tajawal'),
        ),
        locale: const Locale('ar', 'SA'),
        supportedLocales: const [Locale('ar', 'SA')],
        localizationsDelegates: const [
          GlobalMaterialLocalizations.delegate,
          GlobalWidgetsLocalizations.delegate,
          GlobalCupertinoLocalizations.delegate,
        ],
        home: RepaintBoundary(
          key: repaintKey,
          child: ConsultationDetailView(initialConsultation: simbaConsultation),
        ),
      ),
    );

    await tester.pumpAndSettle();

    // 5. Capture screenshot
    final boundary = repaintKey.currentContext!.findRenderObject() as RenderRepaintBoundary;
    final image = await boundary.toImage(pixelRatio: 2.0);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    final pngBytes = byteData!.buffer.asUint8List();

    final dir = Directory('assets/images/screenshots');
    if (!dir.existsSync()) {
      dir.createSync(recursive: true);
    }

    final file = File('assets/images/screenshots/soap_consultation_simba.png');
    await file.writeAsBytes(pngBytes);
    print('SUCCESS: Screenshot saved to ${file.absolute.path} (${pngBytes.length} bytes)');
  });
}
