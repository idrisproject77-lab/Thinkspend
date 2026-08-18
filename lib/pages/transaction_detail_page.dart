import 'package:flutter/material.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/transaction_model.dart';
import 'package:thinkspend/utils/currency_formatter.dart';

import 'edit_transaction_page.dart';

class TransactionDetailPage extends StatelessWidget {
  final TransactionModel transaction;

  const TransactionDetailPage({super.key, required this.transaction});

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Transaksi')),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            // ==================================================
            // JUDUL
            // ==================================================
            Text(
              transaction.title,

              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // NOMINAL
            // ==================================================
            Text(
              '${isIncome ? '+' : '-'} '
              '${formatRupiah(transaction.amount)}',

              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: isIncome ? Colors.green : Colors.red,
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // KATEGORI
            // ==================================================
            const Text('Kategori', style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 4),

            Text(transaction.category, style: const TextStyle(fontSize: 18)),

            const SizedBox(height: 20),

            // ==================================================
            // TIPE
            // ==================================================
            const Text('Tipe', style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 4),

            Text(
              transaction.type == 'income' ? 'Pemasukan' : 'Pengeluaran',

              style: const TextStyle(fontSize: 18),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // TANGGAL
            // ==================================================
            const Text('Tanggal', style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 4),

            Text(transaction.date, style: const TextStyle(fontSize: 18)),

            const SizedBox(height: 20),

            // ==================================================
            // CATATAN
            // ==================================================
            const Text('Catatan', style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 4),

            Text(
              transaction.notes ?? '-',

              style: const TextStyle(fontSize: 18),
            ),

            const Spacer(),

            // ==================================================
            // EDIT
            // ==================================================
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,

                    MaterialPageRoute(
                      builder: (context) =>
                          EditTransactionPage(transaction: transaction),
                    ),
                  );

                  if (result == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },

                icon: const Icon(Icons.edit),

                label: const Text('Edit Transaksi'),
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // DELETE
            // ==================================================
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: () async {
                  if (transaction.id == null) {
                    return;
                  }

                  final confirm = await showDialog<bool>(
                    context: context,

                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Hapus Transaksi?'),

                        content: const Text(
                          'Transaksi ini akan '
                          'dihapus secara permanen.',
                        ),

                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },

                            child: const Text('Batal'),
                          ),

                          ElevatedButton(
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
                },

                icon: const Icon(Icons.delete),

                label: const Text('Hapus Transaksi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
