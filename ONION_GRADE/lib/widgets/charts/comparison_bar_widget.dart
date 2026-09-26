import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';

class ComparisonBarWidget extends StatelessWidget {
  final String categoryTitle;
  final double originalPct;
  final double receivedPct;
  final Color categoryColor;
  final bool lowerIsBetter; // e.g. for defective and sprouted, lower is better

  const ComparisonBarWidget({
    super.key,
    required this.categoryTitle,
    required this.originalPct,
    required this.receivedPct,
    required this.categoryColor,
    this.lowerIsBetter = false,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final delta = receivedPct - originalPct;

    final isGoodChange = lowerIsBetter ? delta <= 0 : delta >= 0;
    final deltaColor = isGoodChange ? AppColors.goodQuality : AppColors.defectiveQuality;
    final deltaSign = delta > 0 ? '+' : '';

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                categoryTitle,
                style: TextStyle(
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: deltaColor.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: deltaColor.withOpacity(0.3), width: 1),
                ),
                child: Text(
                  '$deltaSign${delta.toStringAsFixed(1)}% delta',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: deltaColor,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Original Bar
          Row(
            children: [
              SizedBox(
                width: 65,
                child: Text(
                  'Original:',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (originalPct / 100.0).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(categoryColor.withOpacity(0.6)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 45,
                child: Text(
                  '${originalPct.toStringAsFixed(1)}%',
                  textAlign: TextAlign.right,
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 5),
          // Received Bar
          Row(
            children: [
              SizedBox(
                width: 65,
                child: Text(
                  'Received:',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                ),
              ),
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: LinearProgressIndicator(
                    value: (receivedPct / 100.0).clamp(0.0, 1.0),
                    minHeight: 8,
                    backgroundColor: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                    valueColor: AlwaysStoppedAnimation<Color>(categoryColor),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              SizedBox(
                width: 45,
                child: Text(
                  '${receivedPct.toStringAsFixed(1)}%',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: categoryColor,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
