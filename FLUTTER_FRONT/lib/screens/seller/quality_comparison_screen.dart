import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/seller_provider.dart';
import '../../widgets/charts/comparison_bar_widget.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../widgets/onion_badge.dart';
import '../../widgets/onion_card.dart';
import '../../widgets/responsive_scaffold.dart';
import 'profit_calculator_screen.dart';

class QualityComparisonScreen extends StatelessWidget {
  const QualityComparisonScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final seller = Provider.of<SellerProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final comparison = seller.transitComparison;
    final original = comparison?.originalQuality;
    final received = comparison?.receivedQuality;
    final batch = seller.verifiedBatch;

    if (comparison == null || original == null || received == null || batch == null) {
      return const ResponsiveScaffold(
        title: 'Quality Comparison',
        body: Center(child: Text('Please run arrival sampling inspection first.')),
      );
    }

    return ResponsiveScaffold(
      title: 'Original vs Received Quality',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DisclaimerBanner(compact: true),
            const SizedBox(height: 16),

            // Header Comparison Summary Card
            OnionCard(
              hasGlow: true,
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
                            'CONSIGNMENT TRANSIT DELTA',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            batch.id,
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: comparison.requiresPriceRenegotiation
                              ? AppColors.defectiveQuality.withOpacity(0.12)
                              : AppColors.goodQuality.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(
                            color: comparison.requiresPriceRenegotiation
                                ? AppColors.defectiveQuality.withOpacity(0.4)
                                : AppColors.goodQuality.withOpacity(0.4),
                          ),
                        ),
                        child: Text(
                          comparison.requiresPriceRenegotiation ? 'DEGRADATION DETECTED' : 'TRANSIT STABLE',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.5,
                            color: comparison.requiresPriceRenegotiation
                                ? AppColors.defectiveQuality
                                : AppColors.goodQuality,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Text(
                    comparison.conditionSummary,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Estimated natural transit weight loss: ${comparison.weightLossPct}% (~${(batch.totalQuantityKg * comparison.weightLossPct / 100).toStringAsFixed(0)} kg moisture transpiration).',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Side-by-Side Quality Comparison Meters
            OnionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'ORIGINAL vs RECEIVED COMPARISON',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                      ),
                      Row(
                        children: [
                          Container(width: 8, height: 8, color: Colors.grey.withOpacity(0.6)),
                          const SizedBox(width: 4),
                          const Text('Origin  ', style: TextStyle(fontSize: 10, color: Colors.grey)),
                          Container(width: 8, height: 8, color: AppColors.primary),
                          const SizedBox(width: 4),
                          const Text('Mandi', style: TextStyle(fontSize: 10, color: Colors.grey)),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),

                  ComparisonBarWidget(
                    categoryTitle: 'Good Quality Grade',
                    originalPct: original.goodPercentage,
                    receivedPct: received.goodPercentage,
                    categoryColor: AppColors.goodQuality,
                    lowerIsBetter: false,
                  ),
                  ComparisonBarWidget(
                    categoryTitle: 'Active Neck Sprouting',
                    originalPct: original.sproutedPercentage,
                    receivedPct: received.sproutedPercentage,
                    categoryColor: AppColors.sproutedQuality,
                    lowerIsBetter: true,
                  ),
                  ComparisonBarWidget(
                    categoryTitle: 'Visible Defect / Rot',
                    originalPct: original.defectivePercentage,
                    receivedPct: received.defectivePercentage,
                    categoryColor: AppColors.defectiveQuality,
                    lowerIsBetter: true,
                  ),
                  ComparisonBarWidget(
                    categoryTitle: 'Undersized (URS < 40mm)',
                    originalPct: original.undersizedPercentage,
                    receivedPct: received.undersizedPercentage,
                    categoryColor: AppColors.undersizedQuality,
                    lowerIsBetter: true,
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Commercial Procurement Advisory
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF231C16) : const Color(0xFFFFFBEB),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: isDark ? const Color(0xFF4C381E) : const Color(0xFFFDE68A),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.handshake_outlined, color: AppColors.onionGold, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'COMMERCIAL TRADING ADVISORY',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.bold,
                          color: isDark ? const Color(0xFFFCD34D) : const Color(0xFFB45309),
                          letterSpacing: 0.6,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    comparison.requiresPriceRenegotiation
                        ? 'Due to a ${comparison.deltaGood.abs().toStringAsFixed(1)}% reduction in Good Quality bulbs and sprout emergence, the wholesale market realization will be impacted. Use this verified side-by-side report for supplier transit claim settlement.'
                        : 'Consignment maintained stable outer tunic condition during haulage. Good quality degradation is well within standard 3% buffer. Suitable for benchmark wholesale pricing.',
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

            // CTA Button to Profit Estimator
            ElevatedButton.icon(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (_) => const ProfitCalculatorScreen()),
                );
              },
              icon: const Icon(Icons.trending_up_rounded),
              label: const Text('PROCEED TO MARKET PRICING & PROFIT ANALYSIS'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
