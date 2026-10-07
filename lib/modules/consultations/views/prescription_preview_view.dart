import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:get/get.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_strings_ar.dart';
import '../../../core/config/demo_config.dart';
import '../../../data/models/clinic_model.dart';
import '../../../data/models/consultation_model.dart';
import '../../auth/controllers/auth_controller.dart';
import '../controllers/consultation_controller.dart';

class PrescriptionPreviewView extends StatefulWidget {
  const PrescriptionPreviewView({super.key});

  @override
  State<PrescriptionPreviewView> createState() => _PrescriptionPreviewViewState();
}

class _PrescriptionPreviewViewState extends State<PrescriptionPreviewView> {
  late bool _showCost;
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      bool defaultPref = true;
      if (Get.isRegistered<ConsultationController>()) {
        defaultPref = Get.find<ConsultationController>().showCostInPrescription.value;
      }
      if (Get.arguments is Map && (Get.arguments as Map).containsKey('showCost')) {
        defaultPref = (Get.arguments as Map)['showCost'] as bool? ?? defaultPref;
      }
      _showCost = defaultPref;
      _initialized = true;
    }
  }

  Future<Uint8List> _generatePdf(
    ConsultationModel consultation,
    ClinicModel? clinic, {
    bool showCost = true,
  }) async {
    final pdf = pw.Document();

    // Load bundled local TrueType Arabic fonts directly from assets (guaranteed offline, 0 network dependency)
    pw.Font arabicFont;
    pw.Font arabicBold;

    try {
      final regularData = await rootBundle.load('assets/fonts/Tajawal-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Tajawal-Bold.ttf');
      arabicFont = pw.Font.ttf(regularData);
      arabicBold = pw.Font.ttf(boldData);
    } catch (_) {
      // Secondary fallback to Amiri if needed
      final regularData = await rootBundle.load('assets/fonts/Amiri-Regular.ttf');
      final boldData = await rootBundle.load('assets/fonts/Amiri-Bold.ttf');
      arabicFont = pw.Font.ttf(regularData);
      arabicBold = pw.Font.ttf(boldData);
    }

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a5,
        theme: pw.ThemeData.withFont(base: arabicFont, bold: arabicBold),
        build: (pw.Context context) {
          return pw.Directionality(
            textDirection: pw.TextDirection.rtl,
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.stretch,
              children: [
                // Demo Edition Security Watermark Banner
                if (DemoConfig.isDemoMode) ...[
                  pw.Container(
                    margin: const pw.EdgeInsets.only(bottom: 6),
                    padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 8),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.amber50,
                      borderRadius: pw.BorderRadius.circular(4),
                      border: pw.Border.all(color: PdfColors.amber400),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'نسخة تجريبية (Demo Edition) • غير مصرحة للاستخدام الرسمي خارج العرض',
                          style: pw.TextStyle(font: arabicBold, fontSize: 8, color: PdfColors.amber900),
                        ),
                        pw.Text(
                          'مطور النظام: م. عبدالله عبدالمغني الأديمي',
                          style: pw.TextStyle(font: arabicBold, fontSize: 8, color: PdfColors.amber900),
                        ),
                      ],
                    ),
                  ),
                ],

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
                          pw.SizedBox(height: 2),
                          pw.Text(
                            clinic?.doctorName ?? consultation.doctorName ?? 'د. بيطري',
                            style: pw.TextStyle(font: arabicFont, fontSize: 10),
                          ),
                          if (clinic?.licenseNumber != null && clinic!.licenseNumber!.isNotEmpty)
                            pw.Text(
                              'ترخيص: ${clinic.licenseNumber}',
                              style: pw.TextStyle(font: arabicFont, fontSize: 8, color: PdfColors.grey700),
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
                          pw.SizedBox(height: 2),
                          pw.Text(
                            'التاريخ: ${consultation.visitDate.length >= 10 ? consultation.visitDate.substring(0, 10) : consultation.visitDate}',
                            style: pw.TextStyle(font: arabicFont, fontSize: 9),
                          ),
                          if (clinic?.phone != null && clinic!.phone!.isNotEmpty)
                            pw.Text(
                              'هاتف: ${clinic.phone}',
                              style: pw.TextStyle(font: arabicFont, fontSize: 8),
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
                      pw.Text(
                        'المريض: ${consultation.petName ?? ""} (${consultation.petSpecies ?? ""})',
                        style: pw.TextStyle(font: arabicBold, fontSize: 9),
                      ),
                      pw.Text(
                        'المالك: ${consultation.ownerName ?? ""}',
                        style: pw.TextStyle(font: arabicFont, fontSize: 9),
                      ),
                      if (consultation.temperature != null)
                        pw.Text(
                          'الحرارة: ${consultation.temperature}°C',
                          style: pw.TextStyle(font: arabicFont, fontSize: 9),
                        ),
                    ],
                  ),
                ),
                pw.SizedBox(height: 10),

                // 3. Clinical Assessment
                pw.Container(
                  padding: const pw.EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                  decoration: pw.BoxDecoration(
                    border: pw.Border(right: const pw.BorderSide(color: PdfColors.teal, width: 3)),
                  ),
                  child: pw.Text(
                    'التشخيص الطبي: ${consultation.diagnosis}',
                    style: pw.TextStyle(font: arabicBold, fontSize: 10, color: PdfColors.grey900),
                  ),
                ),
                pw.SizedBox(height: 12),

                // 4. Prescribed Medications Table
                pw.Text(
                  'الوصفة الدوائية (Rx):',
                  style: pw.TextStyle(font: arabicBold, fontSize: 11, color: PdfColors.teal900),
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
                      final typeLabel = rx.isClinicAdministered ? '[صُرف بالعيادة]' : '[روشتة منزلية]';
                      return pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              '${rx.displayName} $typeLabel\n${rx.medicineForm != null ? "(${rx.medicineForm})" : ""}',
                              style: pw.TextStyle(font: arabicFont, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              rx.dosage,
                              style: pw.TextStyle(font: arabicFont, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              '${rx.frequency}\nلمدة ${rx.durationDays} يوم',
                              style: pw.TextStyle(font: arabicFont, fontSize: 8),
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              rx.instructions ?? '-',
                              style: pw.TextStyle(font: arabicFont, fontSize: 8),
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),

                // 5. Cost of Consultation (if applicable & requested by doctor)
                if (showCost && consultation.visitCost > 0) ...[
                  pw.SizedBox(height: 8),
                  pw.Container(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: pw.BoxDecoration(
                      color: PdfColors.teal50,
                      borderRadius: pw.BorderRadius.circular(4),
                    ),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'أتعاب الكشف والخدمات:',
                          style: pw.TextStyle(font: arabicBold, fontSize: 9, color: PdfColors.teal900),
                        ),
                        pw.Text(
                          '${consultation.visitCost.toStringAsFixed(0)} ${AppStringsAr.currencyShort}',
                          style: pw.TextStyle(font: arabicBold, fontSize: 9, color: PdfColors.teal900),
                        ),
                      ],
                    ),
                  ),
                ],

                pw.Spacer(),

                // 6. Signature Footer
                pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      'مع تمنياتنا لحيوانكم الأليف بالشفاء العاجل',
                      style: pw.TextStyle(font: arabicFont, fontSize: 8, color: PdfColors.grey600),
                    ),
                    pw.Column(
                      children: [
                        pw.Text('توقيع وختم الطبيب', style: pw.TextStyle(font: arabicBold, fontSize: 9)),
                        pw.SizedBox(height: 20),
                        pw.Text('................................', style: pw.TextStyle(font: arabicFont, fontSize: 8)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );

    return pdf.save();
  }

  Future<void> _shareOnWhatsApp(
    ConsultationModel consultation,
    ClinicModel? clinic, {
    required bool showCost,
  }) async {
    final buffer = StringBuffer();
    buffer.writeln('🐾 *${clinic?.clinicName ?? "عيادة بيطرية"}*');
    buffer.writeln('📋 *روشتة طبية إلكترونية*');
    buffer.writeln('---------------------------');
    buffer.writeln('المريض: ${consultation.petName} (${consultation.petSpecies})');
    buffer.writeln('التشخيص: ${consultation.diagnosis}');
    buffer.writeln('التاريخ: ${consultation.visitDate.length >= 10 ? consultation.visitDate.substring(0, 10) : consultation.visitDate}');
    if (showCost && consultation.visitCost > 0) {
      buffer.writeln('أتعاب الكشف والخدمات: ${consultation.visitCost.toStringAsFixed(0)} ${AppStringsAr.currencyShort}');
    }
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

  Future<void> _sharePdfFile(
    ConsultationModel consultation,
    ClinicModel? clinic, {
    required bool showCost,
  }) async {
    try {
      final bytes = await _generatePdf(consultation, clinic, showCost: showCost);
      await Printing.sharePdf(
        bytes: bytes,
        filename: 'prescription_${consultation.petName ?? "pet"}_${consultation.id ?? 1}.pdf',
      );
    } catch (e) {
      Get.snackbar('خطأ', 'تعذر مشاركة ملف الروشتة: $e', backgroundColor: Colors.red.shade100);
    }
  }

  @override
  Widget build(BuildContext context) {
    ConsultationModel? consultation;
    if (Get.arguments is ConsultationModel) {
      consultation = Get.arguments as ConsultationModel;
    } else if (Get.arguments is Map) {
      consultation = (Get.arguments as Map)['consultation'] as ConsultationModel?;
    } else if (Get.isRegistered<ConsultationController>()) {
      consultation = Get.find<ConsultationController>().lastCreatedConsultation.value;
    }

    final authController = Get.find<AuthController>();
    final clinic = authController.clinicInfo.value;

    if (consultation == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('معاينة الروشتة')),
        body: const Center(child: Text('لا توجد روشتة محددة')),
      );
    }

    final ConsultationModel validConsultation = consultation;
    final hasCost = validConsultation.visitCost > 0;

    return Scaffold(
      appBar: AppBar(
        title: const Text('الروشتة الطبية البيطرية'),
        actions: [
          IconButton(
            tooltip: 'مشاركة ملف PDF',
            icon: const Icon(Icons.share, color: AppColors.primary),
            onPressed: () => _sharePdfFile(validConsultation, clinic, showCost: _showCost),
          ),
          IconButton(
            tooltip: AppStringsAr.shareWhatsApp,
            icon: const Icon(Icons.chat, color: Color(0xFF25D366)),
            onPressed: () => _shareOnWhatsApp(validConsultation, clinic, showCost: _showCost),
          ),
        ],
      ),
      body: Column(
        children: [
          // Doctor control banner for Consultation Fee visibility
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: (_showCost && hasCost) ? AppColors.secondaryLight : Colors.grey.shade100,
              border: Border(
                bottom: BorderSide(
                  color: (_showCost && hasCost)
                      ? AppColors.primary.withValues(alpha: 0.3)
                      : Colors.grey.shade300,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  (_showCost && hasCost) ? Icons.visibility : Icons.visibility_off,
                  color: (_showCost && hasCost) ? AppColors.primary : Colors.grey.shade600,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          Text(
                            'أتعاب الكشف والخدمات في الطباعة',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: (_showCost && hasCost)
                                  ? AppColors.primaryDark
                                  : AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: !hasCost
                                  ? Colors.grey.shade400
                                  : (_showCost ? AppColors.primary : Colors.grey.shade500),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              !hasCost ? 'مجاني' : (_showCost ? 'ظاهر' : 'مخفي'),
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasCost
                            ? (_showCost
                                ? 'سيظهر مبلغ الأتعاب (${validConsultation.visitCost.toStringAsFixed(0)} ${AppStringsAr.currencyShort}) في الروشتة المطبوعة'
                                : 'مخفي: لن يظهر أي مبلغ مالي في الروشتة المطبوعة (روشتة علاجية فقط)')
                            : 'لا توجد أتعاب مسجلة لهذا الكشف',
                        style: TextStyle(
                          fontSize: 11,
                          color: (_showCost && hasCost)
                              ? AppColors.primaryDark.withValues(alpha: 0.8)
                              : Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                ),
                Switch.adaptive(
                  value: _showCost && hasCost,
                  activeTrackColor: AppColors.primary,
                  onChanged: hasCost
                      ? (val) {
                          setState(() {
                            _showCost = val;
                            if (Get.isRegistered<ConsultationController>()) {
                              Get.find<ConsultationController>().showCostInPrescription.value = val;
                            }
                          });
                        }
                      : null,
                ),
              ],
            ),
          ),
          Expanded(
            child: PdfPreview(
              build: (format) => _generatePdf(validConsultation, clinic, showCost: _showCost),
              canChangeOrientation: false,
              canChangePageFormat: false,
              allowPrinting: true,
              allowSharing: true,
              pdfFileName: 'prescription_${validConsultation.petName ?? "pet"}_${validConsultation.id ?? 1}.pdf',
            ),
          ),
        ],
      ),
    );
  }
}
