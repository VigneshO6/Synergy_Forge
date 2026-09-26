import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/batch_model.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../widgets/onion_card.dart';
import '../../widgets/responsive_scaffold.dart';

class BatchHistoryScreen extends StatelessWidget {
  final OnionBatch batch;

  const BatchHistoryScreen({super.key, required this.batch});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final historyEvents = [
      {
        'title': 'Procurement Consignment Registered',
        'desc': 'Consignment of ${batch.totalQuantityKg.toStringAsFixed(0)} kg received from ${batch.supplierName} at ${batch.location}.',
        'time': '23 Sep 2026, 09:30 AM',
        'icon': Icons.inventory_rounded,
        'color': AppColors.primary,
      },
      {
        'title': 'Representative Image Sampling',
        'desc': 'Representative onion bulbs sampled and imaged on standard laboratory grid table.',
        'time': '23 Sep 2026, 10:15 AM',
        'icon': Icons.camera_alt_rounded,
        'color': const Color(0xFF3B82F6),
      },
      {
        'title': 'Computer Vision Quality Assessment',
        'desc': batch.qualityResult != null
            ? 'Segmented ${batch.qualityResult!.totalDetected} bulbs. Computed ${batch.qualityResult!.goodPercentage}% Good, ${batch.qualityResult!.defectivePercentage}% Defect, ${batch.qualityResult!.sproutedPercentage}% Sprout.'
            : 'Pending representative sample execution.',
        'time': '23 Sep 2026, 10:20 AM',
        'icon': Icons.smart_toy_rounded,
        'color': const Color(0xFF10B981),
      },
      {
        'title': 'Digital QR Certificate Generated',
        'desc': 'Generated verifiable cryptographic batch QR code payload with ID ${batch.id}.',
        'time': '23 Sep 2026, 11:00 AM',
        'icon': Icons.qr_code_2_rounded,
        'color': const Color(0xFFF59E0B),
      },
      if (batch.isSorted)
        {
          'title': 'Batch Segregated & Market QRs Generated',
          'desc': 'Partitioned into ${batch.subBatches.length} sub-lots (Grade A Export, Grade B Domestic Retail, Grade C Processing).',
          'time': '23 Sep 2026, 01:45 PM',
          'icon': Icons.splitscreen_rounded,
          'color': const Color(0xFF8B5CF6),
        },
    ];

    return ResponsiveScaffold(
      title: 'Batch Traceability History',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DisclaimerBanner(compact: true),
            const SizedBox(height: 16),

            OnionCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.history_rounded, color: AppColors.primary, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          batch.id,
                          style: const TextStyle(
                            fontFamily: 'monospace',
                            fontWeight: FontWeight.w900,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'End-to-End Supply Chain Audit Trail',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            Text(
              'TRACEABILITY TIMELINE',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 12),

            // Vertical Timeline
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: historyEvents.length,
              itemBuilder: (context, index) {
                final ev = historyEvents[index];
                final isLast = index == historyEvents.length - 1;

                return IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Timeline indicator column
                      Column(
                        children: [
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: (ev['color'] as Color).withOpacity(0.15),
                              shape: BoxShape.circle,
                              border: Border.all(color: ev['color'] as Color, width: 2),
                            ),
                            child: Icon(ev['icon'] as IconData, size: 16, color: ev['color'] as Color),
                          ),
                          if (!isLast)
                            Expanded(
                              child: Container(
                                width: 2,
                                color: isDark ? AppColors.darkBorder : const Color(0xFFCBD5E1),
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(width: 14),
                      // Content
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(bottom: 24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                ev['time'] as String,
                                style: TextStyle(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: ev['color'] as Color,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                ev['title'] as String,
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w800,
                                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ev['desc'] as String,
                                style: TextStyle(
                                  fontSize: 12.5,
                                  height: 1.35,
                                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}
