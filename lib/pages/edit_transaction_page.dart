import 'package:flutter/material.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/transaction_model.dart';
import 'package:thinkspend/utils/currency_input_formatter.dart';

class EditTransactionPage extends StatefulWidget {
  final TransactionModel transaction;

  const EditTransactionPage({super.key, required this.transaction});

  @override
  State<EditTransactionPage> createState() => _EditTransactionPageState();
}

class _EditTransactionPageState extends State<EditTransactionPage> {
  late TextEditingController titleController;
  late TextEditingController amountController;
  late String selectedCategory;
  late TextEditingController notesController;
  late String selectedType;

  String formatNominal(double value) {
    final digits = value.round().toString();
    return digits.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );
  }

  @override
  void initState() {
    super.initState();
    titleController = TextEditingController(text: widget.transaction.title);
    amountController = TextEditingController(
      text: formatNominal(widget.transaction.amount),
    );
    selectedCategory = widget.transaction.category;
    notesController = TextEditingController(
      text: widget.transaction.notes ?? '',
    );
    selectedType = widget.transaction.type;
  }

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  // ============================================================
  // UPDATE TRANSACTION
  // ============================================================

  Future<void> updateTransaction() async {
    final title = titleController.text.trim();
    final amount = double.tryParse(
      amountController.text.replaceAll('.', '').trim(),
    );
    final category = selectedCategory;
    final notes = notesController.text.trim();

    // ----------------------------------------------------------
    // VALIDASI
    // ----------------------------------------------------------
    if (title.isEmpty || amount == null || category.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Judul, nominal, dan kategori wajib diisi.'),
        ),
      );
      return;
    }

    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nominal harus lebih dari 0.')),
      );
      return;
    }

    // ----------------------------------------------------------
    // BUAT DATA BARU
    // ----------------------------------------------------------
    final updatedTransaction = TransactionModel(
      id: widget.transaction.id,
      userId: widget.transaction.userId,
      title: title,
      amount: amount,
      category: category,
      type: selectedType,
      date: widget.transaction.date,
      notes: notes.isEmpty ? null : notes,
    );

    // ----------------------------------------------------------
    // UPDATE DATABASE
    // ----------------------------------------------------------
    final result = await DatabaseHelper.instance.updateTransaction(
      updatedTransaction,
    );

    debugPrint('HASIL UPDATE TRANSAKSI: $result');
    debugPrint('USER ID: ${updatedTransaction.userId}');

    if (!mounted) return;

    if (result > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi berhasil diperbarui.')),
      );
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Transaksi gagal diperbarui.')),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Transaksi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Edit Transaksi',
              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 28),

            // JUDUL
            TextField(
              controller: titleController,
              decoration: const InputDecoration(
                labelText: 'Judul Transaksi',
                hintText: 'Contoh: Makan Siang',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // NOMINAL
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              inputFormatters: [CurrencyInputFormatter()],
              decoration: const InputDecoration(
                labelText: 'Nominal',
                hintText: 'Contoh: 25000',
                prefixText: 'Rp ',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),

            // TIPE
            DropdownButtonFormField<String>(
              initialValue: selectedType,
              decoration: const InputDecoration(
                labelText: 'Tipe Transaksi',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
                DropdownMenuItem(value: 'expense', child: Text('Pengeluaran')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedType = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // KATEGORI
            DropdownButtonFormField<String>(
              initialValue: selectedCategory,
              decoration: const InputDecoration(
                labelText: 'Kategori',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'Food', child: Text('Food')),
                DropdownMenuItem(value: 'Transport', child: Text('Transport')),
                DropdownMenuItem(value: 'Shopping', child: Text('Shopping')),
                DropdownMenuItem(value: 'Bills', child: Text('Bills')),
                DropdownMenuItem(
                  value: 'Entertainment',
                  child: Text('Entertainment'),
                ),
                DropdownMenuItem(value: 'Other', child: Text('Other')),
              ],
              onChanged: (value) {
                if (value != null) {
                  setState(() {
                    selectedCategory = value;
                  });
                }
              },
            ),
            const SizedBox(height: 16),

            // CATATAN
            TextField(
              controller: notesController,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Catatan',
                hintText: 'Catatan tambahan',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 28),

            // SIMPAN
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: updateTransaction,
                icon: const Icon(Icons.save_outlined),
                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Text(
                    'Simpan Perubahan',
                    style: TextStyle(fontSize: 16),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }
}
