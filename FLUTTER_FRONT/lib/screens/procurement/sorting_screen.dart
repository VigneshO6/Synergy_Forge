import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:qr_flutter/qr_flutter.dart';
import '../../core/constants/app_colors.dart';
import '../../models/batch_model.dart';
import '../../providers/auth_provider.dart';
import '../../providers/batch_provider.dart';
import '../../providers/seller_provider.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../widgets/onion_badge.dart';
import '../../widgets/onion_card.dart';
import '../../widgets/responsive_scaffold.dart';
import '../seller/seller_batch_details_screen.dart';

class SortingScreen extends StatefulWidget {
  final OnionBatch batch;

  const SortingScreen({super.key, required this.batch});

  @override
  State<SortingScreen> createState() => _SortingScreenState();
}

class _SortingScreenState extends State<SortingScreen> {
  late double _gradeAQty;
  late double _gradeBQty;
  late double _gradeCQty;

  late double _gradeAPrice;
  late double _gradeBPrice;
  late double _gradeCPrice;

  bool _isCreated = false;
  List<MarketSubBatch> _generatedSubBatches = [];

  @override
  void initState() {
    super.initState();
    final total = widget.batch.totalQuantityKg;
    final r = widget.batch.qualityResult;

    // Use 4-class quality percentages to suggest realistic sorting split
    final goodPct = (r?.goodPercentage ?? 75.0) / 100.0;
    final ursPct = (r?.undersizedPercentage ?? 15.0) / 100.0;
    final defectPct = ((r?.defectivePercentage ?? 5.0) + (r?.sproutedPercentage ?? 5.0)) / 100.0;

    _gradeAQty = double.parse((total * goodPct).clamp(0, total).toStringAsFixed(0));
    _gradeBQty = double.parse((total * ursPct).clamp(0, total - _gradeAQty).toStringAsFixed(0));
    _gradeCQty = double.parse((total - (_gradeAQty + _gradeBQty)).clamp(0, total).toStringAsFixed(0));

    _gradeAPrice = widget.batch.purchasePricePerKg + 14.0;
    _gradeBPrice = widget.batch.purchasePricePerKg + 6.0;
    _gradeCPrice = widget.batch.purchasePricePerKg - 8.0;

    if (widget.batch.isSorted) {
      _isCreated = true;
      _generatedSubBatches = widget.batch.subBatches;
    }
  }

