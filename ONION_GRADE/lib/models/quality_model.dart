class DetectedBoundingBox {
  final int x;
  final int y;
  final int width;
  final int height;
  final String category; // 'good', 'defective', 'sprouted', 'urs'
  final double confidence;
  final double? normX;
  final double? normY;
  final double? normW;
  final double? normH;

  DetectedBoundingBox({
    required this.x,
    required this.y,
    required this.width,
    required this.height,
    required this.category,
    required this.confidence,
    this.normX,
    this.normY,
    this.normW,
    this.normH,
  });

  factory DetectedBoundingBox.fromJson(Map<String, dynamic> json) {
    final rawBbox = json['bbox'] as Map<String, dynamic>?;
    final norm = (json['normalized_bbox'] ?? rawBbox?['normalized_bbox']) as Map<String, dynamic>?;

    final nx = (norm?['x'] as num?)?.toDouble() ??
               (json['norm_x'] as num?)?.toDouble() ??
               (rawBbox?['norm_x'] as num?)?.toDouble();
    final ny = (norm?['y'] as num?)?.toDouble() ??
               (json['norm_y'] as num?)?.toDouble() ??
               (rawBbox?['norm_y'] as num?)?.toDouble();
    final nw = (norm?['width'] as num?)?.toDouble() ??
               (json['norm_w'] as num?)?.toDouble() ??
               (rawBbox?['norm_w'] as num?)?.toDouble();
    final nh = (norm?['height'] as num?)?.toDouble() ??
               (json['norm_h'] as num?)?.toDouble() ??
               (rawBbox?['norm_h'] as num?)?.toDouble();

    final x = (rawBbox?['x1'] ?? json['x']) as int? ?? 0;
    final y = (rawBbox?['y1'] ?? json['y']) as int? ?? 0;
    final w = (rawBbox?['width'] ?? json['width']) as int? ?? 40;
    final h = (rawBbox?['height'] ?? json['height']) as int? ?? 40;

    String rawCat = json['category'] as String? ?? json['label'] as String? ?? 'good';
    // Purge any legacy 'medium' to 'good' or 'undersized'
    if (rawCat.toLowerCase() == 'medium') {
      rawCat = 'good';
    }

    return DetectedBoundingBox(
      x: x,
      y: y,
      width: w,
      height: h,
      category: rawCat,
      confidence: (json['confidence'] as num?)?.toDouble() ?? 0.90,
      normX: nx,
      normY: ny,
      normW: nw,
      normH: nh,
    );
  }

  Map<String, dynamic> toJson() => {
    'x': x,
    'y': y,
    'width': width,
    'height': height,
    'category': category,
    'confidence': confidence,
    if (normX != null) 'norm_x': normX,
    if (normY != null) 'norm_y': normY,
    if (normW != null) 'norm_w': normW,
    if (normH != null) 'norm_h': normH,
  };
}

/// Strict 4-Class Quality System: Good, Defective, Sprouted, Undersized (URS).
/// 'Medium' has been completely removed across the entire platform.
class QualityAnalysisResult {
  final String batchId;
  final int totalDetected;
  final int good;
  final int defective;
  final int sprouted;
  final int undersized;
  final double goodPercentage;
  final double defectivePercentage;
  final double sproutedPercentage;
  final double undersizedPercentage;
  final String overallQuality;
  final List<String> observations;
  final List<DetectedBoundingBox> detectedItems;
  final DateTime analyzedAt;
  final String disclaimer;


  QualityAnalysisResult({
    required this.batchId,
    required this.totalDetected,
    required this.good,
    required this.defective,
    required this.sprouted,
    required this.undersized,
    required this.goodPercentage,
    required this.defectivePercentage,
    required this.sproutedPercentage,
    required this.undersizedPercentage,
    required this.overallQuality,
    required this.observations,
    this.detectedItems = const [],
    DateTime? analyzedAt,
    this.disclaimer = 'The image-processing system primarily evaluates externally visible onion quality characteristics from RGB images.',
  }) : analyzedAt = analyzedAt ?? DateTime.now();

  factory QualityAnalysisResult.fromJson(Map<String, dynamic> json) {
    // Read from counts map or top-level keys
    final counts = json['counts'] as Map<String, dynamic>?;
    final pcts = json['percentages'] as Map<String, dynamic>?;

    final goodCount = (counts?['good'] ?? json['good']) as int? ?? 0;
    final defCount = (counts?['defective'] ?? json['defective']) as int? ?? 0;
    final sprCount = (counts?['sprouted'] ?? json['sprouted']) as int? ?? 0;
    final ursCount = (counts?['undersized'] ?? json['undersized'] ?? counts?['urs'] ?? json['urs']) as int? ?? 0;

    final goodPct = (pcts?['good'] ?? json['good_percentage']) as num? ?? 0.0;
    final defPct = (pcts?['defective'] ?? json['defective_percentage']) as num? ?? 0.0;
    final sprPct = (pcts?['sprouted'] ?? json['sprouted_percentage']) as num? ?? 0.0;
    final ursPct = (pcts?['undersized'] ?? json['undersized_percentage'] ?? pcts?['urs'] ?? json['urs_percentage']) as num? ?? 0.0;

    String overall = 'Good';
    if (json['quality'] is Map) {
      overall = json['quality']['label'] as String? ?? 'Good';
    } else if (json['overall_quality'] != null) {
      overall = json['overall_quality'].toString();
    }
    // Purge 'Medium' from overall quality label
    if (overall.toLowerCase().contains('medium')) {
      overall = 'Commercial Grade';
    }

    return QualityAnalysisResult(
      batchId: json['batch_id'] as String? ?? 'BTH-UNKNOWN',
      totalDetected: (json['total_onions'] ?? json['total_detected']) as int? ?? 0,
      good: goodCount,
      defective: defCount,
      sprouted: sprCount,
      undersized: ursCount,
      goodPercentage: goodPct.toDouble(),
      defectivePercentage: defPct.toDouble(),
      sproutedPercentage: sprPct.toDouble(),
      undersizedPercentage: ursPct.toDouble(),
      overallQuality: overall,
      observations: (json['observations'] as List<dynamic>?)?.map((e) => e.toString()).toList() ?? [],
      detectedItems: (json['detections'] as List<dynamic>?)
              ?.map((e) => DetectedBoundingBox.fromJson(e as Map<String, dynamic>))
              .toList() ??
          (json['detected_items'] as List<dynamic>?)
              ?.map((e) => DetectedBoundingBox.fromJson(e as Map<String, dynamic>))
              .toList() ??
          [],
      disclaimer: json['disclaimer'] as String? ??
          'The image-processing system primarily evaluates externally visible onion quality characteristics from RGB images.',
    );
  }

  Map<String, dynamic> toJson() => {
    'batch_id': batchId,
    'total_detected': totalDetected,
    'good': good,
    'defective': defective,
    'sprouted': sprouted,
    'undersized': undersized,
    'good_percentage': goodPercentage,
    'defective_percentage': defectivePercentage,
    'sprouted_percentage': sproutedPercentage,
    'undersized_percentage': undersizedPercentage,
    'overall_quality': overallQuality,
    'observations': observations,
    'detected_items': detectedItems.map((e) => e.toJson()).toList(),
    'analyzed_at': analyzedAt.toIso8601String(),
    'disclaimer': disclaimer,
  };
}
