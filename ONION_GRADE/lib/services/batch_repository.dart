import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/batch_model.dart';
import '../models/quality_model.dart';

class BatchRepository {
  static const String _storageKey = 'onion_smart_procurement_batches_v2';
  static const Set<String> _legacyDemoIds = {
    'BTH-2026-0098',
    'BTH-2026-0099',
    'BTH-2026-0100',
    'BTH-2026-0101',
  };

  final List<OnionBatch> _batches = [];
  bool _isLoaded = false;

  BatchRepository() {
    loadFromStorage();
  }

  bool get isLoaded => _isLoaded;

  Future<void> loadFromStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_storageKey);
      _batches.clear();

      if (raw != null && raw.isNotEmpty) {
        final List<dynamic> list = jsonDecode(raw);
        for (final item in list) {
          if (item is Map<String, dynamic>) {
            final batch = OnionBatch.fromJson(item);
            // Purge previous dummy demo batches
            if (!_legacyDemoIds.contains(batch.id.toUpperCase())) {
              _batches.add(batch);
            }
          }
        }
      }
      _isLoaded = true;
    } catch (e) {
      debugPrint('Notice loading saved batches: $e');
      _batches.clear();
      _isLoaded = true;
    }
  }

  Future<void> persistToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final list = _batches.map((b) => b.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(list));
    } catch (e) {
      debugPrint('Notice persisting batches to storage: $e');
    }
  }

  List<OnionBatch> getAllBatches() => List.unmodifiable(_batches);

  OnionBatch? getBatchById(String id) {
    try {
      return _batches.firstWhere((b) => b.id.toUpperCase() == id.toUpperCase());
    } catch (_) {
      return null;
    }
  }

  String generateNextBatchId() {
    final year = DateTime.now().year;
    int maxNum = 0;
    final prefix = 'BTH-$year-';

    for (final b in _batches) {
      if (b.id.startsWith(prefix)) {
        final numPart = b.id.substring(prefix.length);
        final val = int.tryParse(numPart);
        if (val != null && val > maxNum) {
          maxNum = val;
        }
      }
    }

    final nextNum = maxNum + 1;
    return '$prefix${nextNum.toString().padLeft(4, '0')}';
  }

  void addBatch(OnionBatch batch) {
    _batches.removeWhere((b) => b.id.toUpperCase() == batch.id.toUpperCase());
    _batches.insert(0, batch);
    persistToStorage();
  }

  void updateQualityResult(String batchId, QualityAnalysisResult result, List<String> samplePaths) {
    final index = _batches.indexWhere((b) => b.id.toUpperCase() == batchId.toUpperCase());
    if (index != -1) {
      final old = _batches[index];
      final updatedLogs = List<String>.from(old.auditLogs)
        ..add('CV Quality Analysis performed: ${result.overallQuality} (${result.goodPercentage}% Good)');

      _batches[index] = old.copyWith(
        status: 'Analysed',
        qualityResult: result,
        sampleImagePaths: samplePaths,
        auditLogs: updatedLogs,
      );
      persistToStorage();
    }
  }

  void updateStatus(String batchId, String newStatus) {
    final index = _batches.indexWhere((b) => b.id.toUpperCase() == batchId.toUpperCase());
    if (index != -1) {
      final old = _batches[index];
      final updatedLogs = List<String>.from(old.auditLogs)
        ..add('Status transitioned to $newStatus on ${DateTime.now().toLocal().toString().split('.')[0]}');

      _batches[index] = old.copyWith(
        status: newStatus,
        auditLogs: updatedLogs,
      );
      persistToStorage();
    }
  }

  void setSubBatches(String batchId, List<MarketSubBatch> subBatches) {
    final index = _batches.indexWhere((b) => b.id.toUpperCase() == batchId.toUpperCase());
    if (index != -1) {
      final old = _batches[index];
      final updatedLogs = List<String>.from(old.auditLogs)
        ..add('Batch partitioned into ${subBatches.length} Market Sub-batches for distribution.');

      _batches[index] = old.copyWith(
        status: 'Sorted',
        subBatches: subBatches,
        auditLogs: updatedLogs,
      );
      persistToStorage();
    }
  }

  void deleteBatch(String batchId) {
    _batches.removeWhere((b) => b.id.toUpperCase() == batchId.toUpperCase());
    persistToStorage();
  }

  void clearAllBatches() {
    _batches.clear();
    persistToStorage();
  }
}
