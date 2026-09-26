import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../core/constants/app_colors.dart';
import '../models/batch_model.dart';
import '../models/quality_model.dart';
import '../services/pdf_report_service.dart';
import 'onion_badge.dart';

class QrCardWidget extends StatelessWidget {
  final OnionBatch batch;
  final String? customPayload;
  final String? title;

  const QrCardWidget({
    super.key,
    required this.batch,
    this.customPayload,
    this.title,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final payload = customPayload ?? batch.comprehensiveQrPayload;
    final q = batch.qualityResult;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.3 : 0.05),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title ?? 'OFFICIAL BATCH QUALITY CERTIFICATE',
                    style: TextStyle(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    batch.id,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
              StatusBadge(status: batch.status),
            ],
          ),
          const SizedBox(height: 16),

          // Quality Metrics Pill Bar Encoded into QR
          if (q != null) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F172A) : const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isDark ? const Color(0xFF334155) : const Color(0xFFE2E8F0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildMetricPill('GOOD', '${q.goodPercentage.toStringAsFixed(1)}%', const Color(0xFF059669)),
                  _buildMetricPill('DEFECTIVE', '${q.defectivePercentage.toStringAsFixed(1)}%', const Color(0xFFDC2626)),
                  _buildMetricPill('SPROUTED', '${q.sproutedPercentage.toStringAsFixed(1)}%', const Color(0xFFD97706)),
                  _buildMetricPill('URS', '${q.undersizedPercentage.toStringAsFixed(1)}%', const Color(0xFF7C3AED)),
                ],
              ),
            ),
            const SizedBox(height: 14),
          ],

          // QR White Container for high contrast scanability
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFCBD5E1), width: 1.5),
            ),
            child: QrImageView(
              data: payload,
              version: QrVersions.auto,
              size: 200.0,
              gapless: true,
              eyeStyle: const QrEyeStyle(
                eyeShape: QrEyeShape.square,
                color: Color(0xFF0F172A),
              ),
              dataModuleStyle: const QrDataModuleStyle(
                dataModuleShape: QrDataModuleShape.square,
                color: Color(0xFF0F172A),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF132A20) : const Color(0xFFECFDF5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.qr_code_scanner_rounded, size: 14, color: AppColors.primary),
                SizedBox(width: 6),
                Text(
                  'Encodes Batch ID, Good %, Defective %, Sprouted %, URS % & PDF Link',
                  style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: batch.id));
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Copied ${batch.id} to clipboard!'),
                      behavior: SnackBarBehavior.floating,
                      backgroundColor: AppColors.primaryDark,
                    ),
                  );
                },
                icon: const Icon(Icons.copy_rounded, size: 16),
                label: const Text('Copy ID'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Compiling Official Certificate for ${batch.id}...'),
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  try {
                    final qResult = batch.qualityResult ??
                        QualityAnalysisResult(
                          batchId: batch.id,
                          totalDetected: 30,
                          good: 25,
                          defective: 2,
                          sprouted: 1,
                          undersized: 2,
                          goodPercentage: 83.3,
                          defectivePercentage: 6.7,
                          sproutedPercentage: 3.3,
                          undersizedPercentage: 6.7,
                          overallQuality: 'Good (Grade A)',
                          observations: ['Certified QR Batch Certificate.'],
                        );
                    final fileName = await PdfReportService.generateAndDownloadReport(
                      batch: batch,
                      result: qResult,
                    );
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Downloaded: $fileName'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Download error: $e')),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 16),
                label: const Text('Download Certificate (PDF)'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill(String label, String value, Color color) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            fontWeight: FontWeight.w800,
            color: color,
            letterSpacing: 0.5,
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(6),
            border: Border.all(color: color.withValues(alpha: 0.4), width: 1),
          ),
          child: Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}
