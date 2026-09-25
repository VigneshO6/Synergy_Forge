import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/seller_provider.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../widgets/onion_badge.dart';
import '../../widgets/onion_card.dart';
import '../../widgets/responsive_scaffold.dart';
import 'seller_sample_capture_screen.dart';
import 'profit_calculator_screen.dart';

class SellerBatchDetailsScreen extends StatelessWidget {
  const SellerBatchDetailsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final sellerProv = Provider.of<SellerProvider>(context);
    final batch = sellerProv.verifiedBatch;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    if (batch == null) {
      return const ResponsiveScaffold(
        title: 'Batch Verification',
        body: Center(child: Text('No batch selected or scanned.')),
      );
    }

    final quality = batch.qualityResult;

    return ResponsiveScaffold(
      title: 'Scanned Batch Verification',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DisclaimerBanner(compact: true),
            const SizedBox(height: 16),

            // Origin Verification Card
            OnionCard(
              hasGlow: true,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(Icons.check_circle_rounded, color: AppColors.primary, size: 20),
                          const SizedBox(width: 8),
                          Text(
                            'CONSIGNMENT VERIFIED',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.6,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      StatusBadge(status: batch.status),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    batch.id,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Consignment from ${batch.supplierName}',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  const SizedBox(height: 12),

                  _buildDetailItem('Origin Yard:', batch.location, isDark),
                  _buildDetailItem('Consignment Volume:', '${batch.totalQuantityKg.toStringAsFixed(0)} kg', isDark),
                  _buildDetailItem('Origin Buying Rate:', '₹${batch.purchasePricePerKg.toStringAsFixed(1)} / kg', isDark),
                  _buildDetailItem(
                    'Total Procurement Cost:',
                    '₹${batch.totalProcurementCost.toStringAsFixed(0)}',
                    isDark,
                    isHighlight: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Initial Origin Quality Certificate Summary
            if (quality != null) ...[
              OnionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'ORIGIN QUALITY CERTIFICATE',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                        ),
                        QualityBadge(category: quality.overallQuality),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildMetricCol('Good Bulbs', '${quality.goodPercentage}%', AppColors.goodQuality),
                        _buildMetricCol('Sprouted', '${quality.sproutedPercentage}%', AppColors.sproutedQuality),
                        _buildMetricCol('Defective', '${quality.defectivePercentage}%', AppColors.defectiveQuality),
                        _buildMetricCol('URS Grade', '${quality.undersizedPercentage}%', AppColors.undersizedQuality),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Assessed at origin packhouse on ${quality.analyzedAt.day}/${quality.analyzedAt.month}/${quality.analyzedAt.year}',
                      style: TextStyle(
                        fontSize: 11,
                        color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Inbound Mandi Sampling Prompt
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withOpacity(0.3)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.camera_alt_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Second Quality Analysis (Arrival)',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              'Detect transit rot, sprouting & moisture loss',
                              style: TextStyle(fontSize: 11.5, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'To verify consignment condition upon arrival at the market, take representative sample photos. The system will compare the arrival state against the original origin certificate to compute transit loss and assist with market pricing.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Action Buttons
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const SellerSampleCaptureScreen()),
                );
              },
              icon: const Icon(Icons.photo_camera_rounded),
              label: const Text('CAPTURE ARRIVAL SAMPLES & VERIFY QUALITY'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
            const SizedBox(height: 10),

            OutlinedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfitCalculatorScreen()),
                );
              },
              icon: const Icon(Icons.calculate_rounded),
              label: const Text('SKIP DIRECTLY TO PROFIT ESTIMATOR'),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, bool isDark, {bool isHighlight = false}) {
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
              fontWeight: isHighlight ? FontWeight.w900 : FontWeight.w700,
              color: isHighlight ? AppColors.primary : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMetricCol(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w900, color: color),
        ),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 10, color: Colors.grey)),
      ],
    );
  }
}
