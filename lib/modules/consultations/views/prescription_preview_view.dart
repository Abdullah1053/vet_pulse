import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../data/models/clinic_model.dart';
import '../../../data/models/consultation_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/consultation_controller.dart';

class PrescriptionPreviewView extends StatelessWidget {
  const PrescriptionPreviewView({super.key});

  Future<Uint8List> _generatePdf(
    ConsultationModel consultation,
    ClinicModel? clinic,
  ) async {
    final pdf = pw.Document();
    final arabicFont = await PdfGoogleFonts.cairoRegular();
    final arabicBold = await PdfGoogleFonts.cairoBold();

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        textDirection: pw.TextDirection.rtl,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBold),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.stretch,
            children: [
              // 1. Clinic Letterhead Header
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(bottom: pw.BorderSide(color: PdfColors.teal, width: 2)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          clinic?.clinicName ?? 'عيادة بيطرية متقدمة',
                          style: pw.TextStyle(font: arabicBold, fontSize: 14, color: PdfColors.teal800),
                        ),
                        pw.Text(
                          clinic?.doctorName ?? consultation.doctorName ?? 'د. بيطري',
                          style: const pw.TextStyle(fontSize: 10),
                        ),
                        if (clinic?.licenseNumber != null)
                          pw.Text(
                            'ترخيص: ${clinic!.licenseNumber}',
                            style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey700),
                          ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'روشتة طبية بيطرية',
                          style: pw.TextStyle(font: arabicBold, fontSize: 13, color: PdfColors.teal),
                        ),
                        pw.Text(
                          'التاريخ: ${consultation.visitDate.substring(0, 10)}',
                          style: const pw.TextStyle(fontSize: 9),
                        ),
                        if (clinic?.phone != null)
                          pw.Text(
                            'هاتف: ${clinic!.phone}',
                            style: const pw.TextStyle(fontSize: 8),
                          ),
                      ],
                    ),
                  ],
                ),
              ),
              pw.SizedBox(height: 12),

              // 2. Patient & Owner Info Bar
              pw.Container(
                padding: const pw.EdgeInsets.all(8),
                decoration: pw.BoxDecoration(
                  color: PdfColors.grey100,
                  borderRadius: pw.BorderRadius.circular(6),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('المريض: ${consultation.petName ?? ""} (${consultation.petSpecies ?? ""})'),
                    pw.Text('المالك: ${consultation.ownerName ?? ""}'),
                    if (consultation.temperature != null)
                      pw.Text('الحرارة: ${consultation.temperature}°C'),
                  ],
                ),
              ),
              pw.SizedBox(height: 10),

              // 3. Clinical Assessment
              pw.Text(
                'التشخيص الطبي: ${consultation.diagnosis}',
                style: pw.TextStyle(font: arabicBold, fontSize: 11),
              ),
              pw.SizedBox(height: 12),

              // 4. Prescribed Medications Table
              pw.Text(
                'الوصفة الدوائية (Rx):',
                style: pw.TextStyle(font: arabicBold, fontSize: 12, color: PdfColors.teal900),
              ),
              pw.SizedBox(height: 6),
              pw.Table(
                border: pw.TableBorder.all(color: PdfColors.grey300),
                children: [
                  pw.TableRow(
                    decoration: const pw.BoxDecoration(color: PdfColors.teal50),
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('الدواء', style: pw.TextStyle(font: arabicBold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('الجرعة', style: pw.TextStyle(font: arabicBold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('التكرار والمدة', style: pw.TextStyle(font: arabicBold, fontSize: 9)),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(4),
                        child: pw.Text('تعليمات الاستخدام', style: pw.TextStyle(font: arabicBold, fontSize: 9)),
                      ),
                    ],
                  ),
                  ...consultation.prescriptions.map((rx) {
                    return pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('${rx.medicineName ?? ""}\n(${rx.medicineForm ?? ""})', style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(rx.dosage, style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('${rx.frequency}\nلمدة ${rx.durationDays} يوم', style: const pw.TextStyle(fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(rx.instructions ?? '-', style: const pw.TextStyle(fontSize: 8)),
                        ),
                      ],
                    );
                  }),
                ],
              ),
              pw.Spacer(),

              // 5. Signature Footer
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  pw.Text('مع تمنياتنا لحيوانكم الأليف بالشفاء العاجل', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey600)),
                  pw.Column(
                    children: [
                      pw.Text('توقيع وختم الطبيب', style: pw.TextStyle(font: arabicBold, fontSize: 9)),
                      pw.SizedBox(height: 20),
                      pw.Text('................................', style: const pw.TextStyle(fontSize: 8)),
                    ],
                  ),
                ],
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _shareOnWhatsApp(ConsultationModel consultation, ClinicModel? clinic) async {
    final buffer = StringBuffer();
    buffer.writeln('🐾 *${clinic?.clinicName ?? "عيادة بيطرية"}*');
    buffer.writeln('📋 *روشتة طبية إلكترونية*');
    buffer.writeln('---------------------------');
    buffer.writeln('المريض: ${consultation.petName} (${consultation.petSpecies})');
    buffer.writeln('التشخيص: ${consultation.diagnosis}');
    buffer.writeln('التاريخ: ${consultation.visitDate.substring(0, 10)}');
    buffer.writeln('---------------------------');
    buffer.writeln('💊 *الأدوية الموصوفة:*');
    for (final rx in consultation.prescriptions) {
      buffer.writeln('• *${rx.medicineName}*: الجرعة: ${rx.dosage} (${rx.frequency} لمدة ${rx.durationDays} أيام)');
      if (rx.instructions != null && rx.instructions!.isNotEmpty) {
        buffer.writeln('  تعليمات: ${rx.instructions}');
      }
    }
    buffer.writeln('---------------------------');
    buffer.writeln('نتمنى لحيوانكم دوام الصحة والعافية.');

    final encoded = Uri.encodeComponent(buffer.toString());
    final url = Uri.parse('whatsapp://send?text=$encoded');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    } else {
      Get.snackbar('تنبيه', 'تطبيق واتساب غير مثبت على الجهاز', backgroundColor: Colors.amber.shade100);
    }
  }

  @override
  Widget build(BuildContext context) {
    final ConsultationModel? consultation = Get.arguments as ConsultationModel? ??
        Get.find<ConsultationController>().lastCreatedConsultation.value;

    final authController = Get.find<AuthController>();
    final clinic = authController.clinicInfo.value;

    if (consultation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('معاينة الروشتة')),
        body: const Center(child: Text('لا توجد روشتة محددة')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('الروشتة الطبية البيطرية'),
        actions: [
          IconButton(
            tooltip: AppStringsAr.shareWhatsApp,
            icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
            onPressed: () => _shareOnWhatsApp(consultation, clinic),
          ),
        ],
      ),
      body: PdfPreview(
        build: (format) => _generatePdf(consultation, clinic),
        canChangeOrientation: false,
        canChangePageFormat: false,
        allowPrinting: true,
        allowSharing: true,
        pdfFileName: 'prescription_${consultation.petName}_${consultation.id}.pdf',
      ),
    );
  }
}
