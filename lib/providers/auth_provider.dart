import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_config.dart';

final authProvider = Provider<AuthProvider>((ref) {
  return AuthProvider();
});

class AuthProvider {
  final _supabase = SupabaseConfig.client;

  Future<Map<String, dynamic>> signInWithIdPassword({
    required String userId,
    required String password,
  }) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('user_id', userId)
          .maybeSingle();

      if (response == null) {
        throw Exception('User tidak ditemukan');
      }

      if (response['password_hash'] != password) {
        throw Exception('ID atau password salah');
      }

      return response;
    } catch (e) {
      throw Exception('Terjadi kesalahan: ${e.toString()}');
    }
  }

  Future<void> signOut() async {
    // Implementasi logout jika diperlukan
  }

  Future<Map<String, dynamic>?> getCurrentUser(String userId) async {
    try {
      final response = await _supabase
          .from('users')
          .select()
          .eq('user_id', userId)
          .maybeSingle();
      return response;
    } catch (e) {
      return null;
    }
  }
}
