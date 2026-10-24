import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../data/models/clinic_model.dart';
import '../../../data/models/follow_up_model.dart';
import '../../../data/models/prescription_model.dart';

class FollowUpPdfHelper {
  FollowUpPdfHelper._();

  static Future<Uint8List> generateFollowUpPdf({
    required FollowUpModel followUp,
    ClinicModel? clinic,
    String? clinicalNotes,
    List<PrescriptionModel> administeredTreatments = const [],
    FollowUpModel? nextFollowUp,
    Map<String, dynamic>? financialSummary,
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
                            pw.SizedBox(height: 3),
                            if (clinic?.phone != null)
                              pw.Text('هاتف العيادة: ${clinic!.phone}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                            if (clinic?.address != null)
                              pw.Text('العنوان: ${clinic!.address}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.teal50,
                                borderRadius: pw.BorderRadius.circular(6),
                                border: pw.Border.all(color: PdfColors.teal700),
                              ),
                              child: pw.Text(
                                'تقرير مراجعة سريرية',
                                style: pw.TextStyle(font: arabicBold, fontSize: 12, color: PdfColors.teal900),
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text('تاريخ الجلسة: ${followUp.scheduledDate}', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey800)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 12),

                  // 2. Patient & Owner Details Box
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('اسم المريض: ${followUp.petName ?? "المريض"}', style: pw.TextStyle(font: arabicBold, fontSize: 11)),
                            pw.SizedBox(height: 2),
                            pw.Text('النوع / الفصيلة: ${followUp.petSpecies ?? "غير محدد"}', style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('المالك: ${followUp.ownerName ?? "غير محدد"}', style: pw.TextStyle(font: arabicBold, fontSize: 11)),
                            pw.SizedBox(height: 2),
                            pw.Text('الهاتف: ${followUp.ownerPhone ?? "-"}', style: const pw.TextStyle(fontSize: 10)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('سبب المراجعة:', style: pw.TextStyle(font: arabicBold, fontSize: 11)),
                            pw.SizedBox(height: 2),
                            pw.Text(followUp.reason, style: const pw.TextStyle(fontSize: 10, color: PdfColors.teal900)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 12),

                  // 3. Clinical Examination Findings & Observations
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.teal50,
                      borderRadius: pw.BorderRadius.circular(6),
                      border: pw.Border.all(color: PdfColors.teal200),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ملاحظات الفحص السريري ونتائج المتابعة:',
                          style: pw.TextStyle(font: arabicBold, fontSize: 11, color: PdfColors.teal900),
                        ),
                        pw.SizedBox(height: 4),
                        pw.Text(
                          (clinicalNotes != null && clinicalNotes.isNotEmpty)
                              ? clinicalNotes
                              : (followUp.notes?.isNotEmpty == true ? followUp.notes! : 'تم فحص المريض وحالته مستقرة وفق الخطة العلاجية.'),
                          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey900),
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 14),

                  // 4. In-Clinic Administered Treatments & Injections Table
                  pw.Text(
                    'العلاجات والحقن التي تم إعطاؤها داخل العيادة أثناء الجلسة:',
                    style: pw.TextStyle(font: arabicBold, fontSize: 11, color: PdfColors.teal900),
                  ),
                  pw.SizedBox(height: 6),
                  if (administeredTreatments.isEmpty)
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey50,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Text(
                        'فحص سريري ومتابعة دون إعطاء حقن أو أدوية من مخزن العيادة في هذه الجلسة.',
                        style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700),
                      ),
                    )
                  else
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300),
                      columnWidths: const {
                        0: pw.FlexColumnWidth(3.0), // Medicine
                        1: pw.FlexColumnWidth(1.5), // Dosage
                        2: pw.FlexColumnWidth(1.5), // Route
                        3: pw.FlexColumnWidth(1.0), // Quantity
                        4: pw.FlexColumnWidth(2.5), // Notes
                      },
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.teal100),
                          children: [
                            _buildPdfHeaderCell('الدواء / الإجراء', arabicBold),
                            _buildPdfHeaderCell('الجرعة', arabicBold),
                            _buildPdfHeaderCell('طريقة الإعطاء', arabicBold),
                            _buildPdfHeaderCell('الكمية', arabicBold),
                            _buildPdfHeaderCell('الملاحظات', arabicBold),
                          ],
                        ),
                        ...administeredTreatments.map((t) => pw.TableRow(
                              children: [
                                _buildPdfDataCell('${t.displayName} ${t.medicineForm != null ? "(${t.medicineForm})" : ""}', isBold: true, boldFont: arabicBold),
                                _buildPdfDataCell(t.dosage),
                                _buildPdfDataCell(t.route ?? 'حقن / موضعي'),
                                _buildPdfDataCell('${t.quantityDispensed}'),
                                _buildPdfDataCell(t.instructions ?? '-'),
                              ],
                            )),
                      ],
                    ),
                  pw.SizedBox(height: 14),

                  // 5. Next Follow-Up Session (if scheduled)
                  if (nextFollowUp != null) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.indigo50,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: PdfColors.indigo200),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text('موعد المراجعة القادمة المجدول:', style: pw.TextStyle(font: arabicBold, fontSize: 10, color: PdfColors.indigo900)),
                              pw.SizedBox(height: 2),
                              pw.Text('السبب: ${nextFollowUp.reason}', style: const pw.TextStyle(fontSize: 9.5)),
                            ],
                          ),
                          pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.end,
                            children: [
                              pw.Text('التاريخ: ${nextFollowUp.scheduledDate}', style: pw.TextStyle(font: arabicBold, fontSize: 10, color: PdfColors.indigo900)),
                              if (nextFollowUp.scheduledTime != null)
                                pw.Text('الوقت: ${nextFollowUp.scheduledTime}', style: const pw.TextStyle(fontSize: 9.5)),
                            ],
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 14),
                  ],

                  // 6. Financial Summary Box (if present)
                  if (financialSummary != null && (financialSummary['totalCost'] ?? 0) > 0) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: pw.BorderRadius.circular(6),
                        border: pw.Border.all(color: PdfColors.grey400),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'إجمالي أتعاب وعلاجات المراجعة: ${(financialSummary["totalCost"] as num).toStringAsFixed(0)} ${AppStringsAr.currencyShort}',
                            style: pw.TextStyle(font: arabicBold, fontSize: 10),
                          ),
                          pw.Text(
                            'المدفوع: ${(financialSummary["paidAmount"] as num).toStringAsFixed(0)} ${AppStringsAr.currencyShort} (${financialSummary["paymentMethod"] ?? "نقدا"})',
                            style: const pw.TextStyle(fontSize: 10),
                          ),
                          pw.Text(
                            'المتبقي: ${(financialSummary["remainingAmount"] as num).toStringAsFixed(0)} ${AppStringsAr.currencyShort}',
                            style: pw.TextStyle(font: arabicBold, fontSize: 10, color: (financialSummary['remainingAmount'] ?? 0) > 0 ? PdfColors.red900 : PdfColors.teal900),
                          ),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 14),
                  ],

                  // 7. Footer & Signature
                  pw.Spacer(),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('ختم وتوقيع الطبيب المعالج:', style: pw.TextStyle(font: arabicBold, fontSize: 10)),
                          pw.SizedBox(height: 25),
                          pw.Text('..................................................', style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text('مع تمنياتنا لحيوانكم الأليف بدوام الصحة والعافية', style: const pw.TextStyle(fontSize: 9.5, color: PdfColors.grey700)),
                          pw.SizedBox(height: 2),
                          pw.Text('VetPulse Clinic Management System', style: const pw.TextStyle(fontSize: 8, color: PdfColors.grey500)),
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

  static Future<void> printFollowUpReport({
    required FollowUpModel followUp,
    ClinicModel? clinic,
    String? clinicalNotes,
    List<PrescriptionModel> administeredTreatments = const [],
    FollowUpModel? nextFollowUp,
    Map<String, dynamic>? financialSummary,
  }) async {
    final pdfBytes = await generateFollowUpPdf(
      followUp: followUp,
      clinic: clinic,
      clinicalNotes: clinicalNotes,
      administeredTreatments: administeredTreatments,
      nextFollowUp: nextFollowUp,
      financialSummary: financialSummary,
    );
    await Printing.layoutPdf(
      onLayout: (format) async => pdfBytes,
      name: 'followup_report_${followUp.petName ?? "pet"}_${followUp.id ?? 1}.pdf',
    );
  }

  static Future<void> sharePdf({
    required FollowUpModel followUp,
    ClinicModel? clinic,
    String? clinicalNotes,
    List<PrescriptionModel> administeredTreatments = const [],
    FollowUpModel? nextFollowUp,
    Map<String, dynamic>? financialSummary,
  }) async {
    final pdfBytes = await generateFollowUpPdf(
      followUp: followUp,
      clinic: clinic,
      clinicalNotes: clinicalNotes,
      administeredTreatments: administeredTreatments,
      nextFollowUp: nextFollowUp,
      financialSummary: financialSummary,
    );
    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: 'followup_report_${followUp.petName ?? "pet"}_${followUp.id ?? 1}.pdf',
    );
  }

  static Future<void> shareViaWhatsApp({
    required FollowUpModel followUp,
    ClinicModel? clinic,
    String? clinicalNotes,
    List<PrescriptionModel> administeredTreatments = const [],
    FollowUpModel? nextFollowUp,
  }) async {
    if (followUp.ownerPhone == null || followUp.ownerPhone!.isEmpty) return;
    final phone = followUp.ownerPhone!.replaceAll(RegExp(r'\D'), '');

    final buffer = StringBuffer();
    buffer.writeln('📋 *تقرير جلسة المراجعة السريرية*');
    buffer.writeln('من: *${clinic?.clinicName ?? "عيادة بيطرية"}*');
    buffer.writeln('--------------------------------');
    buffer.writeln('المريض: *${followUp.petName ?? "المريض"}* (${followUp.petSpecies ?? ""})');
    buffer.writeln('التاريخ: ${followUp.scheduledDate}');
    buffer.writeln('السبب: ${followUp.reason}');
    if (clinicalNotes != null && clinicalNotes.isNotEmpty) {
      buffer.writeln('ملاحظات الفحص: $clinicalNotes');
    }
    if (administeredTreatments.isNotEmpty) {
      buffer.writeln('\n💉 *العلاجات والحقن التي أُعطيت بالعيادة:*');
      for (final t in administeredTreatments) {
        buffer.writeln('• ${t.displayName} (${t.dosage} - ${t.route ?? "حقن"})');
      }
    }
    if (nextFollowUp != null) {
      buffer.writeln('\n📅 *موعد المراجعة القادمة:* ${nextFollowUp.scheduledDate} ${nextFollowUp.scheduledTime ?? ""}');
      buffer.writeln('السبب: ${nextFollowUp.reason}');
    }
    buffer.writeln('\nنتمنى لحيوانكم الأليف دوام الصحة والعافية 🐾');

    final uri = Uri.parse('whatsapp://send?phone=$phone&text=${Uri.encodeComponent(buffer.toString())}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  static pw.Widget _buildPdfHeaderCell(String text, pw.Font boldFont) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(font: boldFont, fontSize: 9, color: PdfColors.teal900),
      ),
    );
  }

  static pw.Widget _buildPdfDataCell(String text, {bool isBold = false, pw.Font? boldFont}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 4),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: isBold ? boldFont : null,
          fontSize: 8.5,
          color: PdfColors.grey900,
        ),
      ),
    );
  }
}
