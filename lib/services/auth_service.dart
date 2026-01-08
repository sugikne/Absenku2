import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AuthService {
  final SupabaseClient supabase = Supabase.instance.client;

  /// 🔐 SIMPAN USER YANG SEDANG LOGIN
  static Map<String, dynamic>? currentUser;

  // ================== UTIL ==================
  String _hashPassword(String password) {
    final bytes = utf8.encode(password);
    return sha256.convert(bytes).toString();
  }

  // ================== REGISTER ==================
  Future<void> signUp({
    required String nama,
    required String nim,
    required String email,
    required String password,
  }) async {
    await supabase.from('users').insert({
      'nama': nama,
      'nim': nim,
      'email': email,
      'password_hash': _hashPassword(password),
    });
  }

  // ================== LOGIN ==================
  Future<bool> login({
    required String nama,
    required String password,
  }) async {
    final data = await supabase
        .from('users')
        .select()
        .eq('nama', nama)
        .eq('password_hash', _hashPassword(password))
        .maybeSingle();

    if (data == null) return false;

    currentUser = data;
    return true;
  }

  // ================== VERIFIKASI SESSION ==================

  /// ✅ Cek apakah user sudah login
  static bool isLoggedIn() {
    return currentUser != null;
  }

  /// 🆔 Ambil ID user (users.id)
  static String? get userId {
    return currentUser?['id']?.toString();
  }

  /// 👤 Nama user
  static String get nama {
    return currentUser?['nama'] ?? 'Mahasiswa';
  }

  /// 🎓 NIM user
  static String get nim {
    return currentUser?['nim'] ?? '-';
  }

  /// 📧 Email user
  static String get email {
    return currentUser?['email'] ?? '-';
  }

  // ================== LOGOUT ==================
  static void logout() {
    currentUser = null;
  }
}
