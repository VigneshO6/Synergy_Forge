import 'package:flutter/material.dart';
import '../models/batch_model.dart';
import '../models/quality_model.dart';
import '../services/batch_repository.dart';
import '../services/supabase_db_service.dart';

class BatchProvider extends ChangeNotifier {
  final BatchRepository _repository = BatchRepository();

  String _filterStatus = 'All';
  OnionBatch? _selectedBatch;
  bool _isLoading = false;

  BatchProvider() {
    _initBatches();
  }

  bool get isLoading => _isLoading;
  String get filterStatus => _filterStatus;
  OnionBatch? get selectedBatch => _selectedBatch;

  List<OnionBatch> get allBatches => _repository.getAllBatches();

  List<OnionBatch> get filteredBatches {
    final all = allBatches;
    if (_filterStatus == 'All') return all;
    return all.where((b) => b.status.toLowerCase() == _filterStatus.toLowerCase()).toList();
  }

  // Dashboard Aggregates
  int get totalBatchesCount => allBatches.length;
  int get analysedCount => allBatches.where((b) => b.isAnalysed).length;
  int get pendingCount => allBatches.where((b) => b.status == 'Pending Analysis').length;
  int get approvedCount => allBatches.where((b) => b.status == 'Approved' || b.status == 'Sorted').length;

  double get averageGoodQuality {
    final analysed = allBatches.where((b) => b.qualityResult != null).toList();
    if (analysed.isEmpty) return 0.0;
    final sum = analysed.fold(0.0, (acc, b) => acc + (b.qualityResult?.goodPercentage ?? 0.0));
    return double.parse((sum / analysed.length).toStringAsFixed(1));
  }

  double get averageDefectiveQuality {
    final analysed = allBatches.where((b) => b.qualityResult != null).toList();
    if (analysed.isEmpty) return 0.0;
    final sum = analysed.fold(0.0, (acc, b) => acc + (b.qualityResult?.defectivePercentage ?? 0.0));
    return double.parse((sum / analysed.length).toStringAsFixed(1));
  }

  double get averageSproutedQuality {
    final analysed = allBatches.where((b) => b.qualityResult != null).toList();
    if (analysed.isEmpty) return 0.0;
    final sum = analysed.fold(0.0, (acc, b) => acc + (b.qualityResult?.sproutedPercentage ?? 0.0));
    return double.parse((sum / analysed.length).toStringAsFixed(1));
  }

  double get averageUrsQuality {
    final analysed = allBatches.where((b) => b.qualityResult != null).toList();
    if (analysed.isEmpty) return 0.0;
    final sum = analysed.fold(0.0, (acc, b) => acc + (b.qualityResult?.undersizedPercentage ?? 0.0));
    return double.parse((sum / analysed.length).toStringAsFixed(1));
  }

  Future<void> _initBatches() async {
    _isLoading = true;
    notifyListeners();
    await _repository.loadFromStorage();
    _isLoading = false;
    notifyListeners();
    // Non-blocking attempt to load live records from Supabase if configured
    refreshFromCloud();
  }

  Future<void> refreshFromCloud() async {
    try {
      final cloudBatches = await SupabaseDbService.fetchBatches();
      if (cloudBatches != null && cloudBatches.isNotEmpty) {
        for (final m in cloudBatches) {
          final id = m['id'] as String? ?? '';
          if (id.isEmpty || id.contains('0098') || id.contains('0099') || id.contains('0100') || id.contains('0101')) {
            continue;
          }
          final dateStr = m['procurement_date'] as String? ?? DateTime.now().toIso8601String();
          final b = OnionBatch(
            id: id,
            supplierName: m['supplier_name'] as String? ?? 'Consignment',
            contactNumber: m['contact_number'] as String? ?? '',
            location: m['location'] as String? ?? '',
            totalQuantityKg: (m['total_quantity_kg'] as num?)?.toDouble() ?? 0.0,
            purchasePricePerKg: (m['purchase_price_per_kg'] as num?)?.toDouble() ?? 0.0,
            procurementDate: DateTime.tryParse(dateStr) ?? DateTime.now(),
            status: m['status'] as String? ?? 'Pending Analysis',
            notes: m['notes'] as String? ?? '',
            qrCodeData: m['qr_code_data'] as String?,
          );
          _repository.addBatch(b);
        }
        notifyListeners();
      }
    } catch (e) {
      debugPrint('Cloud batch sync notice: $e');
    }
  }

