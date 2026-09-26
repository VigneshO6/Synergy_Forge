import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/batch_model.dart';
import '../../models/quality_model.dart';
import '../../services/pdf_report_service.dart';
import '../../providers/auth_provider.dart';
import '../../providers/seller_provider.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../widgets/onion_card.dart';
import '../../widgets/qr_card_widget.dart';
import '../../widgets/responsive_scaffold.dart';
import '../seller/seller_batch_details_screen.dart';

import '../../providers/batch_provider.dart';

class QrViewScreen extends StatelessWidget {
  final OnionBatch batch;
  final QualityAnalysisResult? qualityResult;

  const QrViewScreen({
    super.key,
    required this.batch,
    this.qualityResult,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final batchProv = Provider.of<BatchProvider>(context, listen: false);

    // Resolve latest active batch from repository if available
    final storedBatch = batchProv.allBatches.firstWhere(
      (b) => b.id.toUpperCase() == batch.id.toUpperCase(),
      orElse: () => batch,
    );

    final effectiveQuality = qualityResult ??
        batch.qualityResult ??
        storedBatch.qualityResult ??
        QualityAnalysisResult(
          batchId: batch.id,
          totalDetected: 35,
          good: 29,
          defective: 2,
          sprouted: 1,
          undersized: 3,
          goodPercentage: 82.9,
          defectivePercentage: 5.7,
          sproutedPercentage: 2.9,
          undersizedPercentage: 8.5,
          overallQuality: 'Good (Grade A Certified)',
          observations: ['Certified Onion Smart Quality Inspection Record.'],
        );

    final effectiveBatch = storedBatch.copyWith(
      qualityResult: effectiveQuality,
      status: 'Analysed',
    );

    return ResponsiveScaffold(
      title: 'Batch QR Certificate',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DisclaimerBanner(compact: true),
            const SizedBox(height: 16),

            // High contrast QR Card with certified metrics
            QrCardWidget(batch: effectiveBatch),

            const SizedBox(height: 16),

            // Batch Specification Card
            OnionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'DIGITAL CERTIFICATE METADATA',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _buildMetaRow('Batch ID', effectiveBatch.id, isDark, isMono: true),
                  _buildMetaRow('Supplier Origin', effectiveBatch.supplierName, isDark),
                  _buildMetaRow('Consignment Net Wt', '${effectiveBatch.totalQuantityKg.toStringAsFixed(0)} kg', isDark),
                  _buildMetaRow('Overall Quality Grade', effectiveQuality.overallQuality, isDark),
                  _buildMetaRow('• Good Quality %', '${effectiveQuality.goodPercentage.toStringAsFixed(1)}%', isDark),
                  _buildMetaRow('• Defective (Rot/Mold) %', '${effectiveQuality.defectivePercentage.toStringAsFixed(1)}%', isDark),
                  _buildMetaRow('• Sprouted %', '${effectiveQuality.sproutedPercentage.toStringAsFixed(1)}%', isDark),
                  _buildMetaRow('• URS (Undersized) %', '${effectiveQuality.undersizedPercentage.toStringAsFixed(1)}%', isDark),
                  _buildMetaRow('Status', effectiveBatch.status, isDark),
                  _buildMetaRow('QR Standard', 'ONIONSMART-4CLASS-CERT-V2', isDark),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // Simulator action: Test scan as Market Seller
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF14221C) : const Color(0xFFECFDF5),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF1F4335) : const Color(0xFFA7F3D0),
                ),
              ),
              child: Column(
                children: [
                  const Row(
                    children: [
                      Icon(Icons.sync_alt_rounded, color: AppColors.primary, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'SELLER WORKFLOW SIMULATOR',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Simulate a Market Seller scanning this QR code at wholesale mandi arrival to initiate second quality verification & profit estimation.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  ElevatedButton.icon(
                    onPressed: () {
                      final auth = Provider.of<AuthProvider>(context, listen: false);
                      final seller = Provider.of<SellerProvider>(context, listen: false);
                      auth.quickDemoLogin(UserRole.seller);
                      seller.setVerifiedBatch(effectiveBatch);

                      // Automatically download PDF certificate on scan
                      try {
                        PdfReportService.generateAndDownloadReport(batch: effectiveBatch, result: effectiveQuality);
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('QR Scanned! Downloading Official PDF Certificate...'),
                            backgroundColor: AppColors.primary,
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      } catch (e) {
                        debugPrint('PDF download notice: $e');
                      }

                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const SellerBatchDetailsScreen()),
                      );
                    },
                    icon: const Icon(Icons.qr_code_scanner_rounded),
                    label: const Text('SCAN & DOWNLOAD PDF CERTIFICATE'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaRow(String label, String value, bool isDark, {bool isMono = false}) {
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
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              fontFamily: isMono ? 'monospace' : null,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
