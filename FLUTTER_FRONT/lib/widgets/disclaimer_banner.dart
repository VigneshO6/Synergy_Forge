import 'package:flutter/material.dart';
import '../core/constants/app_colors.dart';
import '../core/constants/app_strings.dart';

class DisclaimerBanner extends StatefulWidget {
  final bool compact;

  const DisclaimerBanner({super.key, this.compact = false});

  @override
  State<DisclaimerBanner> createState() => _DisclaimerBannerState();
}

class _DisclaimerBannerState extends State<DisclaimerBanner> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E2619) : const Color(0xFFF0FDF4),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? const Color(0xFF334A2E) : const Color(0xFFBBF7D0),
          width: 1,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Padding(
                padding: EdgeInsets.only(top: 2),
                child: Icon(
                  Icons.info_outline_rounded,
                  size: 18,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'TECHNICAL SPECIFICATION & LIMITATION',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                        color: isDark ? const Color(0xFF86EFAC) : const Color(0xFF166534),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      widget.compact
                          ? AppStrings.rgbLimitationShort
                          : AppStrings.rgbLimitationDisclaimer,
                      style: TextStyle(
                        fontSize: 12.5,
                        height: 1.35,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              if (!widget.compact)
                IconButton(
                  icon: Icon(
                    _isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down,
                    size: 18,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                  onPressed: () => setState(() => _isExpanded = !_isExpanded),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
          if (_isExpanded && !widget.compact) ...[
            const SizedBox(height: 8),
            Divider(
              color: isDark ? const Color(0xFF283D24) : const Color(0xFFDCFCE7),
              height: 1,
            ),
            const SizedBox(height: 8),
            Text(
              '• Evaluated features: External skin integrity, rot necrosis, vegetative neck sprouting, color uniformity, and geometric diameter.\n'
              '• Non-evaluated features: Latent internal center rot, bacterial soft rot without outer skin perforation, and internal hollow heart (requires hyperspectral/NIR sensing).',
              style: TextStyle(
                fontSize: 11.5,
                height: 1.4,
                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
              ),
            ),
          ],
        ],
      ),
    );
  }
}