  void setFilter(String filter) {
    _filterStatus = filter;
    notifyListeners();
  }

  void selectBatch(OnionBatch batch) {
    _selectedBatch = batch;
    notifyListeners();
  }

  void selectBatchById(String id) {
    _selectedBatch = _repository.getBatchById(id);
    notifyListeners();
  }

  OnionBatch createNewBatch({
    required String supplierName,
    required String contactNumber,
    required String location,
    required double totalQuantityKg,
    required double purchasePricePerKg,
    required DateTime procurementDate,
    required String notes,
  }) {
    final batchId = _repository.generateNextBatchId();

    final newBatch = OnionBatch(
      id: batchId,
      supplierName: supplierName,
      contactNumber: contactNumber,
      location: location,
      totalQuantityKg: totalQuantityKg,
      purchasePricePerKg: purchasePricePerKg,
      procurementDate: procurementDate,
      notes: notes,
      status: 'Pending Analysis',
      sampleImagePaths: [],
      qrCodeData: 'ONIONSMART:BATCH:$batchId',
    );

    _repository.addBatch(newBatch);
    _selectedBatch = newBatch;
    notifyListeners();

    // Async sync to Supabase database
    SupabaseDbService.saveBatch(newBatch);

    return newBatch;
  }

  void addBatch(OnionBatch batch) {
    _repository.addBatch(batch);
    _selectedBatch = batch;
    notifyListeners();
    SupabaseDbService.saveBatch(batch);
  }

  void attachQualityResult(String batchId, QualityAnalysisResult result, List<String> samplePaths) {
    _repository.updateQualityResult(batchId, result, samplePaths);
    _selectedBatch = _repository.getBatchById(batchId);
    notifyListeners();
    if (_selectedBatch != null) {
      SupabaseDbService.saveBatch(_selectedBatch!);
      SupabaseDbService.saveQualityReport(batchId: batchId, result: result);
    }
  }

  void approveBatch(String batchId) {
    _repository.updateStatus(batchId, 'Approved');
    _selectedBatch = _repository.getBatchById(batchId);
    notifyListeners();
    if (_selectedBatch != null) {
      SupabaseDbService.saveBatch(_selectedBatch!);
    }
  }

  void createSortedSubBatches({
    required String batchId,
    required double gradeAQty,
    required double gradeBQty,
    required double gradeCQty,
    required double gradeAPrice,
    required double gradeBPrice,
    required double gradeCPrice,
  }) {
    final subBatches = [
      MarketSubBatch(
        subBatchId: '$batchId-EXP',
        parentBatchId: batchId,
        gradeName: 'Grade A Premium Export',
        targetMarket: 'Middle East / Southeast Asia Export',
        quantityKg: gradeAQty,
        suggestedPricePerKg: gradeAPrice,
        qrPayload: 'ONIONSMART:SUBBATCH:$batchId-EXP:GRADE_A:${gradeAQty}KG',
      ),
      MarketSubBatch(
        subBatchId: '$batchId-DOM',
        parentBatchId: batchId,
        gradeName: 'Grade B Domestic Retail Mandi',
        targetMarket: 'Metro Wholesale APMC Mandis',
        quantityKg: gradeBQty,
        suggestedPricePerKg: gradeBPrice,
        qrPayload: 'ONIONSMART:SUBBATCH:$batchId-DOM:GRADE_B:${gradeBQty}KG',
      ),
      MarketSubBatch(
        subBatchId: '$batchId-PRC',
        parentBatchId: batchId,
        gradeName: 'Grade C Food Processing / Flakes',
        targetMarket: 'Dehydration & Powder Manufacturing Plant',
        quantityKg: gradeCQty,
        suggestedPricePerKg: gradeCPrice,
        qrPayload: 'ONIONSMART:SUBBATCH:$batchId-PRC:GRADE_C:${gradeCQty}KG',
      ),
    ];

    _repository.setSubBatches(batchId, subBatches);
    _selectedBatch = _repository.getBatchById(batchId);
    notifyListeners();
    if (_selectedBatch != null) {
      SupabaseDbService.saveBatch(_selectedBatch!);
    }
  }

  void deleteBatch(String batchId) {
    _repository.deleteBatch(batchId);
    if (_selectedBatch?.id.toUpperCase() == batchId.toUpperCase()) {
      _selectedBatch = null;
    }
    notifyListeners();
  }

  void clearAllBatches() {
    _repository.clearAllBatches();
    _selectedBatch = null;
    notifyListeners();
  }
}
