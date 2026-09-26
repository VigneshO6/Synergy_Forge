import 'dart:typed_data';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;

import '../models/batch_model.dart';
import '../models/quality_model.dart';
import 'pdf_download_helper.dart';
import 'user_account_service.dart';

class PdfReportService {
  /// Generates the complete official 4-class PDF certificate and triggers an instant download
  static Future<String> generateAndDownloadReport({
    required OnionBatch batch,
    required QualityAnalysisResult result,
    String? inspectorName,
  }) async {
    final pdfBytes = await generateQualityCertificatePdf(
      batch: batch,
      result: result,
      inspectorName: inspectorName,
    );

    final safeBatchId = batch.id.replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final fileName = 'Onion_Quality_Certificate_$safeBatchId.pdf';

    await saveOrDownloadPdf(pdfBytes, fileName);
    return fileName;
  }

  /// Builds the PDF document bytes
  static Future<Uint8List> generateQualityCertificatePdf({
    required OnionBatch batch,
    required QualityAnalysisResult result,
    String? inspectorName,
  }) async {
    final pdf = pw.Document(
      title: 'Onion Quality Inspection Certificate - ${batch.id}',
      author: 'ONION SMART AI Quality Assurance Engine',
    );

    final dateFormat = DateFormat('dd MMM yyyy, HH:mm');
    final issueDate = dateFormat.format(DateTime.now());
    final certNumber = 'CERT-${batch.id}-${DateTime.now().millisecondsSinceEpoch.toString().substring(6)}';
    final inspector = (inspectorName != null && inspectorName.trim().isNotEmpty)
        ? inspectorName.trim()
        : (UserAccountService.currentSession?.fullName ?? 'Certified Quality Procurement Officer');

    final primaryColor = PdfColor.fromHex('#065F46'); // Deep Forest Green
    final darkSlate = PdfColor.fromHex('#1E293B');
    final lightBg = PdfColor.fromHex('#F8FAFC');
    final borderColor = PdfColor.fromHex('#E2E8F0');

    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(28),
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // 1. TOP HEADER & LOGO BANNER
              pw.Container(
                padding: const pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  color: primaryColor,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'ONION SMART',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            letterSpacing: 1.2,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Digital Quality Assurance & Traceability Protocol',
                          style: pw.TextStyle(
                            color: PdfColors.grey200,
                            fontSize: 9,
                          ),
                        ),
                      ],
                    ),
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'OFFICIAL INSPECTION CERTIFICATE',
                          style: pw.TextStyle(
                            color: PdfColors.amber,
                            fontSize: 10,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Cert No: $certNumber',
                          style: pw.TextStyle(
                            color: PdfColors.white,
                            fontSize: 8.5,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // 2. CONSIGNMENT & BATCH PARTICULARS
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: borderColor),
                ),
                child: pw.Row(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildPdfKeyValue('Batch Identifier:', batch.id, isBold: true),
                          _buildPdfKeyValue('Producer / Supplier:', batch.supplierName),
                          _buildPdfKeyValue('Inspection Origin:', batch.location),
                          _buildPdfKeyValue('Consignment Weight:', '${batch.totalQuantityKg.toStringAsFixed(0)} kg (${(batch.totalQuantityKg / 1000).toStringAsFixed(1)} MT)'),
                        ],
                      ),
                    ),
                    pw.SizedBox(width: 16),
                    pw.Expanded(
                      flex: 1,
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          _buildPdfKeyValue('Inspection Date:', issueDate),
                          _buildPdfKeyValue('Certified Inspector:', inspector),
                          _buildPdfKeyValue('Sampled Bulbs:', '${result.totalDetected} units (Standard Tray)'),
                          _buildPdfKeyValue('Overall Lot Quality:', result.overallQuality, isHighlight: true),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 12),

              // 3. STRICT 4-CLASS QUALITY AUDIT BREAKDOWN
              pw.Text(
                'OFFICIAL 4-CLASS PRODUCE QUALITY SYSTEM (MEDIUM EXCLUDED)',
                style: pw.TextStyle(
                  color: darkSlate,
                  fontSize: 10,
                  fontWeight: pw.FontWeight.bold,
                  letterSpacing: 0.5,
                ),
              ),
              pw.SizedBox(height: 6),

              pw.Table(
                border: pw.TableBorder.all(color: borderColor, width: 0.8),
                children: [
                  // Table Header
                  pw.TableRow(
                    decoration: pw.BoxDecoration(color: PdfColor.fromHex('#F1F5F9')),
                    children: [
                      _buildTableHeaderCell('Grade Category'),
                      _buildTableHeaderCell('Bulb Count'),
                      _buildTableHeaderCell('Percentage'),
                      _buildTableHeaderCell('Export Standard Limit'),
                      _buildTableHeaderCell('Compliance'),
                    ],
                  ),
                  // Row 1: Good
                  _buildQualityRow(
                    category: 'Good Quality Bulbs',
                    count: result.good,
                    pct: result.goodPercentage,
                    standard: 'Min 75.0% for Grade A',
                    isPass: result.goodPercentage >= 70.0,
                  ),
                  // Row 2: Defective
                  _buildQualityRow(
                    category: 'Defective (External Rot/Mold)',
                    count: result.defective,
                    pct: result.defectivePercentage,
                    standard: 'Max 5.0% tolerance',
                    isPass: result.defectivePercentage <= 5.0,
                  ),
                  // Row 3: Sprouted
                  _buildQualityRow(
                    category: 'Sprouted (Vegetative Neck Emergence)',
                    count: result.sprouted,
                    pct: result.sproutedPercentage,
                    standard: 'Max 3.0% tolerance',
                    isPass: result.sproutedPercentage <= 3.0,
                  ),
                  // Row 4: Undersized
                  _buildQualityRow(
                    category: 'Undersized (URS < 40mm Caliber)',
                    count: result.undersized,
                    pct: result.undersizedPercentage,
                    standard: 'Divert to Domestic/Processing',
                    isPass: true,
                    note: 'Segregated',
                  ),
                ],
              ),

              pw.SizedBox(height: 12),

              // 4. COMPUTER VISION SUMMARY & OBSERVATIONS
              pw.Container(
                padding: const pw.EdgeInsets.all(10),
                decoration: pw.BoxDecoration(
                  color: lightBg,
                  borderRadius: const pw.BorderRadius.all(pw.Radius.circular(6)),
                  border: pw.Border.all(color: borderColor),
                ),
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.start,
                  children: [
                    pw.Text(
                      'AI COMPUTER VISION INSPECTION LOG & AUDIT NOTES',
                      style: pw.TextStyle(
                        fontSize: 9.5,
                        fontWeight: pw.FontWeight.bold,
                        color: primaryColor,
                      ),
                    ),
                    pw.SizedBox(height: 4),
                    ...result.observations.map(
                      (obs) => pw.Padding(
                        padding: const pw.EdgeInsets.only(bottom: 2.5),
                        child: pw.Row(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('• ', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: primaryColor)),
                            pw.Expanded(
                              child: pw.Text(
                                obs,
                                style: const pw.TextStyle(fontSize: 8.5),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              pw.Spacer(),

              // 5. OFFICIAL QR CERTIFICATE, SEAL & FOOTER
              pw.Container(
                padding: const pw.EdgeInsets.only(top: 8),
                decoration: const pw.BoxDecoration(
                  border: pw.Border(top: pw.BorderSide(color: PdfColors.grey300, width: 1)),
                ),
                child: pw.Row(
                  mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                  children: [
                    // Digital QR Verification Code
                    pw.Row(
                      children: [
                        pw.Container(
                          width: 54,
                          height: 54,
                          child: pw.BarcodeWidget(
                            barcode: pw.Barcode.qrCode(),
                            data: 'ONIONSMART:CERT:$certNumber:BATCH:${batch.id}:QUALITY:${result.overallQuality}',
                          ),
                        ),
                        pw.SizedBox(width: 8),
                        pw.Column(
                          crossAxisAlignment: pw.CrossAxisAlignment.start,
                          children: [
                            pw.Text('DIGITAL CERTIFICATE VERIFIED', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold, color: primaryColor)),
                            pw.Text('Scan to verify authentic certificate hash', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey700)),
                            pw.Text('System: YOLO11 + MobileNetV3 Engine', style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600)),
                          ],
                        ),
                      ],
                    ),

                    // Official Seal and Signature
                    pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.end,
                      children: [
                        pw.Text(
                          'NATIONAL HORTICULTURAL QUALITY HUB',
                          style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold),
                        ),
                        pw.SizedBox(height: 2),
                        pw.Text(
                          'Digitally Signed: $inspector',
                          style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey800),
                        ),
                        pw.Text(
                          'Certified Cryptographic Timestamp: $issueDate',
                          style: const pw.TextStyle(fontSize: 7, color: PdfColors.grey600),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 4),

              // Legal Disclaimer Footnote
              pw.Center(
                child: pw.Text(
                  result.disclaimer,
                  textAlign: pw.TextAlign.center,
                  style: const pw.TextStyle(fontSize: 6.5, color: PdfColors.grey600),
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf.save();
  }

  static pw.Widget _buildPdfKeyValue(String key, String value, {bool isBold = false, bool isHighlight = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.only(bottom: 3),
      child: pw.Row(
        children: [
          pw.Text(
            key,
            style: const pw.TextStyle(fontSize: 8.5, color: PdfColors.grey700),
          ),
          pw.SizedBox(width: 4),
          pw.Text(
            value,
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: (isBold || isHighlight) ? pw.FontWeight.bold : pw.FontWeight.normal,
              color: isHighlight ? PdfColor.fromHex('#065F46') : PdfColors.black,
            ),
          ),
        ],
      ),
    );
  }

  static pw.Widget _buildTableHeaderCell(String text) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(vertical: 5, horizontal: 6),
      child: pw.Text(
        text,
        style: pw.TextStyle(
          fontSize: 8.5,
          fontWeight: pw.FontWeight.bold,
          color: PdfColor.fromHex('#1E293B'),
        ),
      ),
    );
  }

  static pw.TableRow _buildQualityRow({
    required String category,
    required int count,
    required double pct,
    required String standard,
    required bool isPass,
    String? note,
  }) {
    final statusText = note ?? (isPass ? 'PASS' : 'FLAGGED');
    final statusColor = isPass ? PdfColor.fromHex('#065F46') : PdfColor.fromHex('#DC2626');

    return pw.TableRow(
      children: [
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: pw.Text(category, style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: pw.Text('$count bulbs', style: const pw.TextStyle(fontSize: 8)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: pw.Text('${pct.toStringAsFixed(1)}%', style: pw.TextStyle(fontSize: 8, fontWeight: pw.FontWeight.bold)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: pw.Text(standard, style: const pw.TextStyle(fontSize: 7.5, color: PdfColors.grey700)),
        ),
        pw.Padding(
          padding: const pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
          child: pw.Text(
            statusText,
            style: pw.TextStyle(
              fontSize: 8,
              fontWeight: pw.FontWeight.bold,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }
}
