import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

void main() {
  test('Generates full prescription PDF with embedded Arabic fonts', () async {
    final regularBytes = File('assets/fonts/Tajawal-Regular.ttf').readAsBytesSync();
    final boldBytes = File('assets/fonts/Tajawal-Bold.ttf').readAsBytesSync();
    final ttfRegular = pw.Font.ttf(regularBytes.buffer.asByteData());
    final ttfBold = pw.Font.ttf(boldBytes.buffer.asByteData());

    final doc = pw.Document();
    doc.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        theme: pw.ThemeData.withFont(base: ttfRegular, bold: ttfBold),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                pw.Container(
                  padding: const pw.EdgeInsets.all(10),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'عيادة الشفاء البيطرية الحديثة',
                            style: pw.TextStyle(font: ttfBold, fontSize: 14, color: PdfColors.teal800),
                          ),
                          pw.Text(
                            'د. أحمد اليماني',
                            style: pw.TextStyle(font: ttfRegular, fontSize: 10),
                          ),
                          pw.Text(
                            'ترخيص: YEM-VET-2026',
                            style: pw.TextStyle(font: ttfRegular, fontSize: 8),
                          ),
                        ],
                      ),
                      pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.end,
                        children: [
                          pw.Text(
                            'روشتة طبية بيطرية',
                            style: pw.TextStyle(font: ttfBold, fontSize: 13, color: PdfColors.teal),
                          ),
                          pw.Text(
                            'التاريخ: 2026-09-28',
                            style: pw.TextStyle(font: ttfRegular, fontSize: 9),
                          ),
                          pw.Text(
                            'هاتف: 777123456',
                            style: pw.TextStyle(font: ttfRegular, fontSize: 8),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Container(
                  padding: const pw.EdgeInsets.all(8),
                  color: PdfColors.grey100,
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text('المريض: بسبوس (قط)', style: pw.TextStyle(font: ttfRegular, fontSize: 10)),
                      pw.Text('المالك: محمد صالح', style: pw.TextStyle(font: ttfRegular, fontSize: 10)),
                      pw.Text('الحرارة: 38.5°C', style: pw.TextStyle(font: ttfRegular, fontSize: 10)),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'التشخيص الطبي: التهاب حاد في المعدة والأمعاء',
                  style: pw.TextStyle(font: ttfBold, fontSize: 11),
                ),
                pw.SizedBox(height: 10),
                pw.Text(
                  'الوصفة الدوائية (Rx):',
                  style: pw.TextStyle(font: ttfBold, fontSize: 12, color: PdfColors.teal900),
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
                          child: pw.Text('الدواء', style: pw.TextStyle(font: ttfBold, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('الجرعة', style: pw.TextStyle(font: ttfBold, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('التكرار والمدة', style: pw.TextStyle(font: ttfBold, fontSize: 9)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('التعليمات', style: pw.TextStyle(font: ttfBold, fontSize: 9)),
                        ),
                      ],
                    ),
                    pw.TableRow(
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('أموكسيسيلين\n(أقراص)', style: pw.TextStyle(font: ttfRegular, fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('نصف قرص', style: pw.TextStyle(font: ttfRegular, fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('مرتين يومياً\nلمدة 5 أيام', style: pw.TextStyle(font: ttfRegular, fontSize: 8)),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text('بعد الأكل مباشرة', style: pw.TextStyle(font: ttfRegular, fontSize: 8)),
                        ),
                      ],
                    ),
                  ],
                ),
                pw.Spacer(),
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Text('مع تمنياتنا لحيوانكم بالشفاء العاجل', style: pw.TextStyle(font: ttfRegular, fontSize: 8)),
                    pw.Text('التكلفة: 5000 ريال يمني', style: pw.TextStyle(font: ttfBold, fontSize: 9)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    final pdfBytes = await doc.save();
    expect(pdfBytes, isNotEmpty);
    expect(pdfBytes.length, greaterThan(5000));
  });
}
