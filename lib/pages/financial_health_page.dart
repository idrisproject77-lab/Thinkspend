import 'package:flutter/material.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/goal_model.dart';
import 'package:thinkspend/models/transaction_model.dart';
import 'package:thinkspend/models/user_model.dart';
import 'package:thinkspend/utils/currency_formatter.dart';

class FinancialHealthPage extends StatefulWidget {
  final UserModel user;

  const FinancialHealthPage({super.key, required this.user});

  @override
  State<FinancialHealthPage> createState() => _FinancialHealthPageState();
}

class _FinancialHealthPageState extends State<FinancialHealthPage> {
  List<TransactionModel> transactions = [];
  List<GoalModel> goals = [];

  double totalIncome = 0;
  double totalExpense = 0;

  bool isLoading = true;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  // ============================================================
  // LOAD DATA
  // ============================================================

  Future<void> loadData() async {
    final transactionData = await DatabaseHelper.instance.getTransactions(
      widget.user.id!,
    );

    final goalData = await DatabaseHelper.instance.getGoals(widget.user.id!);

    double income = 0;
    double expense = 0;

    for (final transaction in transactionData) {
      if (transaction.type == 'income') {
        income += transaction.amount;
      } else if (transaction.type == 'expense') {
        expense += transaction.amount;
      }
    }

    if (!mounted) return;

    setState(() {
      transactions = transactionData;
      goals = goalData;
      totalIncome = income;
      totalExpense = expense;
      isLoading = false;
    });
  }

  // ============================================================
  // SCORE CASH FLOW
  // ============================================================

  int getCashFlowScore() {
    if (totalIncome <= 0) {
      return 0;
    }

    if (totalExpense <= 0) {
      return 40;
    }

    final ratio = totalExpense / totalIncome;

    if (ratio <= 0.30) {
      return 40;
    }

    if (ratio <= 0.50) {
      return 35;
    }

    if (ratio <= 0.70) {
      return 28;
    }

    if (ratio <= 0.85) {
      return 20;
    }

    if (ratio < 1.0) {
      return 10;
    }

    return 0;
  }

  // ============================================================
  // SCORE PENGELUARAN
  // ============================================================

  int getExpenseScore() {
    if (totalIncome <= 0) {
      return 0;
    }

    final ratio = totalExpense / totalIncome;

    if (ratio <= 0.30) {
      return 25;
    }

    if (ratio <= 0.50) {
      return 22;
    }

    if (ratio <= 0.70) {
      return 18;
    }

    if (ratio <= 0.85) {
      return 12;
    }

    if (ratio < 1.0) {
      return 6;
    }

    return 0;
  }

  // ============================================================
  // SCORE TABUNGAN
  // ============================================================

  int getSavingScore() {
    if (totalIncome <= 0) {
      return 0;
    }

    final available = totalIncome - totalExpense;

    if (available <= 0) {
      return 0;
    }

    final savingRatio = available / totalIncome;

    if (savingRatio >= 0.40) {
      return 20;
    }

    if (savingRatio >= 0.30) {
      return 17;
    }

    if (savingRatio >= 0.20) {
      return 14;
    }

    if (savingRatio >= 0.10) {
      return 10;
    }

    return 5;
  }

  // ============================================================
  // SCORE KONSISTENSI
  // ============================================================

 int getConsistencyScore() {
  if (transactions.isEmpty) {
    return 0;
  }

  final now = DateTime.now();

  final activeDays = <String>{};

  for (final transaction in transactions) {
    try {
      final date = DateTime.parse(transaction.date);

      final difference =
          DateTime(now.year, now.month, now.day)
              .difference(
                DateTime(
                  date.year,
                  date.month,
                  date.day,
                ),
              )
              .inDays;

      if (difference >= 0 && difference < 7) {
        activeDays.add(
          '${date.year}-${date.month}-${date.day}',
        );
      }
    } catch (_) {
      // Abaikan tanggal transaksi
      // yang tidak valid.
    }
  }

  final activeDayCount = activeDays.length;

  if (activeDayCount >= 7) {
    return 15;
  }

  if (activeDayCount >= 5) {
    return 10;
  }

  if (activeDayCount >= 3) {
    return 6;
  }

  return 3;
}
  // ============================================================
  // TOTAL SCORE
  // ============================================================

