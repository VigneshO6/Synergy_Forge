class OnionBBox {
  final int x1;
  final int y1;
  final int x2;
  final int y2;
  final int width;
  final int height;
  final double? normX;
  final double? normY;
  final double? normW;
  final double? normH;

  OnionBBox({
    required this.x1,
    required this.y1,
    required this.x2,
    required this.y2,
    required this.width,
    required this.height,
    this.normX,
    this.normY,
    this.normW,
    this.normH,
  });

  factory OnionBBox.fromJson(
    Map<String, dynamic> json,
    Map<String, dynamic>? normJson, [
    int? imgWidth,
    int? imgHeight,
  ]) {
    final x1 = (json['x1'] as num?)?.toInt() ?? 0;
    final y1 = (json['y1'] as num?)?.toInt() ?? 0;
    final x2 = (json['x2'] as num?)?.toInt() ?? (x1 + 40);
    final y2 = (json['y2'] as num?)?.toInt() ?? (y1 + 40);
    final w = (json['width'] as num?)?.toInt() ?? (x2 - x1);
    final h = (json['height'] as num?)?.toInt() ?? (y2 - y1);

    double? nx = (normJson?['x'] as num?)?.toDouble() ?? (json['norm_x'] as num?)?.toDouble();
    double? ny = (normJson?['y'] as num?)?.toDouble() ?? (json['norm_y'] as num?)?.toDouble();
    double? nw = (normJson?['width'] as num?)?.toDouble() ?? (json['norm_w'] as num?)?.toDouble();
    double? nh = (normJson?['height'] as num?)?.toDouble() ?? (json['norm_h'] as num?)?.toDouble();

    if ((nw == null || nw <= 0.0) && imgWidth != null && imgWidth > 0) {
      nx = x1 / imgWidth;
      nw = w / imgWidth;
    }
    if ((nh == null || nh <= 0.0) && imgHeight != null && imgHeight > 0) {
      ny = y1 / imgHeight;
      nh = h / imgHeight;
    }

    return OnionBBox(
      x1: x1,
      y1: y1,
      x2: x2,
      y2: y2,
      width: w,
      height: h,
      normX: nx,
      normY: ny,
      normW: nw,
      normH: nh,
    );
  }
}

class OnionDetection {
  final int classId;
  final String label;
  final String category; // 'good', 'defective', 'sprouted', 'urs'
  final double confidence;
  final double categoryConfidence;
  final OnionBBox bbox;

  OnionDetection({
    required this.classId,
    required this.label,
    required this.category,
    required this.confidence,
    required this.categoryConfidence,
    required this.bbox,
  });

  factory OnionDetection.fromJson(Map<String, dynamic> json, [int? imgWidth, int? imgHeight]) {
    final rawBbox = json['bbox'] as Map<String, dynamic>? ?? {};
    final normBbox = (json['normalized_bbox'] ?? rawBbox['normalized_bbox']) as Map<String, dynamic>?;
    String cat = (json['category'] as String? ?? 'good').toLowerCase();
    if (cat == 'medium') cat = 'good';

    return OnionDetection(
      classId: (json['class_id'] as num?)?.toInt() ?? 0,
      label: json['label'] as String? ?? 'onion',
      category: cat,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      categoryConfidence: (json['category_confidence'] as num?)?.toDouble() ?? 90.0,
      bbox: OnionBBox.fromJson(rawBbox, normBbox, imgWidth, imgHeight),
    );
  }
}

class OnionQuality {
  final String label;
  final int classIndex;
  final double confidence;
  final Map<String, double> classProbabilities;

  OnionQuality({
    required this.label,
    required this.classIndex,
    required this.confidence,
    required this.classProbabilities,
  });

  factory OnionQuality.fromJson(Map<String, dynamic> json) {
    final probs = <String, double>{};
    if (json['class_probabilities'] != null) {
      final map = json['class_probabilities'] as Map<String, dynamic>;
      map.forEach((k, v) {
        probs[k] = (v as num).toDouble();
      });
    }

    return OnionQuality(
      label: json['label'] as String? ?? 'Good (Grade A)',
      classIndex: (json['class_index'] as num?)?.toInt() ?? 0,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.0,
      classProbabilities: probs,
    );
  }
}

class AnalysisApiResponse {
  final bool success;
  final String batchId;
  final int totalOnions;
  final int imageWidth;
  final int imageHeight;
  final OnionQuality quality;
  final List<OnionDetection> detections;
  final Map<String, int> counts;
  final Map<String, double> percentages;
  final List<String> observations;
  final String summary;
  final double processingTimeMs;
  final String disclaimer;

  AnalysisApiResponse({
    required this.success,
    required this.batchId,
    required this.totalOnions,
    required this.imageWidth,
    required this.imageHeight,
    required this.quality,
    required this.detections,
    required this.counts,
    required this.percentages,
    required this.observations,
    required this.summary,
    required this.processingTimeMs,
    required this.disclaimer,
  });

  factory AnalysisApiResponse.fromJson(Map<String, dynamic> json) {
    final qualityJson = json['quality'] as Map<String, dynamic>? ?? {};
    final int imgWidth = (json['image_width'] as num?)?.toInt() ?? 0;
    final int imgHeight = (json['image_height'] as num?)?.toInt() ?? 0;
    final detectionsList = (json['detections'] as List<dynamic>?)
            ?.map((e) => OnionDetection.fromJson(e as Map<String, dynamic>, imgWidth, imgHeight))
            .toList() ??
        [];

    final rawCounts = json['counts'] as Map<String, dynamic>? ?? {};
    final countsMap = <String, int>{
      'good': (rawCounts['good'] as num?)?.toInt() ?? 0,
      'defective': (rawCounts['defective'] as num?)?.toInt() ?? 0,
      'sprouted': (rawCounts['sprouted'] as num?)?.toInt() ?? 0,
      'undersized': (rawCounts['undersized'] as num?)?.toInt() ?? 0,
    };

    final rawPcts = json['percentages'] as Map<String, dynamic>? ?? {};
    final pctsMap = <String, double>{
      'good': (rawPcts['good'] as num?)?.toDouble() ?? 0.0,
      'defective': (rawPcts['defective'] as num?)?.toDouble() ?? 0.0,
      'sprouted': (rawPcts['sprouted'] as num?)?.toDouble() ?? 0.0,
      'undersized': (rawPcts['undersized'] as num?)?.toDouble() ?? 0.0,
    };

    final obs = (json['observations'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return AnalysisApiResponse(
      success: json['success'] as bool? ?? true,
      batchId: json['batch_id'] as String? ?? 'BTH-UNKNOWN',
      totalOnions: (json['total_onions'] as num?)?.toInt() ?? detectionsList.length,
      imageWidth: (json['image_width'] as num?)?.toInt() ?? 640,
      imageHeight: (json['image_height'] as num?)?.toInt() ?? 640,
      quality: OnionQuality.fromJson(qualityJson),
      detections: detectionsList,
      counts: countsMap,
      percentages: pctsMap,
      observations: obs,
      summary: json['summary'] as String? ?? '',
      processingTimeMs: (json['processing_time_ms'] as num?)?.toDouble() ?? 0.0,
      disclaimer: json['disclaimer'] as String? ?? '',
    );
  }
}
