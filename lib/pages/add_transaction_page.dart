import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/transaction_model.dart';
import 'package:thinkspend/models/user_model.dart';
import 'package:thinkspend/utils/currency_input_formatter.dart';

class AddTransactionPage extends StatefulWidget {
  final UserModel user;

  const AddTransactionPage({super.key, required this.user});

  @override
  State<AddTransactionPage> createState() => _AddTransactionPageState();
}

class _AddTransactionPageState extends State<AddTransactionPage> {
  final titleController = TextEditingController();
  final amountController = TextEditingController();
  final notesController = TextEditingController();

  String selectedCategory = 'Food';
  String selectedType = 'expense';
  DateTime selectedDate = DateTime.now();

  final List<String> categories = [
    'Food',
    'Transport',
    'Shopping',
    'Bills',
    'Entertainment',
    'Other',
  ];

  @override
  void dispose() {
    titleController.dispose();
    amountController.dispose();
    notesController.dispose();
    super.dispose();
  }

  // ============================================================
  // HITUNG SALDO USER YANG SEDANG LOGIN
  // ============================================================

  Future<double> getCurrentBalance() async {
    final transactions = await DatabaseHelper.instance.getTransactions(
      widget.user.id!,
    );

    double income = widget.user.income;
    double expense = 0;

    for (final transaction in transactions) {
      if (transaction.type == 'income') {
        income += transaction.amount;
      } else if (transaction.type == 'expense') {
        expense += transaction.amount;
      }
    }

    return income - expense;
  }

  // ============================================================
  // THINK BEFORE YOU SPEND
  // ============================================================

  Future<bool> showThinkBeforeYouSpend(
    double amount,
    double currentBalance,
  ) async {
    final remainingBalance = currentBalance - amount;
    final percentage = currentBalance > 0
        ? (amount / currentBalance) * 100
        : 100.0;

    final bool isNegative = remainingBalance < 0;

    final String message = isNegative
        ? 'Pengeluaran ini akan membuat saldo kamu menjadi negatif.\n\n'
              'Saldo saat ini: Rp ${currentBalance.toStringAsFixed(0)}\n'
              'Pengeluaran: Rp ${amount.toStringAsFixed(0)}\n'
              'Perkiraan saldo: Rp ${remainingBalance.toStringAsFixed(0)}'
        : 'Pengeluaran ini cukup besar dibandingkan saldo kamu.\n\n'
              'Saldo saat ini: Rp ${currentBalance.toStringAsFixed(0)}\n'
              'Pengeluaran: Rp ${amount.toStringAsFixed(0)}\n'
              'Perkiraan saldo: Rp ${remainingBalance.toStringAsFixed(0)}\n\n'
              'Transaksi ini menggunakan sekitar ${percentage.toStringAsFixed(0)}% dari saldo kamu.';

    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          titlePadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
          contentPadding: const EdgeInsets.fromLTRB(24, 12, 24, 0),
          title: Column(
            children: [
              if (!isNegative)
                Lottie.asset(
                  'assets/animations/thinking.json',
                  height: 80,
                  width: 80,
                  repeat: true,
                )
              else
                const Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 64,
                ),
              const SizedBox(height: 8),
              const Text(
                'Think Before You Spend',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 21, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          content: Text(
            message,
            textAlign: TextAlign.left,
            style: const TextStyle(fontSize: 15, height: 1.45),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Tetap Simpan'),
            ),
          ],
        );
      },
    );

    return result ?? false;
  }

  // ============================================================
  // SIMPAN TRANSAKSI
  // ============================================================

  Future<void> selectTransactionDate() async {
    final now = DateTime.now();

    final pickedDate = await showDatePicker(
      context: context,
      initialDate: selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
    );

    if (pickedDate != null) {
      setState(() {
        selectedDate = pickedDate;
      });
    }
  }

  Future<void> saveTransaction() async {
    final title = titleController.text.trim();
    final amountText = amountController.text.trim();
    final notes = notesController.text.trim();

    if (title.isEmpty || amountText.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Judul dan nominal wajib diisi')),
      );
      return;
    }

    final amount = double.tryParse(amountText.replaceAll('.', ''));
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Nominal tidak valid')));
      return;
    }

    if (selectedType == 'expense') {
      final currentBalance = await getCurrentBalance();

      bool needConfirmation = false;
      if (currentBalance <= 0 || amount > currentBalance * 0.20) {
        needConfirmation = true;
      }

      if (needConfirmation) {
        if (!mounted) return;

        final shouldSave = await showThinkBeforeYouSpend(
          amount,
          currentBalance,
        );

        if (!shouldSave) return;
      }
    }

    final transaction = TransactionModel(
      userId: widget.user.id!,
      title: title,
      amount: amount,
      category: selectedCategory,
      type: selectedType,
      date: selectedDate.toIso8601String(),
      notes: notes.isEmpty ? null : notes,
    );

    final id = await DatabaseHelper.instance.insertTransaction(transaction);

    debugPrint('TRANSAKSI BERHASIL DISIMPAN');
    debugPrint('USER ID: ${widget.user.id}');
    debugPrint('TRANSACTION ID: $id');

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaksi berhasil disimpan')),
    );

    Navigator.pop(context, true);
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Transaksi')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Tambah Transaksi',
              style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            const Text(
              'Catat pemasukan atau pengeluaranmu.',
              style: TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 30),

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

            // ==================================================
            // TANGGAL
            // ==================================================
            InkWell(
              onTap: selectTransactionDate,

              borderRadius: BorderRadius.circular(4),

              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Tanggal',
                  border: OutlineInputBorder(),
                  suffixIcon: Icon(Icons.calendar_today_outlined),
                ),

                child: Text(
                  '${selectedDate.day.toString().padLeft(2, '0')}-'
                  '${selectedDate.month.toString().padLeft(2, '0')}-'
                  '${selectedDate.year}',
                ),
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
                hintText: 'Masukkan nominal',
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
                DropdownMenuItem(value: 'expense', child: Text('Pengeluaran')),
                DropdownMenuItem(value: 'income', child: Text('Pemasukan')),
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
              items: categories.map((category) {
                return DropdownMenuItem(value: category, child: Text(category));
              }).toList(),
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
                hintText: 'Catatan tambahan (opsional)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 24),

            // BUTTON
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: saveTransaction,
                icon: const Icon(Icons.save_outlined),
                label: const Text('Simpan Transaksi'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