  int get totalScore {
    final score =
        getCashFlowScore() +
        getExpenseScore() +
        getSavingScore() +
        getConsistencyScore();

    return score.clamp(0, 100);
  }

  // ============================================================
  // STATUS
  // ============================================================

  String get healthStatus {
    if (totalIncome <= 0) {
      return 'Belum Ada Data';
    }

    if (totalScore >= 80) {
      return 'Sangat Sehat';
    }

    if (totalScore >= 60) {
      return 'Cukup Sehat';
    }

    if (totalScore >= 40) {
      return 'Perlu Perhatian';
    }

    return 'Perlu Perbaikan';
  }

  Color get healthColor {
    if (totalIncome <= 0) {
      return Colors.grey;
    }

    if (totalScore >= 80) {
      return Colors.green;
    }

    if (totalScore >= 60) {
      return Colors.blue;
    }

    if (totalScore >= 40) {
      return Colors.orange;
    }

    return Colors.red;
  }

  // ============================================================
  // FORMAT RUPIAH
  // ============================================================

 

  // ============================================================
  // INSIGHT CASH FLOW
  // ============================================================

  String getCashFlowInsight() {
    if (totalIncome <= 0) {
      return 'Tambahkan transaksi pemasukan '
          'untuk mulai menganalisis kondisi '
          'keuanganmu.';
    }

    if (totalExpense <= 0) {
      return 'Belum ada pengeluaran yang '
          'tercatat. Pastikan semua transaksi '
          'dicatat agar analisis lebih akurat.';
    }

    if (totalExpense < totalIncome) {
      return 'Pemasukanmu masih lebih besar '
          'daripada pengeluaran.';
    }

    if (totalExpense == totalIncome) {
      return 'Pengeluaranmu sudah sama dengan '
          'pemasukan. Sebaiknya mulai '
          'mengurangi pengeluaran.';
    }

    return 'Pengeluaranmu sudah melebihi '
        'pemasukan. Kondisi ini perlu segera '
        'diperhatikan.';
  }

  // ============================================================
  // INSIGHT TABUNGAN
  // ============================================================

  String getExpenseInsight() {
    if (totalIncome <= 0) {
      return 'Belum cukup data untuk menganalisis pengeluaran.';
    }

    if (totalExpense <= 0) {
      return 'Belum ada pengeluaran yang tercatat.';
    }

    final ratio = totalExpense / totalIncome;

    if (ratio <= 0.30) {
      return 'Pengeluaranmu masih sangat terkendali.';
    }

    if (ratio <= 0.70) {
      return 'Pengeluaranmu masih terkendali.';
    }

    if (ratio < 1.0) {
      return 'Pengeluaranmu mulai mendekati pemasukan.';
    }

    return 'Pengeluaranmu sudah melebihi pemasukan.';
  }

  String getSavingInsight() {
    final remaining = totalIncome - totalExpense;

    if (totalIncome <= 0) {
      return 'Belum ada pemasukan yang bisa disisihkan.';
    }

    if (remaining <= 0) {
      return 'Belum ada uang yang tersisa untuk ditabung.';
    }

    return 'Kamu masih punya uang yang bisa ditabung.';
  }

  // ============================================================
  // INSIGHT KONSISTENSI
  // ============================================================

String getConsistencyInsight() {
  if (transactions.isEmpty) {
    return 'Belum ada transaksi yang tercatat.';
  }

  final now = DateTime.now();

  final activeDays = <String>{};

  for (final transaction in transactions) {
    try {
      final date = DateTime.parse(transaction.date);

      final difference =
          DateTime(now.year, now.month, now.day)
              .difference(
                DateTime(
                  date.year,
                  date.month,
                  date.day,
                ),
              )
              .inDays;

      if (difference >= 0 && difference < 7) {
        activeDays.add(
          '${date.year}-${date.month}-${date.day}',
        );
      }
    } catch (_) {
      // Abaikan tanggal transaksi
      // yang tidak valid.
    }
  }

  final activeDayCount = activeDays.length;

  if (activeDayCount >= 7) {
    return 'Kamu konsisten mencatat transaksi '
        'setiap hari dalam 7 hari terakhir.';
  }

  if (activeDayCount >= 5) {
    return 'Kamu cukup konsisten mencatat transaksi '
        'dalam 7 hari terakhir.';
  }

  if (activeDayCount >= 3) {
    return 'Kamu mulai rutin mencatat transaksi. '
        'Coba pertahankan kebiasaan ini.';
  }

  return 'Catatan transaksi masih belum rutin. '
      'Coba catat transaksi setiap hari.';
}
  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Financial Health')),

