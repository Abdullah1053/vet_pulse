import 'dart:typed_data';
import 'package:flutter/services.dart' show rootBundle;
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../../core/config/demo_config.dart';
import '../../../data/models/account_statement_model.dart';
import '../../../data/models/clinic_model.dart';

class FinancialStatementPdfHelper {
  FinancialStatementPdfHelper._();

  static Future<Uint8List> generateStatementPdf({
    required OwnerAccountSummary summary,
    required ClinicModel? clinic,
  }) async {
    final pdf = pw.Document();

    // Load bundled local Arabic TrueType fonts
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

    final clinicName = clinic?.clinicName ?? 'عيادة نبض البيطرية المتقدمة';
    final doctorName = clinic?.doctorName ?? 'د. عبدالله خالد السالم';
    final clinicPhone = clinic?.phone ?? '0777123456';
    final clinicAddress = clinic?.address ?? 'صنعاء - الجمهورية اليمنية';
    final licenseNumber = clinic?.licenseNumber ?? 'VET-YE-2026-9812';

    final now = DateTime.now();
    final issueDate = '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(24),
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBold),
        build: (pw.Context context) {
          return [
            pw.Directionality(
              textDirection: pw.TextDirection.rtl,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.stretch,
                children: [
                  // Demo Banner Watermark
                  if (DemoConfig.isDemoMode) ...[
                    pw.Container(
                      margin: const pw.EdgeInsets.only(bottom: 8),
                      padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.amber50,
                        borderRadius: pw.BorderRadius.circular(4),
                        border: pw.Border.all(color: PdfColors.amber400),
                      ),
                      child: pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.center,
                        children: [
                          pw.Text(
                            '[تنبيه] نسخة عرض وتجربة تجريبية (Demo Edition) - نبض البيطري 2026',
                            style: pw.TextStyle(font: arabicBold, fontSize: 8, color: PdfColors.amber900),
                          ),
                        ],
                      ),
                    ),
                  ],

                  // Clinic Header
                  pw.Container(
                    padding: const pw.EdgeInsets.only(bottom: 12),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(bottom: pw.BorderSide(color: PdfColors.teal, width: 2.5)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text(
                              clinicName,
                              style: pw.TextStyle(font: arabicBold, fontSize: 16, color: PdfColors.teal900),
                            ),
                            pw.SizedBox(height: 3),
                            pw.Text(
                              '$doctorName | ترخيص: $licenseNumber',
                              style: pw.TextStyle(font: arabicFont, fontSize: 9, color: PdfColors.grey700),
                            ),
                            pw.SizedBox(height: 2),
                            pw.Text(
                              '$clinicAddress | هاتف: $clinicPhone',
                              style: pw.TextStyle(font: arabicFont, fontSize: 8, color: PdfColors.grey600),
                            ),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Container(
                              padding: const pw.EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: pw.BoxDecoration(
                                color: PdfColors.teal,
                                borderRadius: pw.BorderRadius.circular(4),
                              ),
                              child: pw.Text(
                                'كشف حساب مالي تفصيلي',
                                style: pw.TextStyle(font: arabicBold, fontSize: 11, color: PdfColors.white),
                              ),
                            ),
                            pw.SizedBox(height: 4),
                            pw.Text(
                              'تاريخ التصدير: $issueDate',
                              style: pw.TextStyle(font: arabicFont, fontSize: 8, color: PdfColors.grey700),
                            ),
                            pw.Text(
                              'رقم الحساب: #ACC-${summary.ownerId.toString().padLeft(4, '0')}',
                              style: pw.TextStyle(font: arabicBold, fontSize: 8, color: PdfColors.teal800),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 12),

                  // Client Information Box
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
                        pw.Expanded(
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.start,
                            children: [
                              pw.Text(
                                'اسم العميل / المربي: ${summary.ownerName}',
                                style: pw.TextStyle(font: arabicBold, fontSize: 11, color: PdfColors.grey900),
                              ),
                              if (summary.address != null && summary.address!.isNotEmpty) ...[
                                pw.SizedBox(height: 3),
                                pw.Text(
                                  'العنوان: ${summary.address}',
                                  style: pw.TextStyle(font: arabicFont, fontSize: 9, color: PdfColors.grey700),
                                ),
                              ],
                            ],
                          ),
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text(
                              'رقم الهاتف: ${summary.phonePrimary}',
                              style: pw.TextStyle(font: arabicBold, fontSize: 10, color: PdfColors.grey900),
                            ),
                            if (summary.phoneSecondary != null && summary.phoneSecondary!.isNotEmpty) ...[
                              pw.SizedBox(height: 2),
                              pw.Text(
                                'هاتف إضافي: ${summary.phoneSecondary}',
                                style: pw.TextStyle(font: arabicFont, fontSize: 8, color: PdfColors.grey700),
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 12),

                  // Financial Totals Summary Row (Cards)
                  pw.Row(
                    children: [
                      // Total Billed
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.blue50,
                            borderRadius: pw.BorderRadius.circular(6),
                            border: pw.Border.all(color: PdfColors.blue300),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Text('إجمالي الخدمات', style: pw.TextStyle(font: arabicFont, fontSize: 9, color: PdfColors.blue900)),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                '${summary.totalBilled.toStringAsFixed(0)} ر.ي',
                                style: pw.TextStyle(font: arabicBold, fontSize: 13, color: PdfColors.blue900),
                              ),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),

                      // Total Paid
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.green50,
                            borderRadius: pw.BorderRadius.circular(6),
                            border: pw.Border.all(color: PdfColors.green300),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Text('إجمالي المسدد', style: pw.TextStyle(font: arabicFont, fontSize: 9, color: PdfColors.green900)),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                '${summary.totalPaid.toStringAsFixed(0)} ر.ي',
                                style: pw.TextStyle(font: arabicBold, fontSize: 13, color: PdfColors.green900),
                              ),
                            ],
                          ),
                        ),
                      ),
                      pw.SizedBox(width: 8),

