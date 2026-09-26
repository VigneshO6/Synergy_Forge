import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/quality_model.dart';

class DonutChartWidget extends StatefulWidget {
  final QualityAnalysisResult result;
  final double size;

  const DonutChartWidget({
    super.key,
    required this.result,
    this.size = 200,
  });

  @override
  State<DonutChartWidget> createState() => _DonutChartWidgetState();
}

class _DonutChartWidgetState extends State<DonutChartWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic);
    _controller.forward();
  }

  @override
  void didUpdateWidget(DonutChartWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.result.goodPercentage != widget.result.goodPercentage) {
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final segments = [
      ChartSegment(
        label: 'Good',
        value: widget.result.goodPercentage,
        count: widget.result.good,
        color: AppColors.goodQuality,
      ),
      ChartSegment(
        label: 'Defective',
        value: widget.result.defectivePercentage,
        count: widget.result.defective,
        color: AppColors.defectiveQuality,
      ),
      ChartSegment(
        label: 'Sprouted',
        value: widget.result.sproutedPercentage,
        count: widget.result.sprouted,
        color: AppColors.sproutedQuality,
      ),
      ChartSegment(
        label: 'Undersized',
        value: widget.result.undersizedPercentage,
        count: widget.result.undersized,
        color: AppColors.undersizedQuality,
      ),
    ];

    return Column(
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: Size(widget.size, widget.size),
                    painter: _DonutChartPainter(
                      segments: segments,
                      progress: _animation.value,
                      strokeWidth: 26,
                      backgroundColor: isDark
                          ? AppColors.darkSurfaceElevated
                          : AppColors.lightSurfaceElevated,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '${widget.result.goodPercentage.toStringAsFixed(0)}%',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: isDark
                              ? AppColors.darkTextPrimary
                              : AppColors.lightTextPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        widget.result.overallQuality.toUpperCase(),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.8,
                          color: AppColors.goodQuality,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${widget.result.totalDetected} onions',
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppColors.darkTextMuted
                              : AppColors.lightTextMuted,
                        ),
                      ),
                    ],
                  ),
                ],
              );
            },
          ),
        ),
        const SizedBox(height: 24),
        // Legend Grid
        Wrap(
          spacing: 12,
          runSpacing: 8,
          alignment: WrapAlignment.center,
          children: segments.map((seg) {
            return Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: seg.color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${seg.label} (${seg.count} • ${seg.value.toStringAsFixed(1)}%)',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isDark
                        ? AppColors.darkTextSecondary
                        : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            );
          }).toList(),
        ),
      ],
    );
  }
}

class ChartSegment {
  final String label;
  final double value;
  final int count;
  final Color color;

  ChartSegment({
    required this.label,
    required this.value,
    required this.count,
    required this.color,
  });
}

class _DonutChartPainter extends CustomPainter {
  final List<ChartSegment> segments;
  final double progress;
  final double strokeWidth;
  final Color backgroundColor;

  _DonutChartPainter({
    required this.segments,
    required this.progress,
    required this.strokeWidth,
    required this.backgroundColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width - strokeWidth) / 2;

    // Draw background track
    final bgPaint = Paint()
      ..color = backgroundColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;
    canvas.drawCircle(center, radius, bgPaint);

    final total = segments.fold(0.0, (acc, s) => acc + s.value);
    if (total <= 0) return;

    double startAngle = -math.pi / 2;
    final maxAngle = 2 * math.pi * progress;
    double accumulatedAngle = 0.0;

    for (final seg in segments) {
      if (seg.value <= 0) continue;
      final sweepAngle = (seg.value / total) * (2 * math.pi);
      final currentSweep = math.min(sweepAngle, math.max(0.0, maxAngle - accumulatedAngle));

      if (currentSweep > 0) {
        final paint = Paint()
          ..color = seg.color
          ..style = PaintingStyle.stroke
          ..strokeWidth = strokeWidth
          ..strokeCap = StrokeCap.round;

        final rect = Rect.fromCircle(center: center, radius: radius);
        // Slightly inset each arc so there's an aesthetic gap
        const gap = 0.035;
        if (currentSweep > gap) {
          canvas.drawArc(rect, startAngle + (gap / 2), currentSweep - gap, false, paint);
        } else {
          canvas.drawArc(rect, startAngle, currentSweep, false, paint);
        }
      }

      startAngle += sweepAngle;
      accumulatedAngle += sweepAngle;
      if (accumulatedAngle >= maxAngle) break;
    }
  }

  @override
  bool shouldRepaint(covariant _DonutChartPainter oldDelegate) {
    return oldDelegate.progress != progress || oldDelegate.segments != segments;
  }
}
