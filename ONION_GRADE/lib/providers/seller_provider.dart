import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../models/batch_model.dart';
import '../models/quality_model.dart';
import '../models/profit_model.dart';
import '../models/sample_image_item.dart';

class SellerProvider extends ChangeNotifier {
  OnionBatch? _verifiedBatch;
  String _scannedBatchId = '';
  final ImagePicker _picker = ImagePicker();

  final List<SampleImageItem> _receivedSampleItems = [];

  bool _isAnalyzing = false;
  String _analysisProgressMessage = '';
  double _analysisProgress = 0.0;
  QualityAnalysisResult? _receivedQualityResult;
  TransitComparison? _transitComparison;

  // Market Price & Cost Inputs
  double _sellingPricePerKg = 42.0;
  double _transportCostPerKg = 2.5;
  double _storageCostPerKg = 1.0;
  double _wasteMarginPct = 3.5;

  // Transaction history
  final List<Map<String, dynamic>> _settledTransactions = [];

  OnionBatch? get verifiedBatch => _verifiedBatch;
  String get scannedBatchId => _scannedBatchId;
  List<SampleImageItem> get receivedSampleItems => List.unmodifiable(_receivedSampleItems);
  List<String> get receivedSampleImages => _receivedSampleItems.map((e) => e.assetPath ?? e.name).toList();
  bool get isAnalyzing => _isAnalyzing;
  String get analysisProgressMessage => _analysisProgressMessage;
  double get analysisProgress => _analysisProgress;
  QualityAnalysisResult? get receivedQualityResult => _receivedQualityResult;
  TransitComparison? get transitComparison => _transitComparison;

  double get sellingPricePerKg => _sellingPricePerKg;
  double get transportCostPerKg => _transportCostPerKg;
  double get storageCostPerKg => _storageCostPerKg;
  double get wasteMarginPct => _wasteMarginPct;
  List<Map<String, dynamic>> get settledTransactions => List.unmodifiable(_settledTransactions);

  ProfitCalculation get profitCalculation {
    final qty = _verifiedBatch?.totalQuantityKg ?? 5000.0;
    final purchasePrice = _verifiedBatch?.purchasePricePerKg ?? 32.0;

    return ProfitCalculation(
      batchQuantityKg: qty,
      purchasePricePerKg: purchasePrice,
      sellingPricePerKg: _sellingPricePerKg,
      transportCostPerKg: _transportCostPerKg,
      storageCostPerKg: _storageCostPerKg,
      wasteDeductionPct: _wasteMarginPct,
    );
  }

  void setScannedBatchId(String batchId) {
    _scannedBatchId = batchId.trim();
    notifyListeners();
  }

  void setVerifiedBatch(OnionBatch? batch) {
    _verifiedBatch = batch;
    _receivedQualityResult = null;
    _transitComparison = null;
    if (batch != null) {
      _scannedBatchId = batch.id;
      _sellingPricePerKg = batch.purchasePricePerKg + 10.0;
    }
    notifyListeners();
  }

  // Camera Access for Seller
  Future<bool> captureArrivalWithCamera() async {
    try {
      final XFile? photo = await _picker.pickImage(
        source: ImageSource.camera,
        preferredCameraDevice: CameraDevice.rear,
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );

      if (photo != null) {
        final bytes = await photo.readAsBytes();
        _receivedSampleItems.add(
          SampleImageItem(
            id: 'sel-cam-${DateTime.now().millisecondsSinceEpoch}',
            bytes: bytes,
            name: photo.name.isNotEmpty ? photo.name : 'Mandi_Camera_${_receivedSampleItems.length + 1}.jpg',
          ),
        );
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Seller camera capture error: $e');
    }
    return false;
  }

  // Gallery Picker for Seller
  Future<bool> pickArrivalFromGallery() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1600,
        maxHeight: 1600,
        imageQuality: 90,
      );

