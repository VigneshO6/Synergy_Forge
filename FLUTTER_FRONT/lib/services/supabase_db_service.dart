import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../core/config/supabase_config.dart';
import '../models/batch_model.dart';
import '../models/quality_model.dart';

class SupabaseDbService {
  static SupabaseClient? get _client => SupabaseConfig.client;

  /// Ensures user profile exists in Supabase 'profiles' table
  static Future<void> upsertProfile({
    required String userId,
    required String email,
    required String fullName,
    required String role,
  }) async {
    final client = _client;
    if (client == null || !SupabaseConfig.isConfigured) return;

    try {
      await client.from('profiles').upsert({
        'id': userId,
        'email': email.trim().toLowerCase(),
        'full_name': fullName.trim(),
        'role': role,
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('Supabase profile saved for $email');
    } catch (e) {
      debugPrint('Supabase profile upsert error (local fallback active): $e');
    }
  }

  /// Syncs an OnionBatch into Supabase 'batches' table
  static Future<void> saveBatch(OnionBatch batch) async {
    final client = _client;
    if (client == null || !SupabaseConfig.isConfigured) return;

    try {
      await client.from('batches').upsert({
        'id': batch.id,
        'supplier_name': batch.supplierName,
        'contact_number': batch.contactNumber,
        'location': batch.location,
        'total_quantity_kg': batch.totalQuantityKg,
        'purchase_price_per_kg': batch.purchasePricePerKg,
        'procurement_date': batch.procurementDate.toIso8601String(),
        'status': batch.status,
        'notes': batch.notes,
        'qr_code_data': batch.qrCodeData,
        'updated_at': DateTime.now().toIso8601String(),
      });
      debugPrint('Supabase batch saved: ${batch.id}');
    } catch (e) {
      debugPrint('Supabase batch save notice: $e');
    }
  }

  /// Stores quality inspection results into Supabase 'quality_reports' table
  static Future<void> saveQualityReport({
    required String batchId,
    required QualityAnalysisResult result,
  }) async {
    final client = _client;
    if (client == null || !SupabaseConfig.isConfigured) return;

    try {
      await client.from('quality_reports').upsert({
        'batch_id': batchId,
        'total_detected': result.totalDetected,
        'good_count': result.good,
        'defective_count': result.defective,
        'sprouted_count': result.sprouted,
        'urs_count': result.undersized,
        'good_percentage': result.goodPercentage,
        'defective_percentage': result.defectivePercentage,
        'sprouted_percentage': result.sproutedPercentage,
        'urs_percentage': result.undersizedPercentage,
        'overall_quality': result.overallQuality,
        'observations': result.observations,
        'analyzed_at': result.analyzedAt.toIso8601String(),
      });
      debugPrint('Supabase quality report saved for $batchId');
    } catch (e) {
      debugPrint('Supabase quality report save notice: $e');
    }
  }

  /// Fetches batches from Supabase 'batches' table
  static Future<List<Map<String, dynamic>>?> fetchBatches() async {
    final client = _client;
    if (client == null || !SupabaseConfig.isConfigured) return null;

    try {
      final res = await client.from('batches').select().order('procurement_date', ascending: false);
      return List<Map<String, dynamic>>.from(res);
    } catch (e) {
      debugPrint('Supabase fetch batches error: $e');
      return null;
    }
  }
}
