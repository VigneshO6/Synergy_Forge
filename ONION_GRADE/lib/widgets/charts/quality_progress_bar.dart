import 'package:flutter/material.dart';
import '../../core/constants/app_colors.dart';
import '../../models/quality_model.dart';

class QualityProgressBar extends StatelessWidget {
  final QualityAnalysisResult result;
  final double height;

  const QualityProgressBar({
    super.key,
    required this.result,
    this.height = 12,
  });

  @override
  Widget build(BuildContext context) {
    final total = result.good +
        result.defective +
        result.sprouted +
        result.undersized;

    if (total == 0) return const SizedBox.shrink();

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: SizedBox(
        height: height,
        child: Row(
          children: [
            if (result.good > 0)
              Expanded(
                flex: result.good,
                child: Container(color: AppColors.goodQuality),
              ),
            if (result.defective > 0)
              Expanded(
                flex: result.defective,
                child: Container(color: AppColors.defectiveQuality),
              ),
            if (result.sprouted > 0)
              Expanded(
                flex: result.sprouted,
                child: Container(color: AppColors.sproutedQuality),
              ),
            if (result.undersized > 0)
              Expanded(
                flex: result.undersized,
                child: Container(color: AppColors.undersizedQuality),
              ),
          ],
        ),
      ),
    );
  }
}
