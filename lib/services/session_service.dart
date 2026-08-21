import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service singleton untuk mengelola persistent login session dan last page restore.
///
/// Komponen state yang disimpan:
/// 1. `is_logged_in` (bool) -> Menandakan user sedang memiliki sesi login aktif.
/// 2. `user_id` (int) -> Menyimpan ID pengguna untuk memulihkan profil lengkap dari SQLite.
/// 3. `last_page_index` (int) -> Menyimpan index navigasi terakhir (0: Beranda, 1: Transaksi, 2: Target, 3: AI, 4: Profil).
class SessionService {
  static final SessionService instance = SessionService._internal();

  SessionService._internal();

  static const String _keyIsLoggedIn = 'thinkspend_is_logged_in';
  static const String _keyUserId = 'thinkspend_user_id';
  static const String _keyLastPage = 'thinkspend_last_page_index';

  /// KENAPA SESSION DISIMPAN:
  /// Menyimpan status login dan user ID ke SharedPreferences agar ketika aplikasi
  /// ditutup, di-restart, atau mengalami force close, pengguna tidak perlu login ulang.
  Future<void> saveSession({required int userId, int lastPage = 0}) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyIsLoggedIn, true);
      await prefs.setInt(_keyUserId, userId);
      await prefs.setInt(_keyLastPage, lastPage);
    } catch (e) {
      debugPrint('Error saving session: $e');
    }
  }

  /// BAGAIMANA CURRENT INDEX DISIMPAN:
  /// Saat user berpindah NavigationBar, index tab disimpan secara lokal ke SharedPreferences
  /// secara asinkron dan ringan tanpa membebani query database SQLite berulang-ulang.
  Future<void> saveLastPage(int index) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(_keyLastPage, index);
    } catch (e) {
      debugPrint('Error saving last page index: $e');
    }
  }

  /// BAGAIMANA CURRENT INDEX DIPULIHKAN:
  /// Mengambil index tab terakhir yang disimpan. Jika belum ada atau di luar rentang tab
  /// (0..4), default nilai yang dikembalikan adalah 0 (Beranda).
  Future<int> getLastPage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final page = prefs.getInt(_keyLastPage) ?? 0;
      if (page < 0 || page > 4) {
        return 0;
      }
      return page;
    } catch (e) {
      debugPrint('Error getting last page index: $e');
      return 0;
    }
  }

  /// BAGAIMANA SESSION DIPULIHKAN:
  /// Mengecek apakah ada session login aktif dan mengembalikan `userId` pengguna.
  /// User ID ini kemudian divalidasi ke database SQLite sebelum membuka MainPage.
  Future<int?> getSessionUserId() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final isLoggedIn = prefs.getBool(_keyIsLoggedIn) ?? false;
      if (!isLoggedIn) {
        return null;
      }
      return prefs.getInt(_keyUserId);
    } catch (e) {
      debugPrint('Error getting session user id: $e');
      return null;
    }
  }

  /// Memeriksa apakah status session login tersimpan dan valid.
  Future<bool> isLoggedIn() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_keyIsLoggedIn) ?? false;
    } catch (e) {
      debugPrint('Error checking login status: $e');
      return false;
    }
  }

  /// BAGAIMANA LOGOUT MEMBERSIHKAN SESSION:
  /// Menghapus status login, user ID, serta me-reset last_page_index ke 0.
  /// Dengan pembersihan ini, aplikasi yang dibuka kembali akan tetap berada di LoginPage.
  Future<void> clearSession() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyIsLoggedIn);
      await prefs.remove(_keyUserId);
      await prefs.remove(_keyLastPage);
    } catch (e) {
      debugPrint('Error clearing session: $e');
    }
  }
}
