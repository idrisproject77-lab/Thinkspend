import 'package:flutter/material.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/transaction_model.dart';
import 'package:thinkspend/models/user_model.dart';

class StatisticsPage extends StatefulWidget {
  final UserModel user;

  const StatisticsPage({super.key, required this.user});

  @override
  State<StatisticsPage> createState() => _StatisticsPageState();
}

class _StatisticsPageState extends State<StatisticsPage> {
  List<TransactionModel> transactions = [];

  double totalIncome = 0;
  double totalExpense = 0;

  final Map<String, double> categoryTotals = {};

  String selectedPeriod = 'Semua Waktu';

  @override
  void initState() {
    super.initState();
    loadStatistics();
  }

  Future<void> loadStatistics() async {
    final data = await DatabaseHelper.instance.getTransactions(widget.user.id!);

    // ==================================================
    // FILTER PERIODE
    // ==================================================

    final now = DateTime.now();

    List<TransactionModel> filteredData = [];

    for (final transaction in data) {
      try {
        final date = DateTime.parse(transaction.date);

        bool include = false;

        if (selectedPeriod == 'Semua Waktu') {
          include = true;
        } else if (selectedPeriod == 'Bulan Ini') {
          include = date.year == now.year && date.month == now.month;
        } else if (selectedPeriod == 'Bulan Lalu') {
          final lastMonth = DateTime(now.year, now.month - 1);

          include =
              date.year == lastMonth.year && date.month == lastMonth.month;
        }

        if (include) {
          filteredData.add(transaction);
        }
      } catch (_) {
        // Abaikan tanggal transaksi yang tidak valid.
      }
    }

    // ==================================================
    // HITUNG TOTAL
    // ==================================================

    double income = 0;
    double expense = 0;

    final Map<String, double> categories = {};

    for (final transaction in filteredData) {
      if (transaction.type == 'income') {
        income += transaction.amount;
      }

      if (transaction.type == 'expense') {
        expense += transaction.amount;

        categories[transaction.category] =
            (categories[transaction.category] ?? 0) + transaction.amount;
      }
    }

    if (!mounted) return;

    setState(() {
      transactions = filteredData;

      totalIncome = income;
      totalExpense = expense;

      categoryTotals
        ..clear()
        ..addAll(categories);
    });
  }

  String formatRupiah(double value) {
    final formatted = value
        .toStringAsFixed(0)
        .replaceAllMapped(RegExp(r'\B(?=(\d{3})+(?!\d))'), (match) => '.');

    return 'Rp $formatted';
  }

  @override
  Widget build(BuildContext context) {
    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return Scaffold(
      appBar: AppBar(title: const Text('Statistik')),

      body: RefreshIndicator(
        onRefresh: loadStatistics,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // JUDUL
              // ==================================================
              const Text(
                'Ringkasan Keuangan',
                style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                'Lihat bagaimana kondisi keuanganmu '
                'berdasarkan transaksi yang tercatat.',
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // FILTER PERIODE
              // ==================================================
              const Text(
                'Periode',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              DropdownButtonFormField<String>(
                initialValue: selectedPeriod,
                decoration: const InputDecoration(
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.calendar_month_outlined),
                ),
                items: const [
                  DropdownMenuItem(
                    value: 'Semua Waktu',
                    child: Text('Semua Waktu'),
                  ),
                  DropdownMenuItem(
                    value: 'Bulan Ini',
                    child: Text('Bulan Ini'),
                  ),
                  DropdownMenuItem(
                    value: 'Bulan Lalu',
                    child: Text('Bulan Lalu'),
                  ),
                ],
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    selectedPeriod = value;
                  });

                  loadStatistics();
                },
              ),

              const SizedBox(height: 24),

              // ==================================================
              // PEMASUKAN & PENGELUARAN
              // ==================================================
              Row(
                children: [
                  Expanded(
                    child: _SummaryCard(
                      title: 'Pemasukan',
                      value: formatRupiah(totalIncome),
                      icon: Icons.arrow_downward,
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: _SummaryCard(
                      title: 'Pengeluaran',
                      value: formatRupiah(totalExpense),
                      icon: Icons.arrow_upward,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ==================================================
              // PENGELUARAN PER KATEGORI
              // ==================================================
              const Text(
                'Pengeluaran per Kategori',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              if (sortedCategories.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Belum ada data pengeluaran '
                        'pada periode ini.',
                        style: TextStyle(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                Card(
                  child: Column(
                    children: [
                      for (int i = 0; i < sortedCategories.length; i++) ...[
                        _CategoryTile(
                          rank: i + 1,
                          category: sortedCategories[i].key,
                          amount: sortedCategories[i].value,
                          totalExpense: totalExpense,
                          formatRupiah: formatRupiah,
                        ),

                        if (i < sortedCategories.length - 1)
                          const Divider(height: 1),
                      ],
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // ==================================================
              // GRAFIK PENGELUARAN
              // ==================================================
              const Text(
                'Grafik Pengeluaran',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              if (sortedCategories.isEmpty)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Center(
                      child: Text(
                        'Belum ada data untuk ditampilkan.',
                        style: TextStyle(color: Colors.grey),
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      children: [
                        for (final category in sortedCategories)
                          _CategoryBar(
                            category: category.key,
                            amount: category.value,
                            maxAmount: sortedCategories.first.value,
                            formatRupiah: formatRupiah,
                          ),
                      ],
                    ),
                  ),
                ),

              const SizedBox(height: 24),

              // ==================================================
              // TOTAL TRANSAKSI
              // ==================================================
              Card(
                child: ListTile(
                  leading: const Icon(Icons.receipt_long_outlined),

                  title: const Text('Total Transaksi'),

                  subtitle: Text(
                    '${transactions.length} transaksi '
                    'tercatat',
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ============================================================
// SUMMARY CARD
// ============================================================

class _SummaryCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData icon;

  const _SummaryCard({
    required this.title,
    required this.value,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Icon(icon),

            const SizedBox(height: 12),

            Text(title, style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 4),

            Text(
              value,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}

// ============================================================
// CATEGORY TILE
// ============================================================

class _CategoryTile extends StatelessWidget {
  final int rank;
  final String category;
  final double amount;
  final double totalExpense;
  final String Function(double) formatRupiah;

  const _CategoryTile({
    required this.rank,
    required this.category,
    required this.amount,
    required this.totalExpense,
    required this.formatRupiah,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = totalExpense > 0 ? (amount / totalExpense) * 100 : 0;

    return ListTile(
      leading: CircleAvatar(child: Text('$rank')),

      title: Text(
        category,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),

      subtitle: Text(
        '${percentage.toStringAsFixed(1).replaceAll('.', ',')}% '
        'dari total pengeluaran',
      ),

      trailing: Text(
        formatRupiah(amount),
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
    );
  }
}

// ============================================================
// CATEGORY BAR
// ============================================================

class _CategoryBar extends StatelessWidget {
  final String category;
  final double amount;
  final double maxAmount;
  final String Function(double) formatRupiah;

  const _CategoryBar({
    required this.category,
    required this.amount,
    required this.maxAmount,
    required this.formatRupiah,
  });

  @override
  Widget build(BuildContext context) {
    final percentage = maxAmount > 0 ? amount / maxAmount : 0.0;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  category,
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),

              const SizedBox(width: 12),

              Text(
                formatRupiah(amount),
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),

          const SizedBox(height: 8),

          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: percentage.toDouble(),
              minHeight: 10,
            ),
          ),
        ],
      ),
    );
  }
}
