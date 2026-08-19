import 'package:flutter/material.dart';

/// Service singleton untuk mengelola status privasi tampilan nominal finansial di seluruh aplikasi.
/// Menggunakan ChangeNotifier sehingga seluruh widget yang mendengarkan perubahan state akan
/// me-rebuild tampilan secara instan tanpa query database, tanpa reload transaksi, dan tanpa
/// mengubah model/business logic.
class PrivacyService extends ChangeNotifier {
  static final PrivacyService instance = PrivacyService._internal();

  PrivacyService._internal();

  bool _isAmountVisible = true;

  /// Status apakah seluruh nominal uang ditampilkan secara normal atau disamarkan.
  bool get isAmountVisible => _isAmountVisible;

  /// Karakter penyamar standar untuk menyembunyikan nominal.
  static const String hiddenMask = '••••••••';

  /// Toggle status privasi nominal (tampil / sembunyikan).
  void toggleVisibility() {
    _isAmountVisible = !_isAmountVisible;
    notifyListeners();
  }

  /// Menampilkan seluruh nominal finansial.
  void showAmounts() {
    if (!_isAmountVisible) {
      _isAmountVisible = true;
      notifyListeners();
    }
  }

  /// Menyembunyikan seluruh nominal finansial.
  void hideAmounts() {
    if (_isAmountVisible) {
      _isAmountVisible = false;
      notifyListeners();
    }
  }

  /// Helper untuk menyamarkan teks format nominal jika privasi aktif.
  String mask(String formattedText) {
    return _isAmountVisible ? formattedText : hiddenMask;
  }
}
