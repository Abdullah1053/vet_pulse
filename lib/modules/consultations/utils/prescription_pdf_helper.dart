import 'dart:typed_data';
import 'package:flutter/material.dart' show debugPrint;
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../data/models/clinic_model.dart';
import '../../../data/models/consultation_model.dart';
import '../../../data/models/follow_up_model.dart';
import '../../../data/models/surgery_model.dart';

class PrescriptionPdfHelper {
  PrescriptionPdfHelper._();

  static Future<Uint8List> generatePrescriptionPdf({
    required ConsultationModel consultation,
    ClinicModel? clinic,
    bool showCost = true,
    SurgeryModel? scheduledSurgery,
    List<FollowUpModel> followUpSessions = const [],
  }) async {
    final pdf = pw.Document();

    pw.Font arabicFont;
    pw.Font arabicBold;

    try {
      final regularData = await rootBundle.load('assets/fonts/Tajawal-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Tajawal-Bold.ttf');
      arabicFont = pw.Font.ttf(regularData);
      arabicBold = pw.Font.ttf(boldData);
    } catch (_) {
      final regularData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
      arabicFont = pw.Font.ttf(regularData);
      arabicBold = pw.Font.ttf(boldData);
    }

    final clinicRx = consultation.prescriptions.where((p) => p.isClinicAdministered).toList();
    final homeRx = consultation.prescriptions.where((p) => !p.isClinicAdministered).toList();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBold),
        build: (pw.Context context) {
          return [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // 1. Clinic Letterhead Header
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.teal700, width: 2)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              clinic?.clinicName ?? 'عيادة بيطرية متقدمة',
                              style: pw.TextStyle(font: arabicBold, fontSize: 15, color: PdfColors.teal900),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              clinic?.doctorName ?? consultation.doctorName ?? 'د. بيطري',
                              style: pw.TextStyle(font: arabicFont, fontSize: 10, color: PdfColors.grey800),
                            ),
                            if (clinic?.licenseNumber != null && clinic!.licenseNumber!.isNotEmpty)
                              pw.Text(
                                'ترخيص: ${clinic.licenseNumber}',
                                style: pw.TextStyle(font: arabicFont, fontSize: 8.5, color: PdfColors.grey700),
                              ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'تقرير الفحص السريري والروشتة الطبية',
                              style: pw.TextStyle(font: arabicBold, fontSize: 13, color: PdfColors.teal700),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'التاريخ: ${consultation.visitDate.length >= 10 ? consultation.visitDate.substring(0, 10) : consultation.visitDate}',
                              style: pw.TextStyle(font: arabicFont, fontSize: 9.5),
                            ),
                            if (clinic?.phone != null && clinic!.phone!.isNotEmpty)
                              pw.Text(
                                'هاتف: ${clinic.phone}',
                                style: pw.TextStyle(font: arabicFont, fontSize: 8.5),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  // 2. Patient & Owner Info Bar
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'المريض: ${consultation.petName ?? ""} (${consultation.petSpecies ?? ""})',
                          style: pw.TextStyle(font: arabicBold, fontSize: 9.5),
                        ),
                        pw.Text(
                          'المالك: ${consultation.ownerName ?? "غير محدد"}',
                          style: pw.TextStyle(font: arabicFont, fontSize: 9.5),
                        ),
                        if (consultation.temperature != null)
                          pw.Text(
                            'الحرارة: ${consultation.temperature}°C',
                            style: pw.TextStyle(font: arabicFont, fontSize: 9.5),
                          ),
                        if (consultation.heartRate != null)
                          pw.Text(
                            'النبض: ${consultation.heartRate} bpm',
                            style: pw.TextStyle(font: arabicFont, fontSize: 9.5),
                          ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 10),