                      // Account Status
                      pw.Expanded(
                        child: pw.Container(
                          padding: const pw.EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                          decoration: pw.BoxDecoration(
                            color: PdfColors.teal50,
                            borderRadius: pw.BorderRadius.circular(6),
                            border: pw.Border.all(color: PdfColors.teal300),
                          ),
                          child: pw.Column(
                            crossAxisAlignment: pw.CrossAxisAlignment.center,
                            children: [
                              pw.Text(
                                'حالة الحساب',
                                style: pw.TextStyle(
                                  font: arabicFont,
                                  fontSize: 9,
                                  color: PdfColors.teal900,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                'خالص ومسدد',
                                style: pw.TextStyle(
                                  font: arabicBold,
                                  fontSize: 13,
                                  color: PdfColors.teal900,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),

                  pw.SizedBox(height: 16),

                  // Statement Items Table
                  pw.Text(
                    'تفاصيل الخدمات السريرية والعمليات المسددة:',
                    style: pw.TextStyle(font: arabicBold, fontSize: 11, color: PdfColors.teal900),
                  ),
                  pw.SizedBox(height: 6),

                  pw.Table(
                    border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
                    columnWidths: const {
                      0: pw.FlexColumnWidth(1.2), // التاريخ
                      1: pw.FlexColumnWidth(3.0), // البيان
                      2: pw.FlexColumnWidth(1.2), // المريض
                      3: pw.FlexColumnWidth(1.3), // المبلغ
                      4: pw.FlexColumnWidth(1.3), // المسدد
                      5: pw.FlexColumnWidth(1.4), // الحالة
                    },
                    children: [
                      // Header Row
                      pw.TableRow(
                        decoration: const pw.BoxDecoration(color: PdfColors.teal50),
                        children: [
                          _buildTableCell('التاريخ', arabicBold, isHeader: true),
                          _buildTableCell('البيان / الخدمة', arabicBold, isHeader: true),
                          _buildTableCell('المريض', arabicBold, isHeader: true),
                          _buildTableCell('المبلغ (ر.ي)', arabicBold, isHeader: true),
                          _buildTableCell('المسدد (ر.ي)', arabicBold, isHeader: true),
                          _buildTableCell('الحالة', arabicBold, isHeader: true),
                        ],
                      ),
                      // Data Rows
                      ...summary.statementItems.map((item) {
                        final amt = item.debit > 0 ? item.debit : item.credit;
                        return pw.TableRow(
                          children: [
                            _buildTableCell(item.date, arabicFont),
                            _buildTableCell(item.description, arabicFont),
                            _buildTableCell(item.petName ?? '-', arabicFont),
                            _buildTableCell(
                              amt.toStringAsFixed(0),
                              arabicFont,
                              textColor: PdfColors.blue900,
                            ),
                            _buildTableCell(
                              amt.toStringAsFixed(0),
                              arabicFont,
                              textColor: PdfColors.green900,
                            ),
                            _buildTableCell(
                              'مسدد',
                              arabicBold,
                              textColor: PdfColors.teal900,
                            ),
                          ],
                        );
                      }),
                    ],
                  ),

                  pw.SizedBox(height: 20),

                  // Signature & Closing
                  pw.Container(
                    padding: const pw.EdgeInsets.only(top: 14),
                    decoration: const pw.BoxDecoration(
                      border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300)),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('المسؤول المالي / المحاسب', style: pw.TextStyle(font: arabicBold, fontSize: 9, color: PdfColors.grey800)),
                            pw.SizedBox(height: 20),
                            pw.Text('................................', style: pw.TextStyle(font: arabicFont, fontSize: 8, color: PdfColors.grey500)),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.center,
                          children: [
                            pw.Text('ختم العيادة المعتمد', style: pw.TextStyle(font: arabicBold, fontSize: 9, color: PdfColors.grey800)),
                            pw.SizedBox(height: 25),
                          ],
                        ),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.end,
                          children: [
                            pw.Text('توقيع الطبيب المدير', style: pw.TextStyle(font: arabicBold, fontSize: 9, color: PdfColors.grey800)),
                            pw.SizedBox(height: 20),
                            pw.Text('................................', style: pw.TextStyle(font: arabicFont, fontSize: 8, color: PdfColors.grey500)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  pw.SizedBox(height: 12),
                  pw.Center(
                    child: pw.Text(
                      'نظام نبض البيطري - المنظومة البيطرية السريرية والمالية الشاملة © 2026',
                      style: pw.TextStyle(font: arabicFont, fontSize: 7, color: PdfColors.grey500),
                    ),
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

  static pw.Widget _buildTableCell(
    String text,
    pw.Font font, {
    bool isHeader = false,
    PdfColor? textColor,
  }) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 6, horizontal: 5),
      child: pw.Text(
        text,
        textAlign: pw.TextAlign.center,
        style: pw.TextStyle(
          font: font,
          fontSize: isHeader ? 8.5 : 8,
          color: textColor ?? (isHeader ? PdfColors.teal900 : PdfColors.grey800),
        ),
      ),
    );
  }

  static Future<void> shareStatementPdf({
    required OwnerAccountSummary summary,
    required ClinicModel? clinic,
  }) async {
    final bytes = await generateStatementPdf(summary: summary, clinic: clinic);
    await Printing.sharePdf(
      bytes: bytes,
      filename: 'financial_statement_${summary.ownerName.replaceAll(" ", "_")}_${summary.ownerId}.pdf',
    );
  }
}