      if (images.isNotEmpty) {
        for (final img in images) {
          final bytes = await img.readAsBytes();
          _receivedSampleItems.add(
            SampleImageItem(
              id: 'sel-gal-${DateTime.now().millisecondsSinceEpoch}-${img.name}',
              bytes: bytes,
              name: img.name,
            ),
          );
        }
        notifyListeners();
        return true;
      }
    } catch (e) {
      debugPrint('Seller gallery picker error: $e');
    }
    return false;
  }

  void addReceivedSampleAsset(String path, String name) {
    _receivedSampleItems.add(
      SampleImageItem(
        id: 'sel-asset-${DateTime.now().millisecondsSinceEpoch}',
        assetPath: path,
        name: name,
      ),
    );
    notifyListeners();
  }

  void addReceivedAssetSample(String path, String name) {
    addReceivedSampleAsset(path, name);
  }

  void clearReceivedSamples() {
    _receivedSampleItems.clear();
    notifyListeners();
  }

  void removeReceivedSample(int index) {
    if (index >= 0 && index < _receivedSampleItems.length) {
      _receivedSampleItems.removeAt(index);
      notifyListeners();
    }
  }

  void updatePricing({
    double? sellingPrice,
    double? transportCost,
    double? storageCost,
    double? wasteMargin,
  }) {
    if (sellingPrice != null) _sellingPricePerKg = sellingPrice;
    if (transportCost != null) _transportCostPerKg = transportCost;
    if (storageCost != null) _storageCostPerKg = storageCost;
    if (wasteMargin != null) _wasteMarginPct = wasteMargin;
    notifyListeners();
  }

  Future<void> runSellerVerificationAnalysis() async {
    if (_verifiedBatch == null) return;

    _isAnalyzing = true;
    _analysisProgress = 0.10;
    _analysisProgressMessage = 'Scanning market received onion samples...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));
    _analysisProgress = 0.40;
    _analysisProgressMessage = 'Evaluating transit skin condition & sprout growth...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 700));
    _analysisProgress = 0.75;
    _analysisProgressMessage = 'Detecting surface blemish variations vs origin report...';
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 600));
    _analysisProgress = 1.0;
    _analysisProgressMessage = 'Comparison analysis complete.';

    final original = _verifiedBatch!.qualityResult ??
        QualityAnalysisResult(
          batchId: _verifiedBatch!.id,
          totalDetected: 30,
          good: 25,
          defective: 2,
          sprouted: 1,
          undersized: 2,
          goodPercentage: 83.3,
          defectivePercentage: 6.7,
          sproutedPercentage: 3.3,
          undersizedPercentage: 6.7,
          overallQuality: 'Good (Grade A)',
          observations: ['Baseline origin quality certificate.'],
        );

    final int total = 30;
    final int good = (original.good - 2).clamp(5, 30);
    final int sprouted = original.sprouted + 1;
    final int defective = original.defective + 1;
    final int undersized = (total - (good + sprouted + defective)).clamp(0, 10);

    final receivedResult = QualityAnalysisResult(
      batchId: _verifiedBatch!.id,
      totalDetected: total,
      good: good,
      defective: defective,
      sprouted: sprouted,
      undersized: undersized,
      goodPercentage: double.parse(((good / total) * 100).toStringAsFixed(1)),
      defectivePercentage: double.parse(((defective / total) * 100).toStringAsFixed(1)),
      sproutedPercentage: double.parse(((sprouted / total) * 100).toStringAsFixed(1)),
      undersizedPercentage: double.parse(((undersized / total) * 100).toStringAsFixed(1)),
      overallQuality: good / total >= 0.70 ? 'Good (Grade A)' : 'Commercial Grade',
      observations: [
        'Minor transit impact observed: +3.3% sprouting emergence at neck.',
        'Surface tunic remains largely intact with acceptable moisture balance.',
        'Defect tolerance remains within wholesale APMC standard limits.',
      ],
      analyzedAt: DateTime.now(),
    );

    _receivedQualityResult = receivedResult;
    _transitComparison = TransitComparison(
      originalQuality: original,
      receivedQuality: receivedResult,
      weightLossPct: 1.6,
    );

    _isAnalyzing = false;
    notifyListeners();
  }

  void recordTransaction() {
    if (_verifiedBatch == null) return;
    final calc = profitCalculation;

    _settledTransactions.insert(0, {
      'txId': 'TX-2026-${DateTime.now().millisecondsSinceEpoch.toString().substring(7)}',
      'batchId': _verifiedBatch!.id,
      'grade': _verifiedBatch!.qualityResult?.overallQuality ?? 'Grade A',
      'quantityKg': _verifiedBatch!.totalQuantityKg,
      'sellingPrice': _sellingPricePerKg,
      'netProfit': calc.netProfit,
      'date': 'Today',
      'buyer': 'Direct Mandi Consignment',
    });
    notifyListeners();
  }
}