                  // 3. SOAP Clinical Assessment & Diagnosis
                  pw.Container(
                    padding: const pw.EdgeInsets.all(8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.teal50,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.teal700, width: 1),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        if (consultation.symptoms != null && consultation.symptoms!.isNotEmpty) ...[
                          pw.Text(
                            'الشكوى والأعراض (S): ${consultation.symptoms}',
                            style: pw.TextStyle(font: arabicFont, fontSize: 9, color: PdfColors.grey800),
                          ),
                          pw.SizedBox(height: 3),
                        ],
                        pw.Text(
                          'التشخيص الطبي السريري (Assessment): ${consultation.diagnosis}',
                          style: pw.TextStyle(font: arabicBold, fontSize: 10, color: PdfColors.teal900),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 12),

                  // SECTION 1: In-Clinic Procedures
                  _buildSectionHeader('1. الإجراءات والعلاجات داخل العيادة (In-Clinic Procedures)', arabicBold),
                  pw.SizedBox(height: 4),
                  if (clinicRx.isEmpty)
                    _buildEmptyNotice('لا توجد علاجات أو حقن تم إعطاؤها داخل العيادة في هذه الزيارة.', arabicFont)
                  else
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                      // Physical columns left-to-right: Notes (0) -> Quantity (1) -> Route (2) -> Dosage (3) -> Medication (4)
                      columnWidths: {
                        0: const pw.FlexColumnWidth(2.2),
                        1: const pw.FlexColumnWidth(1.1),
                        2: const pw.FlexColumnWidth(1.4),
                        3: const pw.FlexColumnWidth(1.3),
                        4: const pw.FlexColumnWidth(2.6),
                      },
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.teal100),
                          children: [
                            _buildPdfHeaderCell('الملاحظات والإرشادات', arabicBold),
                            _buildPdfHeaderCell('الكمية', arabicBold),
                            _buildPdfHeaderCell('طريقة الإعطاء', arabicBold),
                            _buildPdfHeaderCell('الجرعة', arabicBold),
                            _buildPdfHeaderCell('الدواء / الإجراء', arabicBold),
                          ],
                        ),
                        ...clinicRx.map((rx) {
                          return pw.TableRow(
                            children: [
                              _buildPdfDataCell(rx.instructions ?? '-', arabicFont),
                              _buildPdfDataCell('${rx.quantityDispensed}', arabicFont),
                              _buildPdfDataCell(rx.route ?? 'حقن / موضعي', arabicFont),
                              _buildPdfDataCell(rx.dosage, arabicFont),
                              _buildPdfDataCell(
                                '${rx.displayName} ${rx.medicineForm != null ? "(${rx.medicineForm})" : ""}',
                                arabicBold,
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  pw.SizedBox(height: 12),

                  // SECTION 2: Home Treatment Prescription
                  _buildSectionHeader('2. روشتة العلاج المنزلي للمريض (Home Treatment Prescription)', arabicBold),
                  pw.SizedBox(height: 4),
                  if (homeRx.isEmpty)
                    _buildEmptyNotice('لم يتم وصف علاجات منزلية في هذه الزيارة.', arabicFont)
                  else
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                      // Physical columns left-to-right: Notes (0) -> Duration (1) -> Frequency (2) -> Dosage (3) -> Medication (4)
                      columnWidths: {
                        0: const pw.FlexColumnWidth(2.2),
                        1: const pw.FlexColumnWidth(1.1),
                        2: const pw.FlexColumnWidth(1.4),
                        3: const pw.FlexColumnWidth(1.3),
                        4: const pw.FlexColumnWidth(2.6),
                      },
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.teal100),
                          children: [
                            _buildPdfHeaderCell('تعليمات الاستخدام', arabicBold),
                            _buildPdfHeaderCell('المدة', arabicBold),
                            _buildPdfHeaderCell('التكرار', arabicBold),
                            _buildPdfHeaderCell('الجرعة', arabicBold),
                            _buildPdfHeaderCell('الدواء الموصوف', arabicBold),
                          ],
                        ),
                        ...homeRx.map((rx) {
                          return pw.TableRow(
                            children: [
                              _buildPdfDataCell(rx.instructions ?? '-', arabicFont),
                              _buildPdfDataCell('لمدة ${rx.durationDays} يوم', arabicFont),
                              _buildPdfDataCell(rx.frequency, arabicFont),
                              _buildPdfDataCell(rx.dosage, arabicFont),
                              _buildPdfDataCell(
                                '${rx.displayName} ${rx.medicineForm != null ? "(${rx.medicineForm})" : ""}',
                                arabicBold,
                              ),
                            ],
                          );
                        }),
                      ],
                    ),
                  pw.SizedBox(height: 12),

                  // SECTION 3: Surgery Appointments (if scheduled)
                  if (scheduledSurgery != null) ...[
                    _buildSectionHeader('3. مواعيد العمليات الجراحية المجدولة (Surgery Appointments)', arabicBold),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.orange50,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: PdfColors.orange200),
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'العملية: ${scheduledSurgery.surgeryName} (${scheduledSurgery.surgeryCategory ?? "جراحة عامة"})',
                                style: pw.TextStyle(font: arabicBold, fontSize: 9.5, color: PdfColors.brown900),
                              ),
                              pw.Text(
                                'الموعد: ${scheduledSurgery.scheduledDate}',
                                style: pw.TextStyle(font: arabicBold, fontSize: 9, color: PdfColors.orange900),
                              ),
                            ],
                          ),
                          pw.SizedBox(height: 4),
                          pw.Row(
                            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                            children: [
                              pw.Text(
                                'الجراح المسؤول: ${scheduledSurgery.surgeonName ?? "الطبيب المعالج"}',
                                style: pw.TextStyle(font: arabicFont, fontSize: 8.5),
                              ),
                              if (scheduledSurgery.estimatedCost != null && scheduledSurgery.estimatedCost! > 0)
                                pw.Text(
                                  'التكلفة التقديرية: ${scheduledSurgery.estimatedCost!.toStringAsFixed(0)} ${AppStringsAr.currencyShort}',
                                  style: pw.TextStyle(font: arabicBold, fontSize: 8.5, color: PdfColors.teal900),
                                ),
                            ],
                          ),
                          if (scheduledSurgery.postOpNotes != null && scheduledSurgery.postOpNotes!.isNotEmpty) ...[
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'تعليمات وتجهيزات ما قبل الجراحة: ${scheduledSurgery.postOpNotes}',
                              style: pw.TextStyle(font: arabicFont, fontSize: 8.5, color: PdfColors.grey800),
                            ),
                          ],
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 12),
                  ],

                  // SECTION 4: Follow-Up Sessions (if scheduled)
                  if (followUpSessions.isNotEmpty) ...[
                    _buildSectionHeader('4. جلسات المتابعة والمراجعات القادمة (Follow-Up Sessions)', arabicBold),
                    pw.SizedBox(height: 4),
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                      // Physical columns left-to-right: Notes (0) -> Time (1) -> Date (2) -> Session/Reason (3)
                      columnWidths: {
                        0: const pw.FlexColumnWidth(2.5),
                        1: const pw.FlexColumnWidth(1.2),
                        2: const pw.FlexColumnWidth(1.5),
                        3: const pw.FlexColumnWidth(2.5),
                      },
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.blue50),
                          children: [
                            _buildPdfHeaderCell('الملاحظات والإرشادات', arabicBold),
                            _buildPdfHeaderCell('الوقت المجدول', arabicBold),
                            _buildPdfHeaderCell('تاريخ المراجعة', arabicBold),
                            _buildPdfHeaderCell('الجلسة / سبب المراجعة', arabicBold),
                          ],
                        ),
                        ...followUpSessions.map((f) {
                          return pw.TableRow(
                            children: [
                              _buildPdfDataCell(f.notes?.isNotEmpty == true ? f.notes! : '-', arabicFont),
                              _buildPdfDataCell(f.scheduledTime?.isNotEmpty == true ? f.scheduledTime! : 'خلال ساعات الدوام', arabicFont),
                              _buildPdfDataCell(f.scheduledDate, arabicFont),
                              _buildPdfDataCell(f.reason, arabicBold),
                            ],
                          );
                        }),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                  ],

                  // Consultation Fees (if applicable & requested)
                  if (showCost && consultation.visitCost > 0) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.teal50,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: PdfColors.teal200),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'أتعاب الكشف والخدمات البيطرية:',
                            style: pw.TextStyle(font: arabicBold, fontSize: 9.5, color: PdfColors.teal900),
                          ),
                          pw.Text(
                            '${consultation.visitCost.toStringAsFixed(0)} ${AppStringsAr.currencyShort}',
                            style: pw.TextStyle(font: arabicBold, fontSize: 9.5, color: PdfColors.teal900),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 12),
                  ],

                  pw.SizedBox(height: 10),

                  // Signature & Seal Footer
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: pw.CrossAxisAlignment.end,
                    children: [
                      pw.Text(
                        'مع تمنياتنا لحيوانكم الأليف بالصحة والعافية والشفاء العاجل',
                        style: pw.TextStyle(font: arabicFont, fontSize: 8.5, color: PdfColors.grey600),
                      ),
                      pw.Column(
                        children: [
                          pw.Text('توقيع وختم الطبيب المعالج', style: pw.TextStyle(font: arabicBold, fontSize: 9)),
                          pw.SizedBox(height: 18),
                          pw.Text('................................', style: pw.TextStyle(font: arabicFont, fontSize: 8)),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildSectionHeader(String title, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: const pw.BoxDecoration(
        border: pw.Border(right: pw.BorderSide(color: PdfColors.teal700, width: 3)),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(font: font, fontSize: 10, color: PdfColors.teal900),
      ),
    );
  }

  static pw.Widget _buildEmptyNotice(String text, pw.Font font) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(6),
      decoration: pw.BoxDecoration(
        color: PdfColors.grey50,
        borderRadius: pw.BorderRadius.circular(4),
      ),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 8.5, color: PdfColors.grey600),
      ),
    );
  }

  static pw.Widget _buildPdfHeaderCell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: 8.5, color: PdfColors.teal900),
      ),
    );
  }

  static pw.Widget _buildPdfDataCell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: font, fontSize: 8),
      ),
    );
  }

  static Future<void> sharePdfFile({
    required ConsultationModel consultation,
    ClinicModel? clinic,
    required bool showCost,
    SurgeryModel? scheduledSurgery,
    List<FollowUpModel> followUpSessions = const [],
  }) async {
    try {
      final bytes = await generatePrescriptionPdf(
        consultation: consultation,
        clinic: clinic,
        showCost: showCost,
        scheduledSurgery: scheduledSurgery,
        followUpSessions: followUpSessions,
      );
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'medical_report_${consultation.petName ?? "pet"}_${consultation.id ?? 1}.pdf',
      );
    } catch (e) {
      debugPrint('Error sharing prescription PDF: $e');
    }
  }

  static Future<void> shareOnWhatsApp({
    required ConsultationModel consultation,
    ClinicModel? clinic,
    required bool showCost,
    SurgeryModel? scheduledSurgery,
    List<FollowUpModel> followUpSessions = const [],
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('🐾 *${clinic?.clinicName ?? "عيادة بيطرية"}*');
    buffer.writeln('📋 *تقرير الفحص السريري والروشتة الطبية*');
    buffer.writeln('---------------------------');
    buffer.writeln('المريض: ${consultation.petName} (${consultation.petSpecies ?? "حيوان أليف"})');
    buffer.writeln('المالك: ${consultation.ownerName ?? "غير محدد"}');
    buffer.writeln('التشخيص: ${consultation.diagnosis}');
    buffer.writeln('التاريخ: ${consultation.visitDate.length >= 10 ? consultation.visitDate.substring(0, 10) : consultation.visitDate}');

    final clinicRx = consultation.prescriptions.where((p) => p.isClinicAdministered).toList();
    final homeRx = consultation.prescriptions.where((p) => !p.isClinicAdministered).toList();

    if (clinicRx.isNotEmpty) {
      buffer.writeln('---------------------------');
      buffer.writeln('💉 *1. الإجراءات والعلاجات داخل العيادة:*');
      for (final rx in clinicRx) {
        buffer.writeln('• *${rx.displayName}*: الجرعة: ${rx.dosage} | طريق الإعطاء: ${rx.route ?? "حقن"} | كمية: ${rx.quantityDispensed}');
        if (rx.instructions?.isNotEmpty == true) {
          buffer.writeln('  ملاحظات: ${rx.instructions}');
        }
      }
    }

    if (homeRx.isNotEmpty) {
      buffer.writeln('---------------------------');
      buffer.writeln('💊 *2. روشتة العلاج المنزلي:*');
      for (final rx in homeRx) {
        buffer.writeln('• *${rx.displayName}*: ${rx.dosage} (${rx.frequency} لمدة ${rx.durationDays} يوم)');
        if (rx.instructions?.isNotEmpty == true) {
          buffer.writeln('  إرشادات: ${rx.instructions}');
        }
      }
    }

    if (scheduledSurgery != null) {
      buffer.writeln('---------------------------');
      buffer.writeln('🏥 *3. العملية الجراحية المجدولة:*');
      buffer.writeln('• *${scheduledSurgery.surgeryName}* (${scheduledSurgery.surgeryCategory ?? "عام"})');
      buffer.writeln('  الموعد: ${scheduledSurgery.scheduledDate}');
      if (scheduledSurgery.postOpNotes?.isNotEmpty == true) {
        buffer.writeln('  تعليمات التحضير: ${scheduledSurgery.postOpNotes}');
      }
    }

    if (followUpSessions.isNotEmpty) {
      buffer.writeln('---------------------------');
      buffer.writeln('🗓️ *4. جلسات المتابعة والمراجعة:*');
      for (final f in followUpSessions) {
        buffer.writeln('• *${f.reason}* بتاريخ: ${f.scheduledDate} ${f.scheduledTime ?? ""}');
        if (f.notes?.isNotEmpty == true) {
          buffer.writeln('  ملاحظة: ${f.notes}');
        }
      }
    }

    if (showCost && consultation.visitCost > 0) {
      buffer.writeln('---------------------------');
      buffer.writeln('أتعاب الكشف والخدمات: ${consultation.visitCost.toStringAsFixed(0)} ${AppStringsAr.currencyShort}');
    }

    buffer.writeln('---------------------------');
    buffer.writeln('مع تمنياتنا لحيوانكم الأليف بدوام الصحة والعافية.');

    final encoded = Uri.encodeComponent(buffer.toString());
    final url = Uri.parse('whatsapp://send?text=$encoded');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
