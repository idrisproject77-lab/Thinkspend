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
import 'package:thinkspend/services/theme_service.dart';
import 'package:thinkspend/services/privacy_service.dart';

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
        totalIncome - totalExpense;

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
    final surface = AppColors.surface(context);
    final border = AppColors.border(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);
    final mutedText = AppColors.muted(context);
    const primaryBlue = AppColors.primaryBlue;
    const incomeGreen = AppColors.green;
    const expenseRed = AppColors.red;

    final balance = totalIncome - totalExpense;

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
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: loadTransactions,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HEADER GREETING + PROFILE AVATAR
              // ==================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Halo, ${currentUser.name} 👋',
                          style: TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Bagaimana kondisi keuanganmu hari ini?',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  InkWell(
                    borderRadius: BorderRadius.circular(24),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ProfilePage(
                            user: currentUser,
                            onLogout: widget.onLogout,
                          ),
                        ),
                      );

                      if (result is UserModel && mounted) {
                        setState(() {
                          currentUser = result;
                        });
                      }
                    },
                    child: CircleAvatar(
                      radius: 22,
                      backgroundColor:
                          primaryBlue.withValues(alpha: 0.1),
                      child: Text(
                        currentUser.name.isNotEmpty
                            ? currentUser.name[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: primaryBlue,
                        ),
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // ==================================================
              // BALANCE & FINANCIAL SUMMARY CARD
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total Saldo',
                          style: TextStyle(
                            fontSize: 13,
                            color: textSecondary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        IconButton(
                          onPressed: () {
                            PrivacyService.instance.toggleVisibility();
                          },
                          icon: Icon(
                            PrivacyService.instance.isAmountVisible
                                ? Icons.visibility_rounded
                                : Icons.visibility_off_rounded,
                            size: 20,
                            color: textSecondary,
                          ),
                          padding: EdgeInsets.zero,
                          constraints: const BoxConstraints(),
                          tooltip: PrivacyService.instance.isAmountVisible
                              ? 'Sembunyikan Nominal'
                              : 'Tampilkan Nominal',
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 200),
                      transitionBuilder: (child, animation) =>
                          FadeTransition(opacity: animation, child: child),
                      child: Text(
                        formatRupiah(balance),
                        key: ValueKey<bool>(
                          PrivacyService.instance.isAmountVisible,
                        ),
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: isNegativeBalance
                              ? expenseRed
                              : textPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Divider(height: 1, color: border),
                    const SizedBox(height: 14),
                    Row(
                      children: [
                        Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    incomeGreen.withValues(alpha: 0.12),
                                child: const Icon(
                                  Icons.arrow_downward,
                                  size: 16,
                                  color: incomeGreen,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pemasukan',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      formatRupiah(totalIncome),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: incomeGreen,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          height: 32,
                          width: 1,
                          color: border,
                          margin: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                        Expanded(
                          child: Row(
                            children: [
                              CircleAvatar(
                                radius: 16,
                                backgroundColor:
                                    expenseRed.withValues(alpha: 0.12),
                                child: const Icon(
                                  Icons.arrow_upward,
                                  size: 16,
                                  color: expenseRed,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Pengeluaran',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: textSecondary,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      formatRupiah(totalExpense),
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.bold,
                                        color: expenseRed,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // FINANCIAL HEALTH SCORE
              // ==================================================
              Container(
                width: double.infinity,
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border, width: 1),
                ),
                child: InkWell(
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
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  radius: 16,
                                  backgroundColor:
                                      healthColor.withValues(alpha: 0.12),
                                  child: Icon(
                                    healthIcon,
                                    size: 18,
                                    color: healthColor,
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Financial Health',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: textPrimary,
                                  ),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: healthColor.withValues(alpha: 0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                healthStatus,
                                style: TextStyle(
                                  color: healthColor,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 14),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Text(
                              healthScore != null
                                  ? healthScore.toStringAsFixed(0)
                                  : '—',
                              style: TextStyle(
                                fontSize: 32,
                                fontWeight: FontWeight.bold,
                                color: healthColor,
                              ),
                            ),
                            Text(
                              ' / 100',
                              style: TextStyle(
                                fontSize: 14,
                                color: mutedText,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Text(
                                healthDescription,
                                style: TextStyle(
                                  color: textSecondary,
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // THINKSPEND INSIGHT
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor:
                              primaryBlue.withValues(alpha: 0.1),
                          child: const Icon(
                            Icons.psychology_outlined,
                            size: 18,
                            color: primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'ThinkSpend Insight',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      spendingInsight,
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                        height: 1.5,
                      ),
                    ),
                    if (impulseInsight != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: const Color(0xFFEA580C).withValues(alpha: 0.08),
                        ),
                        child: Text(
                          impulseInsight,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: Color(0xFFEA580C),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                    if (budgetInsight != null) ...[
                      const SizedBox(height: 10),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(10),
                          color: primaryBlue.withValues(
                            alpha: 0.06,
                          ),
                        ),
                        child: Text(
                          budgetInsight,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1.4,
                            color: primaryBlue,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 16),

              // ==================================================
              // SMART SAVING PLANNER
              // ==================================================
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: surface,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: border, width: 1),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 16,
                          backgroundColor: incomeGreen.withValues(alpha: 0.12),
                          child: const Icon(
                            Icons.savings_outlined,
                            size: 18,
                            color: incomeGreen,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Smart Saving Planner',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Text(
                      totalIncome <= 0
                          ? 'Belum ada pemasukan untuk direncanakan. Catat pemasukanmu terlebih dahulu untuk mendapatkan rekomendasi menabung.'
                          : isNegativeBalance
                          ? 'Prioritaskan memperbaiki kondisi keuanganmu dulu sebelum menabung.'
                          : 'Kamu masih punya alokasi dana yang bisa ditabung secara terencana.',
                      style: TextStyle(
                        fontSize: 13,
                        color: textSecondary,
                        height: 1.4,
                      ),
                    ),
                    if (totalIncome > 0 && !isNegativeBalance) ...[
                      const SizedBox(height: 12),
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          style: OutlinedButton.styleFrom(
                            foregroundColor: primaryBlue,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(10),
                            ),
                            side: BorderSide(color: border),
                            padding: const EdgeInsets.symmetric(vertical: 10),
                          ),
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
                          icon: const Icon(Icons.arrow_forward, size: 16),
                          label: const Text(
                            'Lihat Rencana Menabung',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // TRANSAKSI TERBARU
              // ==================================================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Transaksi Terbaru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  if (recentTransactions.isNotEmpty)
                    Text(
                      '${recentTransactions.length} transaksi',
                      style: TextStyle(
                        fontSize: 12,
                        color: mutedText,
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 12),

              if (recentTransactions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 32),
                  decoration: BoxDecoration(
                    color: surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: border),
                  ),
                  child: Center(
                    child: Text(
                      'Belum ada transaksi.',
                      style: TextStyle(
                        color: mutedText,
                        fontSize: 13,
                      ),
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
    ),
  );
}
}
