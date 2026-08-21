import 'package:flutter/material.dart';
import 'package:thinkspend/models/transaction_model.dart';
import 'package:thinkspend/services/privacy_service.dart';
import 'package:thinkspend/services/theme_service.dart';
import 'package:thinkspend/utils/currency_formatter.dart';

/// Widget kartu untuk menampilkan ringkasan satu item transaksi.
///
/// Menampilkan tipe (ikon panah masuk/keluar), judul, kategori, tanggal,
/// serta nominal Rupiah dengan warna hijau (income) / merah (expense).
class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
  });

  String _formatDate(String date) {
    if (date.length >= 10) {
      return date.substring(0, 10);
    }
    return date;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PrivacyService.instance,
      builder: (context, _) {
        final isIncome = transaction.type == 'income';
        final accentColor = isIncome ? AppColors.green : AppColors.red;

        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Material(
            color: AppColors.surface(context),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
              side: BorderSide(color: AppColors.border(context), width: 1),
            ),
            child: ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            onTap: onTap,
            leading: CircleAvatar(
              radius: 20,
              backgroundColor: accentColor.withValues(alpha: 0.12),
              child: Icon(
                isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                size: 18,
                color: accentColor,
              ),
            ),
            title: Text(
              transaction.title,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 15,
                color: AppColors.textPrimary(context),
              ),
            ),
            subtitle: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                '${transaction.category} • ${_formatDate(transaction.date)}',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ),
            trailing: Text(
              '${isIncome ? '+' : '-'} ${formatRupiah(transaction.amount)}',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: accentColor,
              ),
            ),
          ),
        ),
      );
      },
    );
  }
}
