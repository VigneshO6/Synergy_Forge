import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/seller_provider.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../widgets/onion_card.dart';
import '../../widgets/responsive_scaffold.dart';
import 'quality_comparison_screen.dart';

class SellerSampleCaptureScreen extends StatefulWidget {
  const SellerSampleCaptureScreen({super.key});

  @override
  State<SellerSampleCaptureScreen> createState() => _SellerSampleCaptureScreenState();
}

class _SellerSampleCaptureScreenState extends State<SellerSampleCaptureScreen> {
  Future<void> _runVerification() async {
    final seller = Provider.of<SellerProvider>(context, listen: false);
    await seller.runSellerVerificationAnalysis();

    if (mounted) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const QualityComparisonScreen()),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final seller = Provider.of<SellerProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final samples = seller.receivedSampleImages;

    return ResponsiveScaffold(
      title: 'Arrival Sample Verification',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DisclaimerBanner(compact: true),
            const SizedBox(height: 16),

            if (seller.isAnalyzing) ...[
              // Animated Analysis Progress
              OnionCard(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: AppColors.primary.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: SizedBox(
                          width: 34,
                          height: 34,
                          child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Text(
                      'Running Second CV Inspection...',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      seller.analysisProgressMessage,
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(6),
                      child: LinearProgressIndicator(
                        value: seller.analysisProgress,
                        minHeight: 8,
                        backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                        valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                      ),
                    ),
                  ],
                ),
              ),
            ] else ...[
              OnionCard(
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
                          child: const Icon(Icons.store_mall_directory_rounded, color: AppColors.primary, size: 20),
                        ),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Wholesale Mandi Arrival Sampling',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              'Capture representative sample from unloading bay',
                              style: TextStyle(fontSize: 11.5, color: Colors.grey),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Take representative photos of the onions as unloaded from the transit truck to calibrate transit degradation before wholesale auction.',
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.4,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // Non-Overlapping Upload Action
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    seller.addReceivedAssetSample('assets/images/sample_grid.jpg', 'NonOverlapping_Arrival_Grid.jpg');
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Non-overlapping onion sample loaded for arrival verification!'),
                        backgroundColor: Color(0xFFDC2626),
                        behavior: SnackBarBehavior.floating,
                      ),
                    );
                  },
                  icon: const Icon(Icons.grid_view_rounded, size: 18),
                  label: const Text('UPLOAD NON-OVERLAPPING ONIONS (GRID SAMPLE)'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFDC2626),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Capture Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final success = await seller.captureArrivalWithCamera();
                        if (!context.mounted) return;
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Arrival photo captured from camera!'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('OPEN CAMERA'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () async {
                        final success = await seller.pickArrivalFromGallery();
                        if (!context.mounted) return;
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Arrival photo(s) selected from gallery! Ensure no bulb overlap.'),
                              backgroundColor: AppColors.primary,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        }
                      },
                      icon: const Icon(Icons.photo_library_rounded),
                      label: const Text('PICK GALLERY'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 18),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'ARRIVAL SAMPLES (${seller.receivedSampleItems.length})',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                  if (seller.receivedSampleItems.isNotEmpty)
                    TextButton.icon(
                      onPressed: () => seller.clearReceivedSamples(),
                      icon: const Icon(Icons.delete_sweep_rounded, size: 16, color: Colors.redAccent),
                      label: const Text('Clear All', style: TextStyle(color: Colors.redAccent, fontSize: 12, fontWeight: FontWeight.bold)),
                    ),
                ],
              ),
              const SizedBox(height: 10),

              if (seller.receivedSampleItems.isEmpty)
                Container(
                  height: 140,
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.add_a_photo_outlined, size: 38, color: isDark ? Colors.white24 : Colors.black26),
                        const SizedBox(height: 8),
                        Text(
                          'No arrival inspection photos added yet',
                          style: TextStyle(
                            fontSize: 12.5,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        const Text(
                          'Tap OPEN CAMERA or + Mixed Arrival above',
                          style: TextStyle(fontSize: 11.5, color: AppColors.primary, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: seller.receivedSampleItems.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                    childAspectRatio: 1.2,
                  ),
                itemBuilder: (context, index) {
                  final item = seller.receivedSampleItems[index];
                  return ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        item.buildThumbnail(),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: Container(
                            color: Colors.black.withOpacity(0.65),
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Bay #${index + 1}',
                                  style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                ),
                                InkWell(
                                  onTap: () => seller.removeReceivedSample(index),
                                  child: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent, size: 16),
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

              const SizedBox(height: 24),

              ElevatedButton.icon(
                onPressed: samples.isEmpty ? null : _runVerification,
                icon: const Icon(Icons.compare_arrows_rounded),
                label: const Text('RUN SECOND QUALITY ANALYSIS & COMPARISON'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  backgroundColor: AppColors.primary,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
