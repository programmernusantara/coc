import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseConfig {
  static const String url = 'https://khmoryszrwvosuhubasz.supabase.co';
  static const String anonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImtobW9yeXN6cnd2b3N1aHViYXN6Iiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDk4MDMzMjcsImV4cCI6MjA2NTM3OTMyN30.NdAzfYRY3PSLjj7EJOH0BjbXUum9ZCp29kVnbYHgscs';

  static Future<void> initialize() async {
    await Supabase.initialize(url: url, anonKey: anonKey);
  }

  static SupabaseClient get client => Supabase.instance.client;
}
