import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/batch_model.dart';
import '../../providers/analysis_provider.dart';
import '../../providers/batch_provider.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../widgets/onion_card.dart';
import '../../widgets/responsive_scaffold.dart';
import 'analysis_result_screen.dart';
import 'sample_capture_screen.dart';

class SampleReviewScreen extends StatefulWidget {
  final OnionBatch batch;

  const SampleReviewScreen({super.key, required this.batch});

  @override
  State<SampleReviewScreen> createState() => _SampleReviewScreenState();
}

class _SampleReviewScreenState extends State<SampleReviewScreen> {
  Future<void> _startAnalysis() async {
    final analysis = Provider.of<AnalysisProvider>(context, listen: false);
    final batchProv = Provider.of<BatchProvider>(context, listen: false);

    final result = await analysis.runAnalysis(widget.batch.id);

    if (result != null && mounted) {
      // Save result to batch repository
      batchProv.attachQualityResult(
        widget.batch.id,
        result,
        analysis.sampleImages,
      );

      // Navigate to results screen
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => AnalysisResultScreen(
            batch: widget.batch.copyWith(
              qualityResult: result,
              status: 'Analysed',
            ),
            result: result,
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final analysis = Provider.of<AnalysisProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final samples = analysis.sampleImages;

    return ResponsiveScaffold(
      title: 'Sample Review',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DisclaimerBanner(compact: true),
            const SizedBox(height: 16),

            if (analysis.isAnalyzing) ...[
              // Animated Analysis Progress Screen
              _buildAnalyzingCard(context, analysis, isDark),
            ] else ...[
              // Review Samples Layout
              OnionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'SAMPLE REVIEW',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.8,
                            color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.primary.withOpacity(0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            '${samples.length} Images Selected',
                            style: const TextStyle(
                              color: AppColors.primary,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Batch: ${widget.batch.id}',
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900, fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 16),

                    // Thumbnails list
                    if (samples.isEmpty)
                      const Padding(
                        padding: EdgeInsets.symmetric(vertical: 30),
                        child: Center(child: Text('No sample images in tray.')),
                      )
                    else
                      SizedBox(
                        height: 130,
                        child: ListView.separated(
                          scrollDirection: Axis.horizontal,
                          itemCount: samples.length,
                          separatorBuilder: (_, __) => const SizedBox(width: 10),
                          itemBuilder: (context, index) {
                            return ClipRRect(
                              borderRadius: BorderRadius.circular(12),
                              child: Stack(
                                children: [
                                  analysis.sampleItems[index].buildThumbnail(
                                    width: 140,
                                    height: 130,
                                    fit: BoxFit.cover,
                                  ),
                                  Positioned(
                                    bottom: 0,
                                    left: 0,
                                    right: 0,
                                    child: Container(
                                      color: Colors.black.withOpacity(0.6),
                                      padding: const EdgeInsets.all(4),
                                      child: Text(
                                        'Img #${index + 1}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          },
                        ),
                      ),
                    const SizedBox(height: 16),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Images: ${samples.length}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Text(
                          analysis.isDemoMode ? 'Engine: Demo Vision' : 'Engine: Python REST',
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

              const SizedBox(height: 16),

              // Action Buttons: Add More & Analyse
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => SampleCaptureScreen(batch: widget.batch),
                          ),
                        );
                      },
                      icon: const Icon(Icons.add_photo_alternate_rounded, size: 18),
                      label: const Text('ADD MORE'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton.icon(
                      onPressed: samples.isEmpty ? null : _startAnalysis,
                      icon: const Icon(Icons.auto_awesome_rounded, size: 20),
                      label: const Text('ANALYSE SAMPLES'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildAnalyzingCard(BuildContext context, AnalysisProvider analysis, bool isDark) {
    final steps = [
      'Uploading images...',
      'Detecting onions...',
      'Analysing visible quality...',
      'Calculating quality distribution...',
      'Generating report...',
    ];

    return OnionCard(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Center(
              child: SizedBox(
                width: 38,
                height: 38,
                child: CircularProgressIndicator(strokeWidth: 3, color: AppColors.primary),
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Analysing Samples...',
            style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 6),
          Text(
            analysis.currentStepMessage,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: analysis.currentProgress,
              minHeight: 10,
              backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
            ),
          ),
          const SizedBox(height: 24),
          // Animated Step Indicators
          Column(
            children: steps.map((step) {
              final isCurrent = analysis.currentStepMessage.toLowerCase().contains(step.substring(0, 5).toLowerCase());
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 5),
                child: Row(
                  children: [
                    Icon(
                      isCurrent ? Icons.radio_button_checked_rounded : Icons.check_circle_outline_rounded,
                      size: 16,
                      color: isCurrent ? AppColors.primary : Colors.grey,
                    ),
                    const SizedBox(width: 10),
                    Text(
                      step,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isCurrent ? FontWeight.bold : FontWeight.normal,
                        color: isCurrent ? AppColors.primary : Colors.grey,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}
