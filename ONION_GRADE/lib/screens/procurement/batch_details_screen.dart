import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/batch_model.dart';
import '../../providers/batch_provider.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../widgets/onion_badge.dart';
import '../../widgets/onion_card.dart';
import '../../widgets/responsive_scaffold.dart';
import '../../widgets/qr_card_widget.dart';
import 'sample_capture_screen.dart';
import 'sample_review_screen.dart';
import 'analysis_result_screen.dart';
import 'quality_report_screen.dart';
import 'qr_view_screen.dart';
import 'batch_history_screen.dart';
import 'sorting_screen.dart';

class BatchDetailsScreen extends StatelessWidget {
  final OnionBatch batch;

  const BatchDetailsScreen({super.key, required this.batch});

  @override
  Widget build(BuildContext context) {
    // Listen to live batch updates from provider
    final batchProv = Provider.of<BatchProvider>(context);
    final currentBatch = batchProv.allBatches.firstWhere(
      (b) => b.id == batch.id,
      orElse: () => batch,
    );

    final isDark = Theme.of(context).brightness == Brightness.dark;
    final dateStr =
        '${currentBatch.procurementDate.day.toString().padLeft(2, '0')}/${currentBatch.procurementDate.month.toString().padLeft(2, '0')}/${currentBatch.procurementDate.year}';

    return ResponsiveScaffold(
      title: 'Batch Details',
      actions: [
        IconButton(
          tooltip: 'Batch QR Code',
          icon: const Icon(Icons.qr_code_2_rounded),
          onPressed: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => QrViewScreen(batch: currentBatch)),
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

            // Main Batch Info Card
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
                          const Text(
                            'BATCH IDENTIFIER',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            currentBatch.id,
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      StatusBadge(status: currentBatch.status),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  const SizedBox(height: 12),

                  _buildDetailRow(context, 'Supplier / Farmer', currentBatch.supplierName, Icons.person_rounded),
                  _buildDetailRow(context, 'Contact Number', currentBatch.contactNumber, Icons.phone_rounded),
                  _buildDetailRow(context, 'Mandi Location', currentBatch.location, Icons.location_on_rounded),
                  _buildDetailRow(
                    context,
                    'Total Quantity',
                    '${currentBatch.totalQuantityKg.toStringAsFixed(0)} kg',
                    Icons.scale_rounded,
                  ),
                  _buildDetailRow(
                    context,
                    'Purchase Price',
                    '₹${currentBatch.purchasePricePerKg.toStringAsFixed(1)} / kg',
                    Icons.currency_rupee_rounded,
                  ),
                  _buildDetailRow(
                    context,
                    'Total Investment',
                    '₹${currentBatch.totalProcurementCost.toStringAsFixed(0)}',
                    Icons.payments_rounded,
                  ),
                  _buildDetailRow(context, 'Procurement Date', dateStr, Icons.calendar_today_rounded),

                  if (currentBatch.notes.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Text(
                      'Notes: ${currentBatch.notes}',
                      style: TextStyle(
                        fontSize: 12.5,
                        fontStyle: FontStyle.italic,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Quality Inspection Card (if analysed)
            if (currentBatch.qualityResult != null) ...[
              OnionCard(
                borderColor: AppColors.primary.withOpacity(0.4),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'QUALITY INSPECTION STATUS',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: AppColors.primary,
                          ),
                        ),
                        QualityBadge(category: currentBatch.qualityResult!.overallQuality),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMiniMetric('Sample Size', '${currentBatch.qualityResult!.totalDetected} bulbs'),
                        _buildMiniMetric('Good', '${currentBatch.qualityResult!.goodPercentage}%'),
                        _buildMiniMetric('Sprouted', '${currentBatch.qualityResult!.sproutedPercentage}%'),
                        _buildMiniMetric('Defective', '${currentBatch.qualityResult!.defectivePercentage}%'),
                        _buildMiniMetric('URS', '${currentBatch.qualityResult!.undersizedPercentage}%'),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => AnalysisResultScreen(
                                    batch: currentBatch,
                                    result: currentBatch.qualityResult!,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.analytics_rounded, size: 16),
                            label: const Text('View Quality Analysis'),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => QualityReportScreen(
                                    batch: currentBatch,
                                    result: currentBatch.qualityResult!,
                                  ),
                                ),
                              );
                            },
                            icon: const Icon(Icons.description_rounded, size: 16),
                            label: const Text('Quality Report'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Sorting & Market Sub-batches status (if sorted)
            if (currentBatch.isSorted) ...[
              OnionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'SORTED MARKET BATCHES',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                            color: Color(0xFF8B5CF6),
                          ),
                        ),
                        Text(
                          '${currentBatch.subBatches.length} sub-lots',
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...currentBatch.subBatches.map((sub) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      sub.gradeName,
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                    Text(
                                      '${sub.subBatchId} • ${sub.targetMarket}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${sub.quantityKg.toStringAsFixed(0)} kg\n₹${sub.suggestedPricePerKg}/kg',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                        )),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Primary Workflow Actions
            Text(
              'WORKFLOW ACTIONS',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 10),

            // Button 1: Capture Samples
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SampleCaptureScreen(batch: currentBatch)),
                );
              },
              icon: const Icon(Icons.camera_alt_rounded),
              label: Text(
                currentBatch.isAnalysed ? 'RETAKE / CAPTURE SAMPLES' : 'CAPTURE REPRESENTATIVE SAMPLES',
              ),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                backgroundColor: AppColors.primary,
              ),
            ),
            const SizedBox(height: 10),

            // Button 2: Run Quality Analysis
            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SampleReviewScreen(batch: currentBatch)),
                );
              },
              icon: const Icon(Icons.smart_toy_rounded),
              label: const Text('ANALYSE QUALITY (CV PIPELINE)'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),

            // Button 3: Sorting & Market Batch Creation
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => SortingScreen(batch: currentBatch)),
                );
              },
              icon: const Icon(Icons.splitscreen_rounded),
              label: const Text('SORT BATCH & GENERATE MARKET QRs'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
            const SizedBox(height: 10),

            // Button 4 & 5: QR Code & History
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => QrViewScreen(batch: currentBatch)),
                      );
                    },
                    icon: const Icon(Icons.qr_code_rounded, size: 18),
                    label: const Text('Batch QR'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => BatchHistoryScreen(batch: currentBatch)),
                      );
                    },
                    icon: const Icon(Icons.history_rounded, size: 18),
                    label: const Text('View History'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 13),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value, IconData icon) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          const SizedBox(width: 10),
          SizedBox(
            width: 130,
            child: Text(
              label,
              style: TextStyle(
                fontSize: 12.5,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMiniMetric(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w900),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: const TextStyle(fontSize: 10, color: Colors.grey),
        ),
      ],
    );
  }
}
