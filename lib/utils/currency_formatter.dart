String formatRupiah(double value) {
  final digits = value.round().toString();

  final formatted = digits.replaceAllMapped(
    RegExp(r'\B(?=(\d{3})+(?!\d))'),
    (match) => '.',
  );

  return 'Rp $formatted';
}