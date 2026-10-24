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
import '../../../data/models/surgery_model.dart';

class SurgeryPdfHelper {
  SurgeryPdfHelper._();

  static Future<Uint8List> generateSurgeryPdf({
    required SurgeryModel surgery,
    ClinicModel? clinic,
    List<PrescriptionModel> medications = const [],
    FollowUpModel? followUp,
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

    final double totalCost = (financialSummary?['amount'] as num?)?.toDouble() ?? surgery.estimatedCost ?? 0.0;
    final double paidAmount = (financialSummary?['paid_amount'] as num?)?.toDouble() ?? totalCost;
    final double remainingAmount = (financialSummary?['remaining_amount'] as num?)?.toDouble() ?? 0.0;
    final String paymentMethod = (financialSummary?['payment_method'] as String?) ?? 'نقدا';

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
                              clinic?.doctorName ?? surgery.surgeonName ?? 'د. بيطري',
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
                              'تقرير الجراحة والتخريج الطبي',
                              style: pw.TextStyle(font: arabicBold, fontSize: 13, color: PdfColors.teal700),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              'التاريخ: ${surgery.scheduledDate.length >= 10 ? surgery.scheduledDate.substring(0, 10) : surgery.scheduledDate}',
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
                  pw.SizedBox(height: 12),

                  // 2. Patient & Owner Info Box
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.grey100,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(color: PdfColors.grey300),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('اسم المريض: ${surgery.petName ?? "غير محدد"}', style: pw.TextStyle(font: arabicBold, fontSize: 11)),
                            pw.SizedBox(height: 3),
                            pw.Text('النوع والبيانات: ${surgery.petSpecies ?? "حيوان أليف"}', style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('المالك: ${surgery.ownerName ?? "غير محدد"}', style: pw.TextStyle(font: arabicBold, fontSize: 11)),
                            pw.SizedBox(height: 3),
                            pw.Text('رقم الهاتف: ${surgery.ownerPhone ?? "غير متوفر"}', style: pw.TextStyle(font: arabicFont, fontSize: 10)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('الجراح المسؤول: ${surgery.surgeonName ?? "طبيب بيطري"}', style: pw.TextStyle(font: arabicBold, fontSize: 11)),
                            pw.SizedBox(height: 3),
                            pw.Text('حالة العملية: ${surgery.statusDisplayArabic}', style: pw.TextStyle(font: arabicBold, fontSize: 10, color: PdfColors.teal800)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 12),

                  // 3. Surgery Procedure & Anesthesia Info
                  pw.Container(
                    padding: const pw.EdgeInsets.all(10),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.teal50,
                      borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                      border: pw.Border.all(color: PdfColors.teal200),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Row(
                          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                          children: [
                            pw.Text('العملية الجراحية: ${surgery.surgeryName}', style: pw.TextStyle(font: arabicBold, fontSize: 12, color: PdfColors.teal900)),
                            pw.Text('التصنيف: ${surgery.surgeryCategory ?? "عام"}', style: pw.TextStyle(font: arabicFont, fontSize: 10, color: PdfColors.teal800)),
                          ],
                        ),
                        if (surgery.anesthesiaProtocol != null && surgery.anesthesiaProtocol!.isNotEmpty) ...[
                          pw.SizedBox(height: 4),
                          pw.Text('بروتوكول التخدير المتبع: ${surgery.anesthesiaProtocol}', style: pw.TextStyle(font: arabicFont, fontSize: 9.5)),
                        ],
                      ],
                    ),
                  ),
                  pw.SizedBox(height: 12),

                  // 4. Clinical Outcome & Post-op Notes
                  if (surgery.postOpNotes != null && surgery.postOpNotes!.isNotEmpty) ...[
                    pw.Text('📋 تقرير ونتائج الجراحة وإرشادات الرعاية:', style: pw.TextStyle(font: arabicBold, fontSize: 11, color: PdfColors.teal800)),
                    pw.SizedBox(height: 4),
                    pw.Container(
                      width: double.infinity,
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.white,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Text(
                        surgery.postOpNotes!,
                        style: pw.TextStyle(font: arabicFont, fontSize: 9.5, lineSpacing: 2),
                      ),
                    ),
                    pw.SizedBox(height: 12),
                  ],

                  // 5. Prescribed Medications
                  if (medications.isNotEmpty) ...[
                    pw.Text('💊 الروشتة الطبية والعلاجات المقررة:', style: pw.TextStyle(font: arabicBold, fontSize: 11, color: PdfColors.teal800)),
                    pw.SizedBox(height: 4),
                    pw.Table(
                      border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                      columnWidths: {
                        0: const pw.FlexColumnWidth(3),
                        1: const pw.FlexColumnWidth(2),
                        2: const pw.FlexColumnWidth(2),
                        3: const pw.FlexColumnWidth(3),
                      },
                      children: [
                        pw.TableRow(
                          decoration: const pw.BoxDecoration(color: PdfColors.teal100),
                          children: [
                            _buildTableHeader('الدواء / العلاج', arabicBold),
                            _buildTableHeader('الجرعة', arabicBold),
                            _buildTableHeader('التكرار والمدة', arabicBold),
                            _buildTableHeader('ملاحظات وإرشادات', arabicBold),
                          ],
                        ),
                        ...medications.map((m) => pw.TableRow(
                              children: [
                                _buildTableCell(m.displayName, arabicFont),
                                _buildTableCell(m.dosage, arabicFont),
                                _buildTableCell('${m.frequency} (${m.durationDays} يوم)', arabicFont),
                                _buildTableCell(m.instructions ?? '-', arabicFont),
                              ],
                            )),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                  ],

                  // 6. Follow-up Session
                  if (followUp != null) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.blue50,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        border: pw.Border.all(color: PdfColors.blue200),
                      ),
                      child: pw.Row(
                        children: [
                          pw.Text('🗓️ موعد المراجعة القادمة: ', style: pw.TextStyle(font: arabicBold, fontSize: 10, color: PdfColors.blue900)),
                          pw.Text('${followUp.scheduledDate} ${followUp.scheduledTime ?? ""} - ${followUp.reason}', style: pw.TextStyle(font: arabicFont, fontSize: 9.5)),
                        ],
                      ),
                    ),
                    pw.SizedBox(height: 12),
                  ],

                  // 7. Financial Summary
                  if (totalCost > 0) ...[
                    pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.grey100,
                        borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                        border: pw.Border.all(color: PdfColors.grey300),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'إجمالي التكلفة: ${totalCost.toStringAsFixed(0)} ${AppStringsAr.currencyShort}',
                            style: pw.TextStyle(font: arabicBold, fontSize: 10.5),
                          ),
                          pw.Text(
                            'المسدد: ${paidAmount.toStringAsFixed(0)} ${AppStringsAr.currencyShort} ($paymentMethod)',
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                          ),
                          if (remainingAmount > 0)
                            pw.Text(
                              'المتبقي آجل: ${remainingAmount.toStringAsFixed(0)} ${AppStringsAr.currencyShort}',
                              style: pw.TextStyle(font: arabicBold, fontSize: 10.5, color: PdfColors.red800),
                            )
                          else
                            pw.Text(
                              'خالص ومسدد بالكامل',
                              style: pw.TextStyle(font: arabicBold, fontSize: 10, color: PdfColors.green800),
                            ),
                        ],
                      ),
                    ),
                  ],

                  pw.Spacer(),

                  // 8. Footer & Doctor Signature
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text('توقيع وختم الجراح المسؤول:', style: pw.TextStyle(font: arabicBold, fontSize: 9)),
                          pw.SizedBox(height: 20),
                          pw.Text('د. ${surgery.surgeonName ?? clinic?.doctorName ?? "البيطري"}', style: pw.TextStyle(font: arabicFont, fontSize: 9)),
                        ],
                      ),
                      pw.Text(
                        'صادر من نظام إدارة العيادات البيطرية (VetPulse)',
                        style: pw.TextStyle(font: arabicFont, fontSize: 8, color: PdfColors.grey600),
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

  static pw.Widget _buildTableHeader(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 9.5, color: PdfColors.teal900),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static pw.Widget _buildTableCell(String text, pw.Font font) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      child: pw.Text(
        text,
        style: pw.TextStyle(font: font, fontSize: 8.5),
        textAlign: pw.TextAlign.center,
      ),
    );
  }

  static Future<void> printSurgeryPdf({
    required SurgeryModel surgery,
    ClinicModel? clinic,
    List<PrescriptionModel> medications = const [],
    FollowUpModel? followUp,
    Map<String, dynamic>? financialSummary,
  }) async {
    final bytes = await generateSurgeryPdf(
      surgery: surgery,
      clinic: clinic,
      medications: medications,
      followUp: followUp,
      financialSummary: financialSummary,
    );
    await Printing.layoutPdf(
      onLayout: (_) => bytes,
      name: 'surgery_report_${surgery.id ?? "new"}.pdf',
    );
  }

  static Future<void> shareSurgeryPdfFile({
    required SurgeryModel surgery,
    ClinicModel? clinic,
    List<PrescriptionModel> medications = const [],
    FollowUpModel? followUp,
    Map<String, dynamic>? financialSummary,
  }) async {
    final bytes = await generateSurgeryPdf(
      surgery: surgery,
      clinic: clinic,
      medications: medications,
      followUp: followUp,
      financialSummary: financialSummary,
    );
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'surgery_report_${surgery.surgeryName.replaceAll(' ', '_')}.pdf',
    );
  }

  static Future<void> shareSurgeryOnWhatsApp({
    required SurgeryModel surgery,
    ClinicModel? clinic,
    List<PrescriptionModel> medications = const [],
    FollowUpModel? followUp,
    Map<String, dynamic>? financialSummary,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('🐾 *${clinic?.clinicName ?? "عيادة بيطرية"}*');
    buffer.writeln('🏥 *تقرير الجراحة والتخريج الطبي*');
    buffer.writeln('---------------------------');
    buffer.writeln('المريض: ${surgery.petName ?? "المريض"} (${surgery.petSpecies ?? "حيوان أليف"})');
    buffer.writeln('المالك: ${surgery.ownerName ?? "غير محدد"}');
    buffer.writeln('العملية الجراحية: ${surgery.surgeryName} (${surgery.surgeryCategory ?? "عام"})');
    buffer.writeln('الجراح: ${surgery.surgeonName ?? "طبيب بيطري"}');
    buffer.writeln('تاريخ الإجراء: ${surgery.scheduledDate}');
    buffer.writeln('حالة العملية: ${surgery.statusDisplayArabic}');

    if (surgery.postOpNotes != null && surgery.postOpNotes!.isNotEmpty) {
      buffer.writeln('---------------------------');
      buffer.writeln('📋 *تقرير الجراحة وإرشادات الرعاية:*');
      buffer.writeln(surgery.postOpNotes!);
    }

    if (medications.isNotEmpty) {
      buffer.writeln('---------------------------');
      buffer.writeln('💊 *الأدوية والعلاجات المقررة:*');
      for (final m in medications) {
        buffer.writeln('• *${m.displayName}*: ${m.dosage} (${m.frequency} لمدة ${m.durationDays} يوم)');
        if (m.instructions != null && m.instructions!.isNotEmpty) {
          buffer.writeln('  تعليمات: ${m.instructions}');
        }
      }
    }

    if (followUp != null) {
      buffer.writeln('---------------------------');
      buffer.writeln('🗓️ *موعد المراجعة القادمة:*');
      buffer.writeln('• التاريخ: ${followUp.scheduledDate} ${followUp.scheduledTime ?? ""}');
      buffer.writeln('  الغرض: ${followUp.reason}');
    }

    final double totalCost = (financialSummary?['amount'] as num?)?.toDouble() ?? surgery.estimatedCost ?? 0.0;
    final double remaining = (financialSummary?['remaining_amount'] as num?)?.toDouble() ?? 0.0;
    if (totalCost > 0) {
      buffer.writeln('---------------------------');
      buffer.writeln('تكلفة العملية: ${totalCost.toStringAsFixed(0)} ${AppStringsAr.currencyShort}');
      if (remaining > 0) {
        buffer.writeln('المتبقي آجل: ${remaining.toStringAsFixed(0)} ${AppStringsAr.currencyShort}');
      } else {
        buffer.writeln('الحالة المالية: خالص ومسدد بالكامل');
      }
    }

    buffer.writeln('---------------------------');
    buffer.writeln('مع تمنياتنا لحيوانكم الأليف بالشفاء العاجل والسلامة التامة.');

    final encoded = Uri.encodeComponent(buffer.toString());
    final url = Uri.parse('whatsapp://send?text=$encoded');
    if (await canLaunchUrl(url)) {
      await launchUrl(url);
    }
  }
}