      body: RefreshIndicator(
        onRefresh: loadData,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ==================================================
              // SCORE
              // ==================================================
              Center(
                child: Column(
                  children: [
                    const Text(
                      'Financial Health',

                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      width: 170,
                      height: 170,

                      decoration: BoxDecoration(
                        shape: BoxShape.circle,

                        border: Border.all(color: healthColor, width: 10),
                      ),

                      child: Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,

                          children: [
                            Text(
                              totalIncome <= 0 ? '-' : '$totalScore',

                              style: TextStyle(
                                fontSize: 42,
                                fontWeight: FontWeight.bold,
                                color: healthColor,
                              ),
                            ),

                            const Text(
                              '/ 100',

                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 16),

                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 8,
                      ),

                      decoration: BoxDecoration(
                        color: healthColor.withValues(alpha: 0.10),

                        borderRadius: BorderRadius.circular(20),
                      ),

                      child: Text(
                        healthStatus,

                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: healthColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ==================================================
              // BREAKDOWN
              // ==================================================
              const Text(
                'Breakdown',

                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 12),

              _scoreCard(
                icon: Icons.account_balance_wallet_outlined,
                title: 'Cash Flow',
                score: getCashFlowScore(),
                maxScore: 40,
                description: getCashFlowInsight(),
              ),

              const SizedBox(height: 12),

              _scoreCard(
                icon: Icons.shopping_bag_outlined,
                title: 'Pengeluaran',
                score: getExpenseScore(),
                maxScore: 25,
                description: getExpenseInsight(),
              ),

              const SizedBox(height: 12),

              _scoreCard(
                icon: Icons.savings_outlined,
                title: 'Tabungan',
                score: getSavingScore(),
                maxScore: 20,
                description: getSavingInsight(),
              ),

              const SizedBox(height: 12),

              _scoreCard(
                icon: Icons.edit_calendar_outlined,
                title: 'Konsistensi',
                score: getConsistencyScore(),
                maxScore: 15,
                description: getConsistencyInsight(),
              ),

              const SizedBox(height: 28),

              // ==================================================
              // RINGKASAN
              // ==================================================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Ringkasan',

                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      _summaryRow(
                        'Total Pemasukan',
                        formatRupiah(totalIncome),
                        Colors.green,
                      ),

                      const SizedBox(height: 12),

                      _summaryRow(
                        'Total Pengeluaran',
                        formatRupiah(totalExpense),
                        Colors.red,
                      ),

                      const Divider(height: 28),

                      _summaryRow(
                        'Sisa Pemasukan',
                        formatRupiah(totalIncome - totalExpense),
                        Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // SCORE CARD
  // ============================================================

  Widget _scoreCard({
    required IconData icon,
    required String title,
    required int score,
    required int maxScore,
    required String description,
  }) {
    final percentage = maxScore > 0 ? score / maxScore : 0.0;

    Color color;

    if (percentage >= 0.80) {
      color = Colors.green;
    } else if (percentage >= 0.60) {
      color = Colors.blue;
    } else if (percentage >= 0.40) {
      color = Colors.orange;
    } else {
      color = Colors.red;
    }

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Row(
              children: [
                Icon(icon, color: color),

                const SizedBox(width: 12),

                Expanded(
                  child: Text(
                    title,

                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),

                Text(
                  '$score / $maxScore',

                  style: TextStyle(fontWeight: FontWeight.bold, color: color),
                ),
              ],
            ),

            const SizedBox(height: 14),

            LinearProgressIndicator(value: percentage, minHeight: 8),

            const SizedBox(height: 14),

            Text(
              description,

              style: const TextStyle(color: Colors.grey, height: 1.5),
            ),
          ],
        ),
      ),
    );
  }

  // ============================================================
  // SUMMARY ROW
  // ============================================================

  Widget _summaryRow(String title, String value, Color color) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,

      children: [
        Expanded(
          child: Text(title, style: const TextStyle(color: Colors.grey)),
        ),

        const SizedBox(width: 12),

        Text(
          value,

          style: TextStyle(fontWeight: FontWeight.bold, color: color),
        ),
      ],
    );
  }
}
