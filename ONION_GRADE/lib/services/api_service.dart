import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../core/config/supabase_config.dart';
import '../models/prediction.dart';

class ApiService {
  // Configurable base URL: Use 127.0.0.1 for desktop/web, or your Windows PC's IPv4 (e.g. 192.168.X.X:8000) for Android phones
  static String baseUrl = 'http://127.0.0.1:8000';

  static void setBaseUrl(String url) {
    baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
  }

  /// Checks if the backend server is reachable and deep learning models are loaded
  static Future<Map<String, dynamic>> checkHealth({String? customUrl}) async {
    final host = customUrl ?? baseUrl;
    final uri = Uri.parse('$host/health');
    try {
      final res = await http.get(uri).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return {'status': 'error', 'statusCode': res.statusCode};
    } catch (e) {
      return {'status': 'offline', 'error': e.toString()};
    }
  }

  /// Checks Supabase authentication status with backend
  static Future<Map<String, dynamic>> checkAuthStatus({String? customUrl}) async {
    final host = customUrl ?? baseUrl;
    final uri = Uri.parse('$host/api/auth/status');
    try {
      final token = SupabaseConfig.client?.auth.currentSession?.accessToken;
      final headers = <String, String>{};
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
      final res = await http.get(uri, headers: headers).timeout(const Duration(seconds: 4));
      if (res.statusCode == 200) {
        return jsonDecode(res.body) as Map<String, dynamic>;
      }
      return {'status': 'error', 'statusCode': res.statusCode};
    } catch (e) {
      return {'status': 'offline', 'error': e.toString()};
    }
  }

  /// Sends the captured/uploaded onion image as multipart/form-data to POST /api/analysis/analyze
  static Future<AnalysisApiResponse> analyzeOnionImage({
    required Uint8List imageBytes,
    required String filename,
    String batchId = 'BTH-LIVE',
    String? customUrl,
  }) async {
    final host = customUrl ?? baseUrl;
    final uri = Uri.parse('$host/api/analysis/analyze');

    final request = http.MultipartRequest('POST', uri);
    request.fields['batch_id'] = batchId;

    // Attach Supabase bearer token if session exists
    final token = SupabaseConfig.client?.auth.currentSession?.accessToken;
    if (token != null && token.isNotEmpty) {
      request.headers['Authorization'] = 'Bearer $token';
    }

    // Attach image as multipart file
    request.files.add(
      http.MultipartFile.fromBytes(
        'file',
        imageBytes,
        filename: filename.isNotEmpty ? filename : 'onion_sample.jpg',
      ),
    );

    try {
      final streamedResponse = await request.send().timeout(const Duration(seconds: 25));
      final responseBody = await streamedResponse.stream.bytesToString();

      if (streamedResponse.statusCode == 200) {
        final data = jsonDecode(responseBody) as Map<String, dynamic>;
        return AnalysisApiResponse.fromJson(data);
      } else {
        String errorMsg = 'Server returned HTTP ${streamedResponse.statusCode}';
        try {
          final errJson = jsonDecode(responseBody);
          if (errJson is Map && errJson.containsKey('detail')) {
            errorMsg = errJson['detail'].toString();
          }
        } catch (_) {}
        throw Exception(errorMsg);
      }
    } catch (e) {
      debugPrint('Error calling /api/analysis/analyze: $e');
      rethrow;
    }
  }
}
