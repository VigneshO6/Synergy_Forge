import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  // Configurable Supabase credentials
  // Replace these with your project's URL and anon key from Supabase Dashboard -> Settings -> API
  static String supabaseUrl = 'https://dwjvyiytbkmqjnvxplzo.supabase.co';
  static String supabaseAnonKey = 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImR3anZ5aXl0YmttcWpudnhwbHpvIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Mjc1NTg0MDAsImV4cCI6MjA0MzEzNDQwMH0.demo-placeholder-signature';

  static bool _initialized = false;
  static bool get isInitialized => _initialized;

  static bool get isConfigured =>
      supabaseUrl.startsWith('https://') &&
      !supabaseUrl.contains('xyzcompany') &&
      supabaseAnonKey.isNotEmpty &&
      !supabaseAnonKey.contains('demo-placeholder');

  static SupabaseClient? get client => _initialized ? Supabase.instance.client : null;

  static Future<void> initialize({String? customUrl, String? customAnonKey}) async {
    if (customUrl != null) supabaseUrl = customUrl;
    if (customAnonKey != null) supabaseAnonKey = customAnonKey;

    try {
      await Supabase.initialize(
        url: supabaseUrl,
        anonKey: supabaseAnonKey,
        debug: kDebugMode,
      );
      _initialized = true;
      debugPrint('Supabase initialized successfully ($supabaseUrl)');
    } catch (e) {
      debugPrint('Supabase initialization notice: $e (operating in local resilient mode)');
      _initialized = false;
    }
  }
}
