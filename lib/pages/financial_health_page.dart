import 'package:flutter/material.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/goal_model.dart';
import 'package:thinkspend/models/transaction_model.dart';
import 'package:thinkspend/models/user_model.dart';
import 'package:thinkspend/services/financial_analyzer.dart';
import 'package:thinkspend/utils/currency_formatter.dart';

/// Halaman diagnostik Financial Health ThinkSpend.
///
/// Menggunakan [FinancialAnalyzer] sebagai Single Source of Truth untuk menampilkan:
/// - Skor total kesehatan keuangan (0 - 100) dan status (Keuangan Sehat, Cukup Sehat, Perlu Perhatian, Perlu Perbaikan).
/// - Rincian skor dan insight dari 4 pilar: Cash Flow, Pengeluaran, Tabungan, dan Konsistensi.
/// - Tips dan rekomendasi aksi perbaikan kondisi finansial.
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
  // FINANCIAL HEALTH ENGINE (DELEGATED TO SSOT: FinancialAnalyzer)
  // ============================================================

  HealthScoreBreakdown get breakdown => FinancialAnalyzer.calculateBreakdown(
        income: totalIncome,
        expense: totalExpense,
        monthlyBudget: widget.user.monthlyBudget,
        transactions: transactions,
      );

  int getCashFlowScore() => breakdown.cashFlowScore;

  int getExpenseScore() => breakdown.expenseScore;

  int getSavingScore() => breakdown.savingScore;

  int getConsistencyScore() => breakdown.consistencyScore;

  int get totalScore => breakdown.totalScore;

  double? get healthScore => FinancialAnalyzer.calculateHealthScore(
        income: totalIncome,
        expense: totalExpense,
        monthlyBudget: widget.user.monthlyBudget,
        transactions: transactions,
      );

  String get healthStatus => FinancialAnalyzer.getHealthStatus(healthScore);

  Color get healthColor => FinancialAnalyzer.getHealthColor(healthScore);

  String getCashFlowInsight() => breakdown.cashFlowInsight;

  String getExpenseInsight() => breakdown.expenseInsight;

  String getSavingInsight() => breakdown.savingInsight;

  String getConsistencyInsight() => breakdown.consistencyInsight;
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
                              healthScore == null ? '-' : '$totalScore',

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
