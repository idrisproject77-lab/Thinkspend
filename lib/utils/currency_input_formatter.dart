import 'package:flutter/services.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    // Hapus semua titik yang sudah ada.
    final rawText =
        newValue.text.replaceAll('.', '');

    // Kalau kosong, biarkan kosong.
    if (rawText.isEmpty) {
      return const TextEditingValue(
        text: '',
        selection: TextSelection.collapsed(
          offset: 0,
        ),
      );
    }

    // Pastikan hanya angka.
    final digitsOnly =
        rawText.replaceAll(RegExp(r'[^0-9]'), '');

    if (digitsOnly.isEmpty) {
      return oldValue;
    }

    // Format ribuan menggunakan titik.
    final formatted =
        digitsOnly.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    // Hitung posisi cursor berdasarkan
    // jumlah angka sebelum cursor.
    final digitsBeforeCursor =
        newValue.text
            .substring(
              0,
              newValue.selection.baseOffset
                  .clamp(
                    0,
                    newValue.text.length,
                  ),
            )
            .replaceAll('.', '')
            .replaceAll(
              RegExp(r'[^0-9]'),
              '',
            )
            .length;

    var cursorPosition = 0;
    var digitCount = 0;

    for (int i = 0; i < formatted.length; i++) {
      if (RegExp(r'[0-9]').hasMatch(
        formatted[i],
      )) {
        digitCount++;
      }

      cursorPosition++;

      if (digitCount >= digitsBeforeCursor) {
        break;
      }
    }

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(
        offset: cursorPosition,
      ),
    );
  }
}