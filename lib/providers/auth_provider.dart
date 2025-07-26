import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/supabase_config.dart';

final authProvider = Provider<AuthProvider>((ref) {
  return AuthProvider();
});

class AuthProvider {
  final _supabase = SupabaseConfig.client;

  Future<Map<String, dynamic>?> signInWithIdPassword({
    required String userId,
    required String password,
  }) async {
    // Query ke tabel users
    final response = await _supabase
        .from('users')
        .select()
        .eq('user_id', userId)
        .single();

    // Verifikasi password (dalam produksi, gunakan hash yang aman)
    if (response['password_hash'] != password) {
      throw Exception('ID atau password salah');
    }

    return response;
  }

  Future<void> signOut() async {
    // Karena kita tidak menggunakan auth Supabase, cukup clear state
  }

  Map<String, dynamic>? get currentUser {
    // Dalam implementasi nyata, Anda perlu menyimpan state user
    return null;
  }
}