  void _confirmSorting() {
    final batchProv = Provider.of<BatchProvider>(context, listen: false);

    batchProv.createSortedSubBatches(
      batchId: widget.batch.id,
      gradeAQty: _gradeAQty,
      gradeBQty: _gradeBQty,
      gradeCQty: _gradeCQty,
      gradeAPrice: _gradeAPrice,
      gradeBPrice: _gradeBPrice,
      gradeCPrice: _gradeCPrice,
    );

    final updated = batchProv.allBatches.firstWhere((b) => b.id == widget.batch.id);

    setState(() {
      _isCreated = true;
      _generatedSubBatches = updated.subBatches;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Sorted Market Batches & New QRs created successfully!'),
        backgroundColor: AppColors.primary,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final totalAllocated = _gradeAQty + _gradeBQty + _gradeCQty;

    return ResponsiveScaffold(
      title: 'Sorting & Market Batches',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DisclaimerBanner(compact: true),
            const SizedBox(height: 16),

            // Header Explanation
            OnionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.splitscreen_rounded, color: Color(0xFF8B5CF6), size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Parent Batch: ${widget.batch.id}',
                              style: const TextStyle(
                                fontFamily: 'monospace',
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Color(0xFF8B5CF6),
                              ),
                            ),
                            const Text(
                              'Post-Analysis Batch Segregation',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Divide the raw consignment into target market grades based on the computer-vision quality assessment. Each sorted lot generates a New Market QR with updated target pricing.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.35,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            if (!_isCreated) ...[
              // Allocation Sliders
              OnionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'MARKET LOT PARTITIONING',
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.6),
                        ),
                        Text(
                          'Total: ${widget.batch.totalQuantityKg.toStringAsFixed(0)} kg',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Grade A Export
                    _buildSubBatchConfigTile(
                      title: 'Grade A Premium Export',
                      subTitle: 'Middle East / Southeast Asia Export',
                      color: AppColors.goodQuality,
                      qty: _gradeAQty,
                      maxQty: widget.batch.totalQuantityKg,
                      price: _gradeAPrice,
                      onQtyChange: (val) => setState(() => _gradeAQty = val),
                      onPriceChange: (val) => setState(() => _gradeAPrice = val),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),

                    // Grade B Retail
                    _buildSubBatchConfigTile(
                      title: 'Grade B Domestic Retail Mandi',
                      subTitle: 'Metro Wholesale APMC Mandis',
                      color: AppColors.onionAmber,
                      qty: _gradeBQty,
                      maxQty: widget.batch.totalQuantityKg,
                      price: _gradeBPrice,
                      onQtyChange: (val) => setState(() => _gradeBQty = val),
                      onPriceChange: (val) => setState(() => _gradeBPrice = val),
                      isDark: isDark,
                    ),
                    const SizedBox(height: 14),

                    // Grade C Processing
                    _buildSubBatchConfigTile(
                      title: 'Grade C Food Processing / Flakes',
                      subTitle: 'Dehydration & Powder Manufacturing',
                      color: AppColors.undersizedQuality,
                      qty: _gradeCQty,
                      maxQty: widget.batch.totalQuantityKg,
                      price: _gradeCPrice,
                      onQtyChange: (val) => setState(() => _gradeCQty = val),
                      onPriceChange: (val) => setState(() => _gradeCPrice = val),
                      isDark: isDark,
                    ),

                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Allocated Total: ${totalAllocated.toStringAsFixed(0)} kg',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: (totalAllocated - widget.batch.totalQuantityKg).abs() < 1
                                ? AppColors.goodQuality
                                : AppColors.defectiveQuality,
                          ),
                        ),
                        Text(
                          'Base Cost: ₹${widget.batch.purchasePricePerKg}/kg',
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 20),

              ElevatedButton.icon(
                onPressed: _confirmSorting,
                icon: const Icon(Icons.qr_code_2_rounded),
                label: const Text('CREATE MARKET SUB-BATCHES & GENERATE NEW QRS'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF8B5CF6),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
              ),
            ] else ...[
              // Generated Market Sub-Batches with NEW QRS
              Text(
                'NEW MARKET QR CERTIFICATES GENERATED',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
              const SizedBox(height: 12),

              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _generatedSubBatches.length,
                separatorBuilder: (_, __) => const SizedBox(height: 14),
                itemBuilder: (context, index) {
                  final sub = _generatedSubBatches[index];
                  return _buildSubBatchCard(context, sub, isDark);
                },
              ),

              const SizedBox(height: 20),

              OutlinedButton.icon(
                onPressed: () => setState(() => _isCreated = false),
                icon: const Icon(Icons.tune_rounded),
                label: const Text('Adjust Sorting Proportions'),
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSubBatchConfigTile({
    required String title,
    required String subTitle,
    required Color color,
    required double qty,
    required double maxQty,
    required double price,
    required ValueChanged<double> onQtyChange,
    required ValueChanged<double> onPriceChange,
    required bool isDark,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: color),
              ),
              Text(
                '${qty.toStringAsFixed(0)} kg',
                style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 14),
              ),
            ],
          ),
          Text(
            subTitle,
            style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
          ),
          Slider(
            value: qty.clamp(0, maxQty),
            min: 0,
            max: maxQty,
            activeColor: color,
            onChanged: (val) => onQtyChange(double.parse(val.toStringAsFixed(0))),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Suggested Price: ₹${price.toStringAsFixed(1)} / kg',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              ),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline_rounded, size: 20),
                    onPressed: () => onPriceChange(price - 1.0),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline_rounded, size: 20),
                    onPressed: () => onPriceChange(price + 1.0),
                    constraints: const BoxConstraints(),
                    padding: const EdgeInsets.all(4),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubBatchCard(BuildContext context, MarketSubBatch sub, bool isDark) {
    return OnionCard(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    sub.gradeName,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    sub.subBatchId,
                    style: const TextStyle(
                      fontFamily: 'monospace',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.primary.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '${sub.quantityKg.toStringAsFixed(0)} kg',
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: AppColors.primary),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Small QR Preview
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFE2E8F0)),
                ),
                child: QrImageView(
                  data: sub.qrPayload,
                  version: QrVersions.auto,
                  size: 80,
                  gapless: true,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Market: ${sub.targetMarket}',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Suggested Price: ₹${sub.suggestedPricePerKg}/kg',
                      style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    ElevatedButton.icon(
                      onPressed: () {
                        // Switch role to seller and simulate scanning this sub-batch
                        final auth = Provider.of<AuthProvider>(context, listen: false);
                        final seller = Provider.of<SellerProvider>(context, listen: false);

                        auth.quickDemoLogin(UserRole.seller);
                        seller.setVerifiedBatch(widget.batch);
                        seller.updatePricing(sellingPrice: sub.suggestedPricePerKg);

                        Navigator.push(
                          context,
                          MaterialPageRoute(builder: (_) => const SellerBatchDetailsScreen()),
                        );
                      },
                      icon: const Icon(Icons.qr_code_scanner_rounded, size: 14),
                      label: const Text('Simulate Scan by Market Seller', style: TextStyle(fontSize: 11)),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                        backgroundColor: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
