import 'package:flutter/material.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/transaction_model.dart';
import 'package:thinkspend/services/privacy_service.dart';
import 'package:thinkspend/services/theme_service.dart';
import 'package:thinkspend/utils/currency_formatter.dart';
import 'edit_transaction_page.dart';

/// Halaman rincian lengkap transaksi.
///
/// Menampilkan tipe, judul, kategori, tanggal, catatan detail, dan nominal
/// yang reaktif terhadap sensor privasi ([PrivacyService]), serta tombol Edit dan Hapus.
class TransactionDetailPage extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  // ============================================================
  // DATE FORMATTER HELPER
  // ============================================================

  String _formatDisplayDate(String dateStr) {
    try {
      final date = DateTime.parse(dateStr);
      const months = [
        'Januari',
        'Februari',
        'Maret',
        'April',
        'Mei',
        'Juni',
        'Juli',
        'Agustus',
        'September',
        'Oktober',
        'November',
        'Desember',
      ];
      return '${date.day} ${months[date.month - 1]} ${date.year}';
    } catch (_) {
      if (dateStr.length >= 10) {
        return dateStr.substring(0, 10);
      }
      return dateStr;
    }
  }

  // ============================================================
  // CATEGORY ICON HELPER
  // ============================================================

  IconData _getCategoryIcon(String category, bool isIncome) {
    if (isIncome) {
      return Icons.account_balance_wallet_outlined;
    }

    switch (category.trim().toLowerCase()) {
      case 'food':
      case 'makanan':
      case 'kuliner':
        return Icons.restaurant_outlined;
      case 'transport':
      case 'transportasi':
      case 'kendaraan':
        return Icons.directions_car_outlined;
      case 'shopping':
      case 'belanja':
        return Icons.shopping_bag_outlined;
      case 'bills':
      case 'tagihan':
      case 'listrik':
      case 'air':
        return Icons.receipt_outlined;
      case 'entertainment':
      case 'hiburan':
        return Icons.movie_outlined;
      default:
        return Icons.category_outlined;
    }
  }

  // ============================================================
  // EDIT TRANSACTION HANDLER
  // ============================================================

  Future<void> _handleEdit(BuildContext context) async {
    final result = await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => EditTransactionPage(transaction: transaction),
      ),
    );

    if (result == true && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  // ============================================================
  // DELETE TRANSACTION HANDLER
  // ============================================================

  Future<void> _handleDelete(BuildContext context) async {
    if (transaction.id == null) {
      return;
    }

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          backgroundColor: AppColors.surface(context),
          title: Text(
            'Hapus Transaksi?',
            style: TextStyle(
              color: AppColors.textPrimary(context),
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Transaksi ini akan dihapus secara permanen.',
            style: TextStyle(
              color: AppColors.textSecondary(context),
              fontSize: 14,
            ),
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },
              child: Text(
                'Batal',
                style: TextStyle(color: AppColors.textSecondary(context)),
              ),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.red,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              onPressed: () {
                Navigator.pop(context, true);
              },
              child: const Text('Hapus'),
            ),
          ],
        );
      },
    );

    if (confirm != true) {
      return;
    }

    final result = await DatabaseHelper.instance
        .deleteTransaction(transaction.id!, transaction.userId);

    if (result > 0 && context.mounted) {
      Navigator.pop(context, true);
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';
    final accentColor = isIncome ? AppColors.green : AppColors.red;
    final surface = AppColors.surface(context);
    final border = AppColors.border(context);
    final textPrimary = AppColors.textPrimary(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Transaksi'),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: PrivacyService.instance,
        builder: (context, _) {
          return SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ==================================================
                  // 1. HERO / SUMMARY CARD
                  // ==================================================
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      children: [
                        CircleAvatar(
                          radius: 28,
                          backgroundColor: accentColor.withValues(alpha: 0.12),
                          child: Icon(
                            _getCategoryIcon(transaction.category, isIncome),
                            size: 28,
                            color: accentColor,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            isIncome ? 'Pemasukan' : 'Pengeluaran',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: accentColor,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),
                        Text(
                          transaction.title,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${isIncome ? '+' : '-'} ${formatRupiah(transaction.amount)}',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: accentColor,
                            letterSpacing: -0.5,
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  // ==================================================
                  // 2. STATUS / INFORMASI TRANSAKSI
                  // ==================================================
                  Text(
                    'Informasi Transaksi',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: surface,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: border),
                    ),
                    child: Column(
                      children: [
                        _InfoRow(
                          icon: Icons.category_outlined,
                          label: 'Kategori',
                          value: transaction.category,
                        ),
                        Divider(height: 20, color: border),
                        _InfoRow(
                          icon: Icons.calendar_today_outlined,
                          label: 'Tanggal',
                          value: _formatDisplayDate(transaction.date),
                        ),
                        Divider(height: 20, color: border),
                        _InfoRow(
                          icon: Icons.swap_vert_outlined,
                          label: 'Tipe',
                          value: isIncome ? 'Pemasukan' : 'Pengeluaran',
                          valueColor: accentColor,
                        ),
                        Divider(height: 20, color: border),
                        _InfoRow(
                          icon: Icons.notes_outlined,
                          label: 'Catatan',
                          value: (transaction.notes != null &&
                                  transaction.notes!.trim().isNotEmpty)
                              ? transaction.notes!
                              : '-',
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  // ==================================================
                  // 3. ACTION AREA
                  // ==================================================
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => _handleDelete(context),
                          icon: const Icon(
                            Icons.delete_outline,
                            size: 18,
                            color: AppColors.red,
                          ),
                          label: const Text(
                            'Hapus',
                            style: TextStyle(
                              color: AppColors.red,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: AppColors.red,
                              width: 1.2,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 2,
                        child: ElevatedButton.icon(
                          onPressed: () => _handleEdit(context),
                          icon: const Icon(Icons.edit_outlined, size: 18),
                          label: const Text(
                            'Edit Transaksi',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ============================================================
// INFO ROW COMPONENT
// ============================================================

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);

    return Row(
      children: [
        Icon(icon, size: 18, color: textSecondary),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            fontSize: 13,
            color: textSecondary,
          ),
        ),
        const Spacer(),
        Flexible(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: valueColor ?? textPrimary,
            ),
            textAlign: TextAlign.end,
          ),
        ),
      ],
    );
  }
}
