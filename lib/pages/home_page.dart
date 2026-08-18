import 'package:flutter/material.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/user_model.dart';
import 'package:thinkspend/models/transaction_model.dart';
import 'package:thinkspend/models/goal_model.dart';
import 'package:thinkspend/pages/transaction_detail_page.dart';
import 'package:thinkspend/utils/currency_formatter.dart';
import 'package:thinkspend/widgets/transaction_card.dart';

import 'financial_health_page.dart';
import 'saving_planner_page.dart';
import 'package:thinkspend/views/profile_page.dart';

class HomePage extends StatefulWidget {
  final UserModel user;
  final VoidCallback onLogout;

  const HomePage({
    super.key,
    required this.user,
    required this.onLogout,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late UserModel currentUser;
  List<TransactionModel> transactions = [];
  List<GoalModel> goals = [];

  double totalIncome = 0;
  double totalExpense = 0;

  @override
  void initState() {
    super.initState();

    currentUser = widget.user;

    loadTransactions();
  }

  // ============================================================
  // LOAD TRANSACTIONS & GOALS
  // ============================================================

  Future<void> loadTransactions() async {
    final data = await DatabaseHelper.instance.getTransactions(currentUser.id!);

    final goalsData = await DatabaseHelper.instance.getGoals(currentUser.id!);

    double income = 0;
    double expense = 0;

    for (final transaction in data) {
      if (transaction.type == 'income') {
        income += transaction.amount;
      } else if (transaction.type == 'expense') {
        expense += transaction.amount;
      }
    }

    if (!mounted) return;

    setState(() {
      transactions = data;
      goals = goalsData;
      totalIncome = income;
      totalExpense = expense;
    });
  }

  // ============================================================
  // FORMAT TANGGAL
  // ============================================================

  String formatDate(String date) {
    if (date.length >= 10) {
      return date.substring(0, 10);
    }

    return date;
  }

  // ============================================================
  // FINANCIAL HEALTH SCORE
  // ============================================================

  double? calculateHealthScore() {
    if (transactions.isEmpty) {
      return null;
    }

    double score = 0;

    // ============================================================
    // 1. CASH FLOW - MAKS 40
    // ============================================================

    if (totalIncome > 0) {
      final spendingRatio = totalExpense / totalIncome;

      if (spendingRatio <= 0.30) {
        score += 40;
      } else if (spendingRatio <= 0.50) {
        score += 35;
      } else if (spendingRatio <= 0.70) {
        score += 28;
      } else if (spendingRatio <= 0.85) {
        score += 20;
      } else if (spendingRatio < 1.0) {
        score += 10;
      } else {
        score += 0;
      }
    } else if (totalExpense == 0) {
      score += 20;
    }

    // ============================================================
    // 2. PENGELUARAN - MAKS 25
    // ============================================================

    final budget = currentUser.monthlyBudget;

    if (budget > 0) {
      final budgetRatio = totalExpense / budget;

      if (budgetRatio <= 0.60) {
        score += 25;
      } else if (budgetRatio <= 0.80) {
        score += 20;
      } else if (budgetRatio <= 1.00) {
        score += 12;
      } else {
        score += 0;
      }
    } else {
      if (totalIncome > 0) {
        final spendingRatio = totalExpense / totalIncome;

        if (spendingRatio <= 0.30) {
          score += 25;
        } else if (spendingRatio <= 0.50) {
          score += 22;
        } else if (spendingRatio <= 0.70) {
          score += 18;
        } else if (spendingRatio <= 0.85) {
          score += 12;
        } else if (spendingRatio < 1.0) {
          score += 6;
        } else {
          score += 0;
        }
      }
    }

    // ============================================================
    // 3. TABUNGAN - MAKS 20
    // ============================================================

    if (totalIncome > 0) {
      final available = totalIncome - totalExpense;

      if (available > 0) {
        final savingRatio = available / totalIncome;

        if (savingRatio >= 0.40) {
          score += 20;
        } else if (savingRatio >= 0.30) {
          score += 17;
        } else if (savingRatio >= 0.20) {
          score += 14;
        } else if (savingRatio >= 0.10) {
          score += 10;
        } else {
          score += 5;
        }
      }
    }

    // ============================================================
    // 4. KONSISTENSI - MAKS 15
    // ============================================================

    final transactionCount = transactions.length;

    if (transactionCount >= 15) {
      score += 15;
    } else if (transactionCount >= 10) {
      score += 10;
    } else if (transactionCount >= 5) {
      score += 6;
    } else {
      score += 3;
    }

    return score.clamp(0.0, 100.0);
  }

  // ============================================================
  // STATUS HEALTH SCORE
  // ============================================================

  String getHealthStatus(double? score) {
    if (score == null) {
      if (transactions.isEmpty) {
        return 'Belum Ada Data';
      }

      return 'Data Belum Cukup';
    }

    if (score >= 80) {
      return 'Keuangan Sehat';
    }

    if (score >= 60) {
      return 'Cukup Sehat';
    }

    if (score >= 40) {
      return 'Perlu Perhatian';
    }

    return 'Perlu Perbaikan';
  }

  // ============================================================
  // ICON HEALTH SCORE
  // ============================================================

  IconData getHealthIcon(double? score) {
    if (score == null) {
      return Icons.analytics_outlined;
    }

    if (score >= 80) {
      return Icons.favorite;
    }

    if (score >= 60) {
      return Icons.sentiment_satisfied;
    }

    if (score >= 40) {
      return Icons.warning_amber_rounded;
    }

    return Icons.error_outline;
  }

  // ============================================================
  // WARNA HEALTH SCORE
  // ============================================================

  Color getHealthColor(double? score) {
    if (score == null) {
      return Colors.grey;
    }

    if (score >= 80) {
      return Colors.green;
    }

    if (score >= 60) {
      return Colors.blue;
    }

    if (score >= 40) {
      return Colors.orange;
    }

    return Colors.red;
  }

  // ============================================================
  // DESKRIPSI HEALTH SCORE
  // ============================================================

  String getHealthDescription(double? score) {
    if (score == null) {
      if (transactions.isEmpty) {
        return 'Belum ada data transaksi. '
            'Mulai catat pemasukan dan pengeluaranmu '
            'untuk melihat kesehatan keuangan.';
      }

      return 'Data keuanganmu masih terlalu sedikit '
          'untuk dinilai. Catat minimal 3 transaksi '
          'agar ThinkSpend dapat memberikan penilaian '
          'yang lebih akurat.';
    }

    if (score >= 80) {
      return 'Kondisi keuanganmu sangat baik. '
          'Arus kas positif dan pengeluaran terkendali '
          'dengan baik. Pertahankan kebiasaan ini!';
    }

    if (score >= 60) {
      return 'Kondisi keuanganmu cukup sehat, '
          'tetapi masih ada ruang untuk mengoptimalkan '
          'anggaran dan meningkatkan tabungan.';
    }

    if (score >= 40) {
      return 'Pengeluaranmu mulai perlu diperhatikan. '
          'Coba evaluasi kategori pengeluaran terbesar '
          'dan gunakan budget dengan lebih disiplin.';
    }

    return 'Pengeluaranmu cukup tinggi dibandingkan '
        'kondisi pemasukan atau budget. '
        'Pertimbangkan untuk mengurangi pengeluaran '
        'yang tidak terlalu penting.';
  }

  // ============================================================
  // THINKSPEND INSIGHT
  // ============================================================

  String getSpendingInsight() {
    final expenses = transactions
        .where((transaction) => transaction.type == 'expense')
        .toList();

    if (expenses.isEmpty) {
      return '💡 Mulai catat pengeluaranmu untuk '
          'mendapatkan insight keuangan.';
    }

    // ============================================================
    // BELUM CUKUP DATA UNTUK MELIHAT POLA
    // ============================================================

    if (expenses.length == 1) {
      final transaction = expenses.first;

      return 'Pengeluaran terbesar kamu adalah '
          '${transaction.category} sebesar '
          '${formatRupiah(transaction.amount)}. '
          'Saat ini baru ada 1 transaksi pengeluaran, '
          'jadi belum cukup data untuk melihat pola '
          'pengeluaranmu.';
    }

    // ============================================================
    // HITUNG TOTAL PER KATEGORI
    // ============================================================

    final Map<String, double> categoryTotals = {};

    for (final transaction in expenses) {
      categoryTotals[transaction.category] =
          (categoryTotals[transaction.category] ?? 0) + transaction.amount;
    }

    // ============================================================
    // CARI KATEGORI TERBESAR
    // ============================================================

    String biggestCategory = '';
    double biggestAmount = 0;

    categoryTotals.forEach((category, amount) {
      if (amount > biggestAmount) {
        biggestCategory = category;
        biggestAmount = amount;
      }
    });

    // ============================================================
    // PERSENTASE
    // ============================================================

    final percentage = totalExpense > 0
        ? (biggestAmount / totalExpense) * 100
        : 0;

    return 'Pengeluaran terbesar kamu adalah '
        '$biggestCategory sebesar '
        '${formatRupiah(biggestAmount)}. '
        'Itu sekitar '
        '${percentage.toStringAsFixed(0)}% '
        'dari total pengeluaranmu.';
  }

  String? getImpulseInsight() {
    final expenses = transactions
        .where((transaction) => transaction.type == 'expense')
        .toList();

    if (expenses.isEmpty) {
      return null;
    }

    final balanceBeforeExpense =
        currentUser.income + totalIncome - totalExpense;

    if (balanceBeforeExpense <= 0) {
      return null;
    }

    final latestExpense = expenses.last;

    final percentage = (latestExpense.amount / balanceBeforeExpense) * 100;

    // Pengeluaran yang mengambil >= 50% saldo
    if (percentage >= 50) {
      return '🧠 Pengeluaran ini cukup besar dibandingkan saldo kamu. '
          'Coba pikirkan lagi apakah pembelian ini benar-benar diperlukan.';
    }

    return null;
  }

  // ============================================================
  // BUDGET INSIGHT
  // ============================================================

  String? getBudgetInsight() {
    final budget = currentUser.monthlyBudget;

    if (budget <= 0) {
      return null;
    }

    if (totalExpense <= 0) {
      return '💰 Belum ada pengeluaran bulan ini. '
          'Budget kamu masih utuh.';
    }

    final percentage = (totalExpense / budget) * 100;

    final remaining = budget - totalExpense;

    if (percentage >= 100) {
      return '⚠️ Budget bulananmu sudah terlampaui '
          'sebesar ${formatRupiah(-remaining)}.';
    }

    if (percentage >= 80) {
      return '⚠️ Kamu sudah menggunakan '
          '${percentage.toStringAsFixed(0)}% '
          'budget bulanan. '
          'Sisa budget: ${formatRupiah(remaining)}.';
    }

    return '👍 Pengeluaranmu masih berada '
        'dalam batas budget. '
        'Kamu sudah menggunakan '
        '${percentage.toStringAsFixed(0)}% budget.';
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final balance = currentUser.income + totalIncome - totalExpense;

    final isNegativeBalance = balance < 0;

    final recentTransactions = transactions.reversed.toList();

    final spendingInsight = getSpendingInsight();

    final impulseInsight = getImpulseInsight();

    final budgetInsight = getBudgetInsight();

    final healthScore = calculateHealthScore();

    final healthStatus = getHealthStatus(healthScore);

    final healthColor = getHealthColor(healthScore);

    final healthIcon = getHealthIcon(healthScore);

    final healthDescription = getHealthDescription(healthScore);

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: loadTransactions,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ==================================================
              // PROFILE HEADER
              // ==================================================
              InkWell(
                borderRadius: BorderRadius.circular(18),

                onTap: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          ProfilePage(user: currentUser, onLogout: widget.onLogout),
                    ),
                  );

                  if (result is UserModel && mounted) {
                    setState(() {
                      currentUser = result;
                    });
                  }
                },

                child: Container(
                  width: double.infinity,

                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 16,
                  ),

                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,

                    borderRadius: BorderRadius.circular(18),

                    border: Border.all(color: Colors.grey.shade200, width: 1),

                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.04),
                        blurRadius: 8,
                        offset: const Offset(0, 3),
                      ),
                    ],
                  ),

                  child: Row(
                    children: [
                      CircleAvatar(
                        radius: 30,

                        child: Text(
                          currentUser.name.isNotEmpty
                              ? currentUser.name[0].toUpperCase()
                              : '?',

                          style: const TextStyle(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),

                      const SizedBox(width: 16),

                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            Text(
                              'Halo, ${currentUser.name} 👋',

                              style: const TextStyle(
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),

                            const SizedBox(height: 4),

                            Text(
                              currentUser.email,

                              style: TextStyle(
                                fontSize: 15,
                                color: Colors.grey.shade600,
                              ),
                            ),
                          ],
                        ),
                      ),

                      Icon(
                        Icons.chevron_right,
                        size: 30,
                        color: Colors.grey.shade500,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // SALDO
              // ==================================================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Saldo',

                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),

                      const SizedBox(height: 8),

                      Text(
                        formatRupiah(balance),

                        style: const TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // PEMASUKAN & PENGELUARAN
              // ==================================================
              Row(
                children: [
                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            const Text(
                              'Pemasukan',

                              style: TextStyle(color: Colors.grey),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              formatRupiah(totalIncome),

                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.green,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 12),

                  Expanded(
                    child: Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),

                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,

                          children: [
                            const Text(
                              'Pengeluaran',

                              style: TextStyle(color: Colors.grey),
                            ),

                            const SizedBox(height: 8),

                            Text(
                              formatRupiah(totalExpense),

                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.red,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // ==================================================
              // FINANCIAL HEALTH SCORE
              // ==================================================
              InkWell(
                borderRadius: BorderRadius.circular(16),

                onTap: () async {
                  await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          FinancialHealthPage(user: widget.user),
                    ),
                  );

                  if (!mounted) return;

                  await loadTransactions();
                },

                child: Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),

                    child: Column(
                      children: [
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(10),

                              decoration: BoxDecoration(
                                color: healthColor.withValues(alpha: 0.12),

                                borderRadius: BorderRadius.circular(12),
                              ),

                              child: Icon(healthIcon, color: healthColor),
                            ),

                            const SizedBox(width: 12),

                            const Expanded(
                              child: Text(
                                'Financial Health',

                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Stack(
                          alignment: Alignment.center,

                          children: [
                            SizedBox(
                              width: 150,
                              height: 150,

                              child: CircularProgressIndicator(
                                value: healthScore != null
                                    ? healthScore / 100
                                    : 0,

                                strokeWidth: 12,

                                backgroundColor: Colors.grey.withValues(
                                  alpha: 0.15,
                                ),

                                valueColor: AlwaysStoppedAnimation<Color>(
                                  healthColor,
                                ),
                              ),
                            ),

                            Column(
                              children: [
                                Text(
                                  healthScore != null
                                      ? healthScore.toStringAsFixed(0)
                                      : '—',

                                  style: const TextStyle(
                                    fontSize: 36,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),

                                const Text(
                                  '/ 100',

                                  style: TextStyle(color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),

                        const SizedBox(height: 16),

                        Text(
                          healthStatus,

                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: healthColor,
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          healthDescription,

                          textAlign: TextAlign.center,

                          style: const TextStyle(
                            color: Colors.grey,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // THINKSPEND INSIGHT
              // ==================================================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),

                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),

                              color: Theme.of(
                                context,
                              ).colorScheme.primaryContainer,
                            ),

                            child: Icon(
                              Icons.psychology_outlined,

                              color: Theme.of(
                                context,
                              ).colorScheme.onPrimaryContainer,
                            ),
                          ),

                          const SizedBox(width: 12),

                          const Expanded(
                            child: Text(
                              'ThinkSpend Insight',

                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text(
                        spendingInsight,
                        style: const TextStyle(fontSize: 15, height: 1.5),
                      ),

                      if (impulseInsight != null) ...[
                        const SizedBox(height: 16),

                        const Divider(),

                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                          child: Text(
                            impulseInsight,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],

                      if (budgetInsight != null) ...[
                        const SizedBox(height: 16),

                        const Divider(),

                        const SizedBox(height: 12),

                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: Theme.of(
                              context,
                            ).colorScheme.surfaceContainerHighest,
                          ),
                          child: Text(
                            budgetInsight,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.5,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // ==================================================
              // SMART SAVING PLANNER
              // ==================================================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: Colors.green.withValues(alpha: 0.12),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Icon(
                              Icons.savings_outlined,
                              color: Colors.green,
                            ),
                          ),

                          const SizedBox(width: 12),

                          const Expanded(
                            child: Text(
                              'Smart Saving Planner',
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      Text(
                        totalIncome <= 0
                            ? 'Belum ada pemasukan untuk direncanakan. '
                                'Catat pemasukanmu terlebih dahulu '
                                'untuk mendapatkan rekomendasi menabung.'
                            : isNegativeBalance
                            ? 'Prioritaskan memperbaiki kondisi keuanganmu '
                                'dulu sebelum menabung.'
                            : 'Kamu masih punya uang yang bisa ditabung.',
                        style: const TextStyle(color: Colors.grey, height: 1.5),
                      ),

                      const SizedBox(height: 16),

                      if (totalIncome > 0 && !isNegativeBalance)
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            onPressed: () async {
                              await Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) =>
                                      SavingPlannerPage(user: widget.user),
                                ),
                              );

                              await loadTransactions();
                            },
                            icon: const Icon(Icons.arrow_forward),
                            label: const Text('Lihat Rencana Menabung'),
                          ),
                        ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // TRANSAKSI TERBARU
              // ==================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,

                children: [
                  const Text(
                    'Transaksi Terbaru',

                    style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                  ),

                  if (recentTransactions.isNotEmpty)
                    Text(
                      '${recentTransactions.length} transaksi',

                      style: const TextStyle(color: Colors.grey),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              // ==================================================
              // EMPTY STATE / TRANSACTION LIST
              // ==================================================
              if (recentTransactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 20),

                  child: Center(
                    child: Text(
                      'Belum ada transaksi.',

                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ...recentTransactions.take(5).map((transaction) {
                  return TransactionCard(
                    transaction: transaction,
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              TransactionDetailPage(transaction: transaction),
                        ),
                      );

                      if (result == true) {
                        await loadTransactions();
                      }
                    },
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}