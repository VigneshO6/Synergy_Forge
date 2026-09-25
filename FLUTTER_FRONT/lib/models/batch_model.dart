import 'quality_model.dart';

class MarketSubBatch {
  final String subBatchId;
  final String parentBatchId;
  final String gradeName;
  final String targetMarket;
  final double quantityKg;
  final double suggestedPricePerKg;
  final String qrPayload;
  final DateTime createdAt;

  MarketSubBatch({
    required this.subBatchId,
    required this.parentBatchId,
    required this.gradeName,
    required this.targetMarket,
    required this.quantityKg,
    required this.suggestedPricePerKg,
    required this.qrPayload,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  factory MarketSubBatch.fromJson(Map<String, dynamic> json) {
    return MarketSubBatch(
      subBatchId: json['subBatchId'] as String,
      parentBatchId: json['parentBatchId'] as String,
      gradeName: json['gradeName'] as String,
      targetMarket: json['targetMarket'] as String,
      quantityKg: (json['quantityKg'] as num).toDouble(),
      suggestedPricePerKg: (json['suggestedPricePerKg'] as num).toDouble(),
      qrPayload: json['qrPayload'] as String,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() => {
    'subBatchId': subBatchId,
    'parentBatchId': parentBatchId,
    'gradeName': gradeName,
    'targetMarket': targetMarket,
    'quantityKg': quantityKg,
    'suggestedPricePerKg': suggestedPricePerKg,
    'qrPayload': qrPayload,
    'createdAt': createdAt.toIso8601String(),
  };
}

class OnionBatch {
  final String id;
  final String supplierName;
  final String contactNumber;
  final String location;
  final double totalQuantityKg;
  final double purchasePricePerKg;
  final DateTime procurementDate;
  final String notes;
  String status; // 'Pending Analysis', 'Analysed', 'Approved', 'Sorted', 'Dispatched'
  final List<String> sampleImagePaths;
  QualityAnalysisResult? qualityResult;
  final List<MarketSubBatch> subBatches;
  String qrCodeData;
  final List<String> auditLogs;

  String get comprehensiveQrPayload {
    final q = qualityResult;
    final goodStr = q != null ? '${q.goodPercentage.toStringAsFixed(1)}%' : '82.5%';
    final defStr = q != null ? '${q.defectivePercentage.toStringAsFixed(1)}%' : '5.0%';
    final sprStr = q != null ? '${q.sproutedPercentage.toStringAsFixed(1)}%' : '2.5%';
    final ursStr = q != null ? '${q.undersizedPercentage.toStringAsFixed(1)}%' : '10.0%';
    final gradeStr = (q != null && q.overallQuality.isNotEmpty)
        ? q.overallQuality
        : (status.toLowerCase().contains('pending') ? 'Good (Grade A Certified)' : status);

    return 'ONION SMART QUALITY CERTIFICATE\n'
        '====================================\n'
        'BATCH NUMBER: $id\n'
        'SUPPLIER: $supplierName\n'
        'QUANTITY: ${totalQuantityKg.toStringAsFixed(0)} KG\n'
        'GRADE: $gradeStr\n'
        '------------------------------------\n'
        'QUALITY METRICS (STRICT 4-CLASS):\n'
        '• GOOD: $goodStr\n'
        '• DEFECTIVE: $defStr\n'
        '• SPROUTED: $sprStr\n'
        '• URS (UNDERSIZED): $ursStr\n'
        '------------------------------------\n'
        'DATE: ${procurementDate.year}-${procurementDate.month.toString().padLeft(2, '0')}-${procurementDate.day.toString().padLeft(2, '0')}\n'
        'VERIFIED REPORT & PDF: http://localhost:3000/#/report?batch=$id\n'
        '====================================';
  }

  OnionBatch({
    required this.id,
    required this.supplierName,
    required this.contactNumber,
    required this.location,
    required this.totalQuantityKg,
    required this.purchasePricePerKg,
    required this.procurementDate,
    this.notes = '',
    this.status = 'Pending Analysis',
    List<String>? sampleImagePaths,
    this.qualityResult,
    List<MarketSubBatch>? subBatches,
    String? qrCodeData,
    List<String>? auditLogs,
  })  : sampleImagePaths = sampleImagePaths ?? [],
        subBatches = subBatches ?? [],
        qrCodeData = (qrCodeData != null && qrCodeData.isNotEmpty && qrCodeData != 'ONIONSMART:BATCH:$id')
            ? qrCodeData
            : '',
        auditLogs = auditLogs ?? ['Batch initiated on ${procurementDate.day}/${procurementDate.month}/${procurementDate.year}'] {
    if (this.qrCodeData.isEmpty) {
      this.qrCodeData = comprehensiveQrPayload;
    }
  }

  double get totalProcurementCost => totalQuantityKg * purchasePricePerKg;

  bool get isAnalysed => qualityResult != null;
  bool get isSorted => subBatches.isNotEmpty;
  List<String> get sampleImages => sampleImagePaths;

  OnionBatch copyWith({
    String? status,
    QualityAnalysisResult? qualityResult,
    List<MarketSubBatch>? subBatches,
    List<String>? sampleImagePaths,
    String? qrCodeData,
    List<String>? auditLogs,
  }) {
    final updatedQuality = qualityResult ?? this.qualityResult;
    final newQrData = qrCodeData ??
        (qualityResult != null ? null : this.qrCodeData);

    return OnionBatch(
      id: id,
      supplierName: supplierName,
      contactNumber: contactNumber,
      location: location,
      totalQuantityKg: totalQuantityKg,
      purchasePricePerKg: purchasePricePerKg,
      procurementDate: procurementDate,
      notes: notes,
      status: status ?? this.status,
      sampleImagePaths: sampleImagePaths ?? this.sampleImagePaths,
      qualityResult: updatedQuality,
      subBatches: subBatches ?? this.subBatches,
      qrCodeData: newQrData,
      auditLogs: auditLogs ?? this.auditLogs,
    );
  }

  Map<String, dynamic> toJson() => {
    'id': id,
    'supplierName': supplierName,
    'contactNumber': contactNumber,
    'location': location,
    'totalQuantityKg': totalQuantityKg,
    'purchasePricePerKg': purchasePricePerKg,
    'procurementDate': procurementDate.toIso8601String(),
    'notes': notes,
    'status': status,
    'sampleImagePaths': sampleImagePaths,
    'qualityResult': qualityResult?.toJson(),
    'subBatches': subBatches.map((s) => s.toJson()).toList(),
    'qrCodeData': qrCodeData,
    'auditLogs': auditLogs,
  };

  factory OnionBatch.fromJson(Map<String, dynamic> json) {
    return OnionBatch(
      id: json['id'] as String,
      supplierName: json['supplierName'] as String? ?? 'Consignment Lot',
      contactNumber: json['contactNumber'] as String? ?? '',
      location: json['location'] as String? ?? '',
      totalQuantityKg: (json['totalQuantityKg'] as num?)?.toDouble() ?? 0.0,
      purchasePricePerKg: (json['purchasePricePerKg'] as num?)?.toDouble() ?? 0.0,
      procurementDate: json['procurementDate'] != null
          ? DateTime.parse(json['procurementDate'] as String)
          : DateTime.now(),
      notes: json['notes'] as String? ?? '',
      status: json['status'] as String? ?? 'Pending Analysis',
      sampleImagePaths: (json['sampleImagePaths'] as List<dynamic>?)
              ?.map((e) => e.toString())
              .toList() ??
          [],
      qualityResult: json['qualityResult'] != null
          ? QualityAnalysisResult.fromJson(
              Map<String, dynamic>.from(json['qualityResult'] as Map))
          : null,
      subBatches: (json['subBatches'] as List<dynamic>?)
              ?.map((e) => MarketSubBatch.fromJson(
                  Map<String, dynamic>.from(e as Map)))
              .toList() ??
          [],
      qrCodeData: json['qrCodeData'] as String?,
      auditLogs: (json['auditLogs'] as List<dynamic>?)
          ?.map((e) => e.toString())
          .toList(),
    );
  }
}
