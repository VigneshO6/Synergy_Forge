import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../../providers/analysis_provider.dart';
import '../../widgets/disclaimer_banner.dart';
import '../../widgets/onion_card.dart';
import '../../widgets/responsive_scaffold.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _urlController;
  late double _goodThreshold;
  late double _defectTolerance;

  @override
  void initState() {
    super.initState();
    final analysis = Provider.of<AnalysisProvider>(context, listen: false);
    _urlController = TextEditingController(text: analysis.apiBaseUrl);
    _goodThreshold = analysis.goodThreshold;
    _defectTolerance = analysis.defectTolerance;
  }

  @override
  void dispose() {
    _urlController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final analysis = Provider.of<AnalysisProvider>(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return ResponsiveScaffold(
      title: 'Vision & Engine Settings',
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const DisclaimerBanner(),
            const SizedBox(height: 16),

            // Engine Mode Selection
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
                        child: const Icon(Icons.memory_rounded, color: AppColors.primary, size: 20),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Image Analysis Engine',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                            ),
                            Text(
                              analysis.isDemoMode
                                  ? 'Active: Calibrated Demo Vision (Offline)'
                                  : 'Active: Python REST Backend (${analysis.apiBaseUrl})',
                              style: TextStyle(
                                fontSize: 12,
                                color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Switch(
                        value: !analysis.isDemoMode,
                        activeColor: AppColors.primary,
                        onChanged: (val) {
                          analysis.toggleDemoMode(!val);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    analysis.isDemoMode
                        ? '• Demo mode provides realistic sample distributions and bounding box simulations for academic and field testing without requiring a live Python backend.'
                        : '• REST API mode streams sample photos to your FastAPI / OpenCV server at POST /api/analyse for custom model inferencing.',
                    style: TextStyle(
                      fontSize: 12.5,
                      height: 1.4,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  if (!analysis.isDemoMode) ...[
                    const SizedBox(height: 16),
                    TextField(
                      controller: _urlController,
                      decoration: InputDecoration(
                        labelText: 'FastAPI Backend URL',
                        hintText: 'http://localhost:8000',
                        suffixIcon: IconButton(
                          icon: const Icon(Icons.check_rounded, color: AppColors.primary),
                          onPressed: () {
                            analysis.setApiBaseUrl(_urlController.text.trim());
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('API URL updated.')),
                            );
                          },
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Threshold Configuration
            OnionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: AppColors.onionAmber.withOpacity(0.12),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.tune_rounded, color: AppColors.onionAmber, size: 20),
                      ),
                      const SizedBox(width: 12),
                      const Text(
                        'Quality Grade Thresholds',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Good Quality Minimum: ${_goodThreshold.toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Slider(
                    value: _goodThreshold,
                    min: 50,
                    max: 90,
                    divisions: 8,
                    activeColor: AppColors.goodQuality,
                    label: '${_goodThreshold.toStringAsFixed(0)}%',
                    onChanged: (val) {
                      setState(() => _goodThreshold = val);
                      analysis.updateThresholds(good: _goodThreshold, defectTolerance: _defectTolerance);
                    },
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Defect & Sprout Max Tolerance: ${_defectTolerance.toStringAsFixed(0)}%',
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  Slider(
                    value: _defectTolerance,
                    min: 3,
                    max: 20,
                    divisions: 17,
                    activeColor: AppColors.defectiveQuality,
                    label: '${_defectTolerance.toStringAsFixed(0)}%',
                    onChanged: (val) {
                      setState(() => _defectTolerance = val);
                      analysis.updateThresholds(good: _goodThreshold, defectTolerance: _defectTolerance);
                    },
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Rule: Good >= ${_goodThreshold.toStringAsFixed(0)}% and Defects <= ${_defectTolerance.toStringAsFixed(0)}% → Grade A (Export), otherwise Commercial Grade / Needs Sorting.',
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // Reset Samples & Cache
            OnionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Data & Sample Cache',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Reset representative sample inspection tray to default factory sample images.',
                    style: TextStyle(
                      fontSize: 12.5,
                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                    ),
                  ),
                  const SizedBox(height: 14),
                  OutlinedButton.icon(
                    onPressed: () {
                      analysis.resetSamples();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Sample image tray reset to defaults.')),
                      );
                    },
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Reset Sample Images'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
