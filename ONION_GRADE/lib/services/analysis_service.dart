import 'dart:typed_data';
import '../models/quality_model.dart';

abstract class ImageAnalysisService {
  Future<QualityAnalysisResult> analyzeSamples({
    required String batchId,
    required List<String> imagePaths,
    Uint8List? sampleBytes,
    void Function(String stepMessage, double progress)? onProgress,
  });

  String get serviceName;
  bool get isDemoMode;
}
