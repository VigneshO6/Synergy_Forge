import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../models/batch_model.dart';
import '../../models/quality_model.dart';
import '../../providers/analysis_provider.dart';
import '../../services/pdf_report_service.dart';
import '../../widgets/charts/donut_chart_widget.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../widgets/onion_badge.dart';
import '../../widgets/onion_card.dart';
import '../../widgets/responsive_scaffold.dart';
import 'quality_report_screen.dart';
import 'qr_view_screen.dart';
import 'sorting_screen.dart';

class AnalysisResultScreen extends StatefulWidget {
  final OnionBatch batch;
  final QualityAnalysisResult result;

  const AnalysisResultScreen({
    super.key,
    required this.batch,
    required this.result,
  });

  @override
  State<AnalysisResultScreen> createState() => _AnalysisResultScreenState();
}

class _AnalysisResultScreenState extends State<AnalysisResultScreen> {
  bool _showBoundingBoxes = true;
  bool _isDownloadingPdf = false;

  Future<void> _handleDownloadPdf() async {
    setState(() => _isDownloadingPdf = true);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Compiling official PDF certificate for ${widget.batch.id}...'),
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
                Expanded(child: Text('Downloaded: $fileName')),
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
            content: Text('Download failed: $e'),
            backgroundColor: Colors.redAccent,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isDownloadingPdf = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final r = widget.result;

    return ResponsiveScaffold(
      title: 'Quality Analysis',
      actions: [
        IconButton(
          tooltip: 'Download PDF Certificate',
          icon: _isDownloadingPdf
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.download_rounded),
          onPressed: _isDownloadingPdf ? null : _handleDownloadPdf,
        ),
        IconButton(
          tooltip: 'Batch QR Code',
          icon: const Icon(Icons.qr_code_2_rounded),
          onPressed: () {
            final updatedBatch = widget.batch.copyWith(
              qualityResult: widget.result,
              status: 'Analysed',
            );
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (_) => QrViewScreen(
                  batch: updatedBatch,
                  qualityResult: widget.result,
                ),
              ),
            );
          },
        ),
      ],
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const DisclaimerBanner(),
            const SizedBox(height: 16),

            // If zero onions were detected, show prominent alert banner
            if (r.totalDetected == 0) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 16),
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFFEF4444).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.45),
                    width: 1.5,
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.image_not_supported_rounded,
                        color: Color(0xFFEF4444),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'NO ONION BULBS DETECTED',
                            style: TextStyle(
                              color: Color(0xFFEF4444),
                              fontWeight: FontWeight.w900,
                              fontSize: 13.5,
                              letterSpacing: 0.5,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'The AI deep vision system (YOLO11) analyzed this image and found 0 onion bulbs. This image appears to be a diagram, document, or non-produce subject.',
                            style: TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                          const SizedBox(height: 10),
                          FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: const Color(0xFFEF4444),
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                            onPressed: () => Navigator.pop(context),
                            icon: const Icon(Icons.refresh_rounded, size: 16),
                            label: const Text('Capture or Upload Real Produce'),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],

            // Header Overview Card
            OnionCard(
              hasGlow: true,
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'SAMPLE BATCH ASSESSED',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            widget.batch.id,
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              fontFamily: 'monospace',
                            ),
                          ),
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          r.totalDetected == 0 ? 'Total Sample: 0 (No Produce)' : 'Total Sample: ${r.totalDetected} onions',
                          style: TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                            color: r.totalDetected == 0 ? const Color(0xFFEF4444) : null,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Donut Chart
                  DonutChartWidget(result: r, size: 210),

                  const SizedBox(height: 18),
                  Divider(color: isDark ? AppColors.darkBorder : AppColors.lightBorder),
                  const SizedBox(height: 10),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Overall Sample Quality',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                      ),
                      QualityBadge(category: r.overallQuality),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // 4 Quality Distribution Cards (Good, Defective, Sprouted, Undersized - Medium removed)
            Text(
              'QUALITY CATEGORIES (4-CLASS SYSTEM)',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.8,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: _buildCategoryCard(
                    title: 'GOOD BULBS',
                    count: r.good,
                    pct: r.goodPercentage,
                    color: AppColors.goodQuality,
                    icon: Icons.check_circle_outline_rounded,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCategoryCard(
                    title: 'DEFECTIVE',
                    count: r.defective,
                    pct: r.defectivePercentage,
                    color: AppColors.defectiveQuality,
                    icon: Icons.highlight_off_rounded,
                    isDark: isDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildCategoryCard(
                    title: 'SPROUTED',
                    count: r.sprouted,
                    pct: r.sproutedPercentage,
                    color: AppColors.sproutedQuality,
                    icon: Icons.eco_outlined,
                    isDark: isDark,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildCategoryCard(
                    title: 'UNDERSIZED (URS)',
                    count: r.undersized,
                    pct: r.undersizedPercentage,
                    color: AppColors.undersizedQuality,
                    icon: Icons.aspect_ratio_rounded,
                    isDark: isDark,
                    subtitle: 'Non-defective (<40mm)',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Computer Vision Bounding Box Inspection Toggle
            if (r.detectedItems.isNotEmpty) ...[
              OnionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(6),
                              decoration: BoxDecoration(
                                color: AppColors.primary.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.filter_center_focus_rounded, size: 18, color: AppColors.primary),
                            ),
                            const SizedBox(width: 10),
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Visual Bounding Box Overlay',
                                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                                ),
                                Text(
                                  '${r.detectedItems.length} onion bulb(s) detected by AI',
                                  style: TextStyle(
                                    fontSize: 11.5,
                                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                        Switch(
                          value: _showBoundingBoxes,
                          activeTrackColor: AppColors.primary,
                          onChanged: (val) => setState(() => _showBoundingBoxes = val),
                        ),
                      ],
                    ),
                    if (_showBoundingBoxes) ...[
                      const SizedBox(height: 14),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Container(
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF0F1A15) : const Color(0xFF1E293B),
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: AppColors.primary.withValues(alpha: 0.4),
                              width: 1.5,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(alpha: 0.15),
                                blurRadius: 12,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: AspectRatio(
                            aspectRatio: 4 / 3,
                            child: LayoutBuilder(
                              builder: (context, constraints) {
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    // 1. Given Image Background (Camera, Gallery, or Asset)
                                    _buildGivenImage(context),

                                    // 2. High-contrast subtle overlay for clean bounding box contrast
                                    Container(
                                      decoration: BoxDecoration(
                                        gradient: LinearGradient(
                                          colors: [
                                            Colors.black.withValues(alpha: 0.10),
                                            Colors.black.withValues(alpha: 0.25),
                                          ],
                                          begin: Alignment.topCenter,
                                          end: Alignment.bottomCenter,
                                        ),
                                      ),
                                    ),

                                    // 3. Clean Red Non-Overlapping Bounding Boxes
                                    ...r.detectedItems.asMap().entries.map((entry) {
                                      final index = entry.key;
                                      final box = entry.value;
                                      final cat = box.category.toLowerCase();
                                      final Color boxColor = cat == 'sprouted'
                                          ? const Color(0xFFF59E0B) // Amber for Sprouted
                                          : cat == 'defective'
                                              ? const Color(0xFFEF4444) // Red for Defective
                                              : (cat == 'urs' || cat == 'undersized')
                                                  ? const Color(0xFF6366F1) // Indigo for URS
                                                  : const Color(0xFF10B981); // Emerald for Good

                                      // Normalized or absolute positioning
                                      double left, top, width, height;
                                      if (box.normX != null && box.normW != null && box.normW! > 0) {
                                        left = box.normX! * constraints.maxWidth;
                                        top = (box.normY ?? 0.0) * constraints.maxHeight;
                                        width = box.normW! * constraints.maxWidth;
                                        height = (box.normH ?? 0.1) * constraints.maxHeight;
                                      } else {
                                        final scaleX = constraints.maxWidth / 640.0;
                                        final scaleY = constraints.maxHeight / 480.0;
                                        left = box.x * scaleX;
                                        top = box.y * scaleY;
                                        width = box.width * scaleX;
                                        height = box.height * scaleY;
                                      }

                                      left = left.clamp(0.0, constraints.maxWidth - 20);
                                      top = top.clamp(0.0, constraints.maxHeight - 20);
                                      width = width.clamp(24.0, constraints.maxWidth - left);
                                      height = height.clamp(24.0, constraints.maxHeight - top);

                                      return Positioned(
                                        left: left,
                                        top: top,
                                        width: width,
                                        height: height,
                                        child: Container(
                                          decoration: BoxDecoration(
                                            border: Border.all(
                                              color: boxColor,
                                              width: 2.2,
                                            ),
                                            borderRadius: BorderRadius.circular(6),
                                            color: boxColor.withValues(alpha: 0.14),
                                          ),
                                          child: Align(
                                            alignment: Alignment.topLeft,
                                            child: Container(
                                              margin: const EdgeInsets.only(top: 2, left: 2),
                                              padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.black.withValues(alpha: 0.90),
                                                borderRadius: BorderRadius.circular(4),
                                                border: Border.all(color: boxColor, width: 1.0),
                                              ),
                                              child: Row(
                                                mainAxisSize: MainAxisSize.min,
                                                children: [
                                                  Container(
                                                    width: 5,
                                                    height: 5,
                                                    decoration: BoxDecoration(
                                                      color: boxColor,
                                                      shape: BoxShape.circle,
                                                    ),
                                                  ),
                                                  const SizedBox(width: 4),
                                                  Text(
                                                    'ONION #${index + 1} ${(box.confidence * 100).toInt()}% • ${box.category.toUpperCase()}',
                                                    style: const TextStyle(
                                                      color: Colors.white,
                                                      fontSize: 8.5,
                                                      fontWeight: FontWeight.w800,
                                                      letterSpacing: 0.2,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            ),
                                          ),
                                        ),
                                      );
                                    }),

                                    // 4. Clean Bottom Badge
                                    Positioned(
                                      bottom: 10,
                                      left: 10,
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                        decoration: BoxDecoration(
                                          color: Colors.black.withValues(alpha: 0.82),
                                          borderRadius: BorderRadius.circular(20),
                                          border: Border.all(color: Colors.white24, width: 0.8),
                                        ),
                                        child: Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            const Icon(Icons.verified_rounded, size: 14, color: AppColors.primary),
                                            const SizedBox(width: 6),
                                            Text(
                                              'YOLO11: ${r.detectedItems.length} Bulbs Bounded',
                                              style: const TextStyle(
                                                color: Colors.white,
                                                fontSize: 11,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      // Clean Bulb Detection Status
                      Center(
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                          decoration: BoxDecoration(
                            color: isDark ? const Color(0xFF14241D) : const Color(0xFFE8F5E9),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 8,
                                height: 8,
                                decoration: const BoxDecoration(
                                  color: AppColors.primary,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'YOLO11 Detection: ${r.detectedItems.length} Onion Bulbs Segmented',
                                style: const TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ] else ...[
              OnionCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.search_off_rounded, size: 18, color: Color(0xFFEF4444)),
                        ),
                        const SizedBox(width: 10),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Sample Image Preview',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                            ),
                            Text(
                              '0 onion bulb(s) detected • Bounding boxes disabled',
                              style: TextStyle(
                                fontSize: 11.5,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Container(
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF0F1A15) : const Color(0xFF1E293B),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.35),
                            width: 1.5,
                          ),
                        ),
                        child: AspectRatio(
                          aspectRatio: 4 / 3,
                          child: Stack(
                            fit: StackFit.expand,
                            children: [
                              _buildGivenImage(context),
                              Container(
                                color: Colors.black.withValues(alpha: 0.30),
                                child: Center(
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      color: Colors.black87,
                                      borderRadius: BorderRadius.circular(20),
                                      border: Border.all(color: const Color(0xFFEF4444), width: 1.5),
                                    ),
                                    child: const Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.close_rounded, color: Color(0xFFEF4444), size: 16),
                                        SizedBox(width: 6),
                                        Text(
                                          'No Onion Bulbs Found in Image',
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontWeight: FontWeight.w700,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                        decoration: BoxDecoration(
                          color: isDark ? const Color(0xFF261214) : const Color(0xFFFEE2E2),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.warning_amber_rounded, color: Color(0xFFEF4444), size: 14),
                            SizedBox(width: 6),
                            Text(
                              'YOLO11 Detection: 0 Onion Bulbs Found (Non-Produce Image)',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFFEF4444),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Observations Card
            OnionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.remove_red_eye_outlined, size: 18, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Text(
                        'IMAGE ANALYSIS OBSERVATIONS',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.6,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  ...r.observations.map((obs) {
                    final isWarning = obs.toLowerCase().contains('damage') ||
                        obs.toLowerCase().contains('sprout') ||
                        obs.toLowerCase().contains('blemish') ||
                        obs.toLowerCase().contains('undersize');

                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(
                            isWarning ? Icons.warning_amber_rounded : Icons.check_circle_rounded,
                            size: 16,
                            color: isWarning ? AppColors.onionAmber : AppColors.goodQuality,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              obs,
                              style: TextStyle(
                                fontSize: 13,
                                height: 1.35,
                                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // CTAs
            // Primary Action: Download Report PDF & View Report
            Row(
              children: [
                Expanded(
                  flex: 3,
                  child: ElevatedButton.icon(
                    onPressed: _isDownloadingPdf ? null : _handleDownloadPdf,
                    icon: _isDownloadingPdf
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.download_rounded, size: 20),
                    label: Text(
                      _isDownloadingPdf ? 'DOWNLOADING...' : 'DOWNLOAD REPORT (PDF)',
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
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QualityReportScreen(batch: widget.batch, result: r),
                        ),
                      );
                    },
                    icon: const Icon(Icons.description_rounded, size: 18),
                    label: const Text('VIEW REPORT'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () {
                      final updatedBatch = widget.batch.copyWith(
                        qualityResult: widget.result,
                        status: 'Analysed',
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => QrViewScreen(
                            batch: updatedBatch,
                            qualityResult: widget.result,
                          ),
                        ),
                      );
                    },
                    icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                    label: const Text('GENERATE QR'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => SortingScreen(batch: widget.batch),
                        ),
                      );
                    },
                    icon: const Icon(Icons.splitscreen_rounded, size: 18),
                    label: const Text('SORT BATCH'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF8B5CF6),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 14),
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

  Widget _buildCategoryCard({
    required String title,
    required int count,
    required double pct,
    required Color color,
    required IconData icon,
    required bool isDark,
    String? subtitle,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: color.withOpacity(0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.4,
                  color: color,
                ),
              ),
              Icon(icon, size: 14, color: color),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                '$count',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
              ),
              const SizedBox(width: 6),
              Text(
                '${pct.toStringAsFixed(1)}%',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ],
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 3),
            Text(
              subtitle,
              style: TextStyle(
                fontSize: 9.5,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLegendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }

  Widget _buildGivenImage(BuildContext context) {
    final sampleItems = Provider.of<AnalysisProvider>(context, listen: false).sampleItems;
    if (sampleItems.isNotEmpty) {
      return sampleItems.first.buildThumbnail(fit: BoxFit.fill);
    }
    if (widget.batch.sampleImagePaths.isNotEmpty) {
      final path = widget.batch.sampleImagePaths.first;
      if (path.startsWith('assets/')) {
        return Image.asset(
          path,
          fit: BoxFit.fill,
          errorBuilder: (_, __, ___) => _buildFallbackImage(),
        );
      } else if (path.startsWith('http')) {
        return Image.network(
          path,
          fit: BoxFit.fill,
          errorBuilder: (_, __, ___) => _buildFallbackImage(),
        );
      }
    }
    return _buildFallbackImage();
  }

  Widget _buildFallbackImage() {
    return Image.asset(
      'assets/images/sample_grid.jpg',
      fit: BoxFit.fill,
      errorBuilder: (_, __, ___) => Container(
        color: const Color(0xFF1E293B),
        child: const Center(
          child: Icon(Icons.grain_rounded, size: 48, color: Colors.white24),
        ),
      ),
    );
  }
}
