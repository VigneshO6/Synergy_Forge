import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/batch_model.dart';
import '../../models/quality_model.dart';
import '../../services/pdf_report_service.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../widgets/onion_badge.dart';
import '../../widgets/onion_card.dart';
import '../../widgets/responsive_scaffold.dart';
import 'qr_view_screen.dart';

class QualityReportScreen extends StatefulWidget {
  final OnionBatch batch;
  final QualityAnalysisResult result;

  const QualityReportScreen({
    super.key,
    required this.batch,
    required this.result,
  });

  @override
  State<QualityReportScreen> createState() => _QualityReportScreenState();
}

class _QualityReportScreenState extends State<QualityReportScreen> {
  bool _isGeneratingPdf = false;

  Future<void> _handleGeneratePdf() async {
    setState(() => _isGeneratingPdf = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Compiling official export quality certificate for ${widget.batch.id}...'),
        duration: const Duration(seconds: 2),
      ),
    );

    try {
      final fileName = await PdfReportService.generateAndDownloadReport(
        batch: widget.batch,
        result: widget.result,
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(Icons.check_circle_rounded, color: Colors.white, size: 20),
                const SizedBox(width: 8),
                Expanded(child: Text('Downloaded inspection certificate: $fileName')),
              ],
            ),
            backgroundColor: AppColors.primary,
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to generate PDF: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isGeneratingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final batch = widget.batch;
    final result = widget.result;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr = '${result.analyzedAt.day}/${result.analyzedAt.month}/${result.analyzedAt.year}';

    return ResponsiveScaffold(
      title: 'Official Quality Report',
      actions: [
        IconButton(
          tooltip: 'Download PDF Report',
          icon: _isGeneratingPdf
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.download_rounded),
          onPressed: _isGeneratingPdf ? null : _handleGeneratePdf,
        ),
        IconButton(
          tooltip: 'Share Report',
          icon: const Icon(Icons.share_rounded),
          onPressed: () {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text('Quality Report link ready to share.')),
            );
          },
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DisclaimerBanner(compact: true),
            const SizedBox(height: 16),

            // Official Header Card
            OnionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'BATCH IDENTIFIER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                            ),
                          ),
                          Text(
                            batch.id,
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.primary.withValues(alpha: 0.4)),
                        ),
                        child: Text(
                          'INSPECTED',
                          style: TextStyle(
                            color: isDark ? AppColors.primaryLight : AppColors.primaryDark,
                            fontSize: 10.5,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  _buildDashedLine(isDark),
                  const SizedBox(height: 14),

                  // Meta Details
                  _buildReportLine('Supplier:', batch.supplierName, isDark),
                  _buildReportLine('Origin / Location:', batch.location, isDark),
                  _buildReportLine('Lot Quantity:', '${batch.totalQuantityKg.toStringAsFixed(0)} kg', isDark),
                  _buildReportLine('Analysis Date:', dateStr, isDark),
                  _buildReportLine('Sample Bulbs Verified:', '${result.totalDetected} units', isDark, isBold: true),

                  const SizedBox(height: 14),
                  _buildDashedLine(isDark),
                  const SizedBox(height: 14),

                  // Quality Distribution - Strictly 4 Classes (Medium Removed)
                  const Text(
                    'QUALITY DISTRIBUTION (4-CLASS SYSTEM)',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                  ),
                  const SizedBox(height: 10),

                  _buildDistRow('Good Quality', '${result.goodPercentage}%', '${result.good} bulbs', AppColors.goodQuality, isDark),
                  _buildDistRow('Defective (Visible)', '${result.defectivePercentage}%', '${result.defective} bulbs', AppColors.defectiveQuality, isDark),
                  _buildDistRow('Sprouted (Active)', '${result.sproutedPercentage}%', '${result.sprouted} bulbs', AppColors.sproutedQuality, isDark),
                  _buildDistRow('Undersized (URS)', '${result.undersizedPercentage}%', '${result.undersized} bulbs', AppColors.undersizedQuality, isDark),

                  const SizedBox(height: 14),
                  _buildDashedLine(isDark),
                  const SizedBox(height: 14),

                  // Overall Grade
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Overall Quality Rating:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                      ),
                      QualityBadge(category: result.overallQuality),
                    ],
                  ),

                  const SizedBox(height: 14),
                  _buildDashedLine(isDark),
                  const SizedBox(height: 14),

                  // Observations
                  const Text(
                    'OBSERVATIONS & DEFECT PROFILE',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                  ),
                  const SizedBox(height: 8),

                  ...result.observations.map(
                    (obs) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 4, right: 8),
                            child: Icon(Icons.circle, size: 6, color: AppColors.primary),
                          ),
                          Expanded(
                            child: Text(
                              obs,
                              style: TextStyle(
                                fontSize: 12.5,
                                height: 1.35,
                                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Action Buttons: Primary is DOWNLOAD REPORT (PDF)
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: _isGeneratingPdf ? null : _handleGeneratePdf,
                    icon: _isGeneratingPdf
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download_rounded, size: 20),
                    label: Text(
                      _isGeneratingPdf ? 'DOWNLOADING PDF...' : 'DOWNLOAD REPORT (PDF)',
                      style: const TextStyle(fontWeight: FontWeight.bold, letterSpacing: 0.5),
                    ),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      elevation: 3,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  flex: 2,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Quality Report successfully stored to batch registry.'),
                          backgroundColor: AppColors.primary,
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                    icon: const Icon(Icons.save_rounded, size: 18),
                    label: const Text('SAVE REPORT'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => QrViewScreen(
                      batch: batch.copyWith(
                        qualityResult: result,
                        status: 'Analysed',
                      ),
                      qualityResult: result,
                    ),
                  ),
                );
              },
              icon: const Icon(Icons.qr_code_2_rounded, size: 18),
              label: const Text('VIEW BATCH QR CERTIFICATE'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDashedLine(bool isDark) {
    return Container(
      height: 1,
      color: isDark ? AppColors.darkBorder : const Color(0xFFE2E8F0),
    );
  }

  Widget _buildReportLine(String label, String value, bool isDark, {bool isBold = false, bool isMono = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 12.5,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
              fontFamily: isMono ? 'monospace' : null,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistRow(String label, String pct, String count, Color color, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          Text(
            count,
            style: TextStyle(
              fontSize: 11.5,
              color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
            ),
          ),
          const SizedBox(width: 14),
          SizedBox(
            width: 48,
            child: Text(
              pct,
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
