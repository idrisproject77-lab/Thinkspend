import 'package:thinkspend/services/privacy_service.dart';

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