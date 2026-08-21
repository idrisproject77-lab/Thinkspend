import 'package:thinkspend/services/privacy_service.dart';

/// Memformat nilai numerik ke representasi mata uang Rupiah standar (contoh: "Rp 50.000").
///
/// Terintegrasi dengan [PrivacyService] untuk menyamarkan nominal (menjadi "••••••••")
/// jika mode privasi diaktifkan oleh pengguna.
String formatRupiah(double value, {bool? isVisible}) {
  final visible = isVisible ?? PrivacyService.instance.isAmountVisible;
  if (!visible) {
    return PrivacyService.hiddenMask;
  }

  final digits = value.round().toString();

  final formatted = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );

  return 'Rp $formatted';
}