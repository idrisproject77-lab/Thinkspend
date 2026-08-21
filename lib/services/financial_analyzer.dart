import 'package:flutter/material.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/goal_model.dart';
import 'package:thinkspend/models/transaction_model.dart';

// ============================================================
// HEALTH SCORE BREAKDOWN MODEL
// ============================================================

/// Model rincian penilaian kesehatan finansial dari 4 pilar utama:
/// 1. Cash Flow (Maks 40 poin) -> Arus kas & rasio pengeluaran terhadap pemasukan.
/// 2. Pengeluaran (Maks 25 poin) -> Kepatuhan terhadap budget bulanan atau pemasukan.
/// 3. Tabungan (Maks 20 poin) -> Potensi dan rasio saldo yang dapat ditabung.
/// 4. Konsistensi (Maks 15 poin) -> Kedisiplinan dan frekuensi pencatatan transaksi harian.
class HealthScoreBreakdown {
  final int cashFlowScore;
  final int expenseScore;
  final int savingScore;
  final int consistencyScore;

  final int maxCashFlow;
  final int maxExpense;
  final int maxSaving;
  final int maxConsistency;

  final String cashFlowInsight;
  final String expenseInsight;
  final String savingInsight;
  final String consistencyInsight;

  const HealthScoreBreakdown({
    required this.cashFlowScore,
    required this.expenseScore,
    required this.savingScore,
    required this.consistencyScore,
    this.maxCashFlow = 40,
    this.maxExpense = 25,
    this.maxSaving = 20,
    this.maxConsistency = 15,
    required this.cashFlowInsight,
    required this.expenseInsight,
    required this.savingInsight,
    required this.consistencyInsight,
  });

  int get totalScore =>
      (cashFlowScore + expenseScore + savingScore + consistencyScore).clamp(0, 100);
}

// ============================================================
// FINANCIAL SUMMARY MODEL
// ============================================================

/// Model ringkasan kondisi finansial lengkap pengguna.
///
/// Menggabungkan pemasukan, pengeluaran, saldo, kategori teratas,
/// rata-rata harian, proyeksi 30 hari, anggaran, serta skor kesehatan finansial.
class FinancialSummary {
  final double income;
  final double expense;
  final double balance;

  final int transactionCount;

  final String? topExpenseCategory;
  final double topExpenseAmount;

  final List<GoalModel> goals;

  // DATA PERIOD
  final int dataDays;

  // DAILY SPENDING
  final double averageDailyExpense;

  // MONTHLY PROJECTION
  final double projectedMonthlyExpense;

  // BUDGET
  final double monthlyBudget;
  final double budgetUsagePercentage;

  // HEALTH
  final double? healthScore;
  final String healthStatus;
  final HealthScoreBreakdown? healthBreakdown;

  const FinancialSummary({
    required this.income,
    required this.expense,
    required this.balance,
    required this.transactionCount,
    required this.topExpenseCategory,
    required this.topExpenseAmount,
    required this.goals,
    required this.dataDays,
    required this.averageDailyExpense,
    required this.projectedMonthlyExpense,
    required this.monthlyBudget,
    required this.budgetUsagePercentage,
    required this.healthStatus,
    this.healthScore,
    this.healthBreakdown,
  });

  Map<String, dynamic> toMap() {
    final projectedRatio = income > 0 ? (projectedMonthlyExpense / income) * 100 : 0.0;
    return {
      'income': income,
      'expense': expense,
      'balance': balance,
      'transactionCount': transactionCount,
      'dataDays': dataDays,
      'averageDailyExpense': averageDailyExpense,
      'projectedMonthlyExpense': projectedMonthlyExpense,
      'projectedRatio': double.parse(projectedRatio.toStringAsFixed(1)),
      'topExpenseCategory': topExpenseCategory ?? 'Belum tersedia',
      'topExpenseAmount': topExpenseAmount,
      'healthScore': healthScore,
      'healthStatus': healthStatus,
      'monthlyBudget': monthlyBudget,
    };
  }
}

/// Engine analisis keuangan untuk menghitung metrik, proyeksi, dan status kesehatan finansial (Single Source of Truth).
class FinancialAnalyzer {
  static final DatabaseHelper _database = DatabaseHelper.instance;

  // ============================================================
  // ANALYZE USER
  // ============================================================

  /// Alur utama agregasi analitik finansial user:
  /// 1. Mengambil data profil user, transaksi, dan target tabungan dari SQLite.
  /// 2. Mengakumulasi total pemasukan, pengeluaran, dan total per kategori.
  /// 3. Menghitung jumlah hari aktif transaksi unik (dataDays).
  /// 4. Menghitung rata-rata pengeluaran harian dan proyeksi 30 hari (jika dataDays >= 3).
  /// 5. Mengidentifikasi kategori pengeluaran tertinggi dan rasio penggunaan budget bulanan.
  /// 6. Mengevaluasi skor dan status kesehatan finansial berdasarkan Single Source of Truth.
  static Future<FinancialSummary> analyze(int userId) async {
    // ----------------------------------------------------------
    // GET USER
    // ----------------------------------------------------------

    final currentUser = await _database.getUserById(userId);

    if (currentUser == null) {
      throw Exception('User tidak ditemukan.');
    }

    // ----------------------------------------------------------
    // GET TRANSACTIONS
    // ----------------------------------------------------------

    final transactions = await _database.getTransactions(userId);

    // ----------------------------------------------------------
    // GET GOALS
    // ----------------------------------------------------------

    final goals = await _database.getGoals(userId);

    // ==========================================================
    // TOTAL
    // ==========================================================

    double transactionIncome = 0;
    double expense = 0;

    final Map<String, double> categoryTotals = {};

    for (final transaction in transactions) {
      if (_isIncome(transaction)) {
        transactionIncome += transaction.amount;
      }

      if (_isExpense(transaction)) {
        expense += transaction.amount;

        categoryTotals.update(
          transaction.category,
          (value) => value + transaction.amount,
          ifAbsent: () => transaction.amount,
        );
      }
    }

    // ==========================================================
    // INCOME
    // ==========================================================
    //
    // Jika transaksi income tersedia,
    // gunakan total income dari transaksi.
    //
    // Jika belum ada transaksi income,
    // gunakan income yang tersimpan di profile.
    // ==========================================================

    final income = transactionIncome > 0
        ? transactionIncome
        : currentUser.income;

    // ==========================================================
    // BALANCE
    // ==========================================================

    final balance = income - expense;

    // ==========================================================
    // DATA DAYS
    // ==========================================================

    final dataDays = _calculateDataDays(transactions);

    // ==========================================================
    // AVERAGE DAILY EXPENSE
    // ==========================================================

    double averageDailyExpense = 0;

    if (dataDays > 0) {
      averageDailyExpense = expense / dataDays;
    }

    // ==========================================================
    // MONTHLY PROJECTION
    // ==========================================================

    double projectedMonthlyExpense = 0;

    if (dataDays >= 3) {
      projectedMonthlyExpense = averageDailyExpense * 30;
    }

    // ==========================================================
    // TOP CATEGORY
    // ==========================================================

    String? topExpenseCategory;
    double topExpenseAmount = 0;

    if (categoryTotals.isNotEmpty) {
      final topCategory = categoryTotals.entries.reduce(
        (current, next) => next.value > current.value ? next : current,
      );

      topExpenseCategory = topCategory.key;
      topExpenseAmount = topCategory.value;
    }

    // ==========================================================
    // MONTHLY BUDGET
    // ==========================================================

    final monthlyBudget = currentUser.monthlyBudget;

    // ==========================================================
    // BUDGET USAGE
    // ==========================================================

    double budgetUsagePercentage = 0;

    if (monthlyBudget > 0) {
      budgetUsagePercentage = (projectedMonthlyExpense / monthlyBudget) * 100;
    }

    // ==========================================================
    // HEALTH BREAKDOWN & SCORE (SSOT)
    // ==========================================================

    final healthBreakdown = calculateBreakdown(
      income: income,
      expense: expense,
      monthlyBudget: monthlyBudget,
      transactions: transactions,
    );

    final healthScore = calculateHealthScore(
      income: income,
      expense: expense,
      monthlyBudget: monthlyBudget,
      transactions: transactions,
    );

    final healthStatus = getHealthStatus(healthScore);

    return FinancialSummary(
      income: income,
      expense: expense,
      balance: balance,
      transactionCount: transactions.length,
      topExpenseCategory: topExpenseCategory,
      topExpenseAmount: topExpenseAmount,
      goals: goals,
      dataDays: dataDays,
      averageDailyExpense: averageDailyExpense,
      projectedMonthlyExpense: projectedMonthlyExpense,
      monthlyBudget: monthlyBudget,
      budgetUsagePercentage: budgetUsagePercentage,
      healthScore: healthScore,
      healthStatus: healthStatus,
      healthBreakdown: healthBreakdown,
    );
  }

  // ============================================================
  // CALCULATE DATA DAYS
  // ============================================================

  /// Menghitung jumlah hari aktif pencatatan transaksi unik.
  /// Tanggal dinormalisasi ke format 'YYYY-MM-DD' dan disimpan dalam Set untuk menghindari duplikasi hari.
  static int _calculateDataDays(List<TransactionModel> transactions) {
    if (transactions.isEmpty) {
      return 0;
    }

    final Set<String> uniqueDates = {};

    for (final transaction in transactions) {
      final rawDate = transaction.date.trim();

      if (rawDate.isEmpty) {
        continue;
      }

      try {
        final parsedDate = DateTime.parse(rawDate);

        final normalizedDate =
            '${parsedDate.year.toString().padLeft(4, '0')}-'
            '${parsedDate.month.toString().padLeft(2, '0')}-'
            '${parsedDate.day.toString().padLeft(2, '0')}';

        uniqueDates.add(normalizedDate);
      } catch (_) {
        final normalizedDate = rawDate.split(' ').first;
        uniqueDates.add(normalizedDate);
      }
    }

    return uniqueDates.length;
  }

  // ============================================================
  // SINGLE SOURCE OF TRUTH: BREAKDOWN CALCULATION
  // ============================================================

  static HealthScoreBreakdown calculateBreakdown({
    required double income,
    required double expense,
    required double monthlyBudget,
    required List<TransactionModel> transactions,
  }) {
    // ----------------------------------------------------------
    // 1. CASH FLOW (MAKS 40)
    // ----------------------------------------------------------
    int cashFlowScore = 0;
    String cashFlowInsight = '';

    if (income <= 0) {
      cashFlowScore = 0;
      cashFlowInsight =
          'Tambahkan transaksi pemasukan untuk mulai menganalisis kondisi keuanganmu.';
    } else if (expense <= 0) {
      cashFlowScore = 40;
      cashFlowInsight =
          'Belum ada pengeluaran yang tercatat. Arus kas saat ini surplus penuh.';
    } else {
      final ratio = expense / income;
      if (ratio <= 0.30) {
        cashFlowScore = 40;
      } else if (ratio <= 0.50) {
        cashFlowScore = 35;
      } else if (ratio <= 0.70) {
        cashFlowScore = 28;
      } else if (ratio <= 0.85) {
        cashFlowScore = 20;
      } else if (ratio < 1.0) {
        cashFlowScore = 10;
      } else {
        cashFlowScore = 0;
      }

      if (expense < income) {
        cashFlowInsight = 'Pemasukanmu masih lebih besar daripada pengeluaran.';
      } else if (expense == income) {
        cashFlowInsight =
            'Pengeluaranmu sudah sama dengan pemasukan. Sebaiknya mulai mengurangi pengeluaran.';
      } else {
        cashFlowInsight =
            'Pengeluaranmu sudah melebihi pemasukan. Kondisi ini perlu segera diperhatikan.';
      }
    }

    // ----------------------------------------------------------
    // 2. PENGELUARAN (MAKS 25)
    // ----------------------------------------------------------
    int expenseScore = 0;
    String expenseInsight = '';

    if (monthlyBudget > 0) {
      final budgetRatio = expense / monthlyBudget;
      if (budgetRatio <= 0.60) {
        expenseScore = 25;
      } else if (budgetRatio <= 0.80) {
        expenseScore = 20;
      } else if (budgetRatio <= 1.00) {
        expenseScore = 12;
      } else {
        expenseScore = 0;
      }

      if (budgetRatio <= 0.80) {
        expenseInsight =
            'Pengeluaranmu masih terkendali dalam batas anggaran bulanan.';
      } else if (budgetRatio <= 1.00) {
        expenseInsight =
            'Pengeluaranmu sudah mendekati batas anggaran bulanan.';
      } else {
        expenseInsight =
            'Pengeluaranmu sudah melebihi anggaran bulanan yang ditetapkan.';
      }
    } else {
      if (income <= 0 && expense <= 0) {
        expenseScore = 0;
        expenseInsight = 'Belum cukup data untuk menganalisis pengeluaran.';
      } else if (income <= 0) {
        expenseScore = 0;
        expenseInsight = 'Pengeluaran tercatat tanpa adanya pemasukan acuan.';
      } else if (expense <= 0) {
        expenseScore = 25;
        expenseInsight = 'Belum ada pengeluaran yang tercatat.';
      } else {
        final spendingRatio = expense / income;
        if (spendingRatio <= 0.30) {
          expenseScore = 25;
        } else if (spendingRatio <= 0.50) {
          expenseScore = 22;
        } else if (spendingRatio <= 0.70) {
          expenseScore = 18;
        } else if (spendingRatio <= 0.85) {
          expenseScore = 12;
        } else if (spendingRatio < 1.0) {
          expenseScore = 6;
        } else {
          expenseScore = 0;
        }

        if (spendingRatio <= 0.30) {
          expenseInsight = 'Pengeluaranmu masih sangat terkendali.';
        } else if (spendingRatio <= 0.70) {
          expenseInsight = 'Pengeluaranmu masih terkendali.';
        } else if (spendingRatio < 1.0) {
          expenseInsight = 'Pengeluaranmu mulai mendekati pemasukan.';
        } else {
          expenseInsight = 'Pengeluaranmu sudah melebihi pemasukan.';
        }
      }
    }

    // ----------------------------------------------------------
    // 3. TABUNGAN (MAKS 20)
    // ----------------------------------------------------------
    int savingScore = 0;
    String savingInsight = '';

    if (income <= 0) {
      savingScore = 0;
      savingInsight = 'Belum ada pemasukan yang bisa disisihkan.';
    } else {
      final available = income - expense;
      if (available <= 0) {
        savingScore = 0;
        savingInsight = 'Belum ada uang yang tersisa untuk ditabung.';
      } else {
        final savingRatio = available / income;
        if (savingRatio >= 0.40) {
          savingScore = 20;
        } else if (savingRatio >= 0.30) {
          savingScore = 17;
        } else if (savingRatio >= 0.20) {
          savingScore = 14;
        } else if (savingRatio >= 0.10) {
          savingScore = 10;
        } else {
          savingScore = 5;
        }

        if (savingRatio >= 0.30) {
          savingInsight =
              'Potensi tabunganmu sangat baik, lebih dari 30% pemasukan tersisa.';
        } else {
          savingInsight =
              'Kamu masih punya sisa saldo yang bisa dialokasikan untuk tabungan.';
        }
      }
    }

    // ----------------------------------------------------------
    // 4. KONSISTENSI (MAKS 15)
    // ----------------------------------------------------------
    int consistencyScore = 0;
    String consistencyInsight = '';

    if (transactions.isEmpty) {
      consistencyScore = 0;
      consistencyInsight = 'Belum ada transaksi yang tercatat.';
    } else {
      final dataDays = _calculateDataDays(transactions);
      final count = transactions.length;

      if (dataDays >= 7 || count >= 15) {
        consistencyScore = 15;
        consistencyInsight =
            'Kamu sangat konsisten dan rutin mencatat transaksi keuangan.';
      } else if (dataDays >= 5 || count >= 10) {
        consistencyScore = 10;
        consistencyInsight =
            'Kamu cukup konsisten mencatat transaksi keuangan.';
      } else if (dataDays >= 3 || count >= 5) {
        consistencyScore = 6;
        consistencyInsight =
            'Kamu mulai rutin mencatat transaksi. Coba pertahankan kebiasaan ini.';
      } else {
        consistencyScore = 3;
        consistencyInsight =
            'Catatan transaksi masih awal. Rutin mencatat transaksi setiap hari untuk hasil akurat.';
      }
    }

    return HealthScoreBreakdown(
      cashFlowScore: cashFlowScore,
      expenseScore: expenseScore,
      savingScore: savingScore,
      consistencyScore: consistencyScore,
      cashFlowInsight: cashFlowInsight,
      expenseInsight: expenseInsight,
      savingInsight: savingInsight,
      consistencyInsight: consistencyInsight,
    );
  }

  // ============================================================
  // SINGLE SOURCE OF TRUTH: HEALTH SCORE CALCULATION
  // ============================================================

  static double? calculateHealthScore({
    required double income,
    required double expense,
    required double monthlyBudget,
    required List<TransactionModel> transactions,
  }) {
    if (transactions.isEmpty && income <= 0 && expense <= 0) {
      return null;
    }

    if (income <= 0) {
      return null;
    }

    final breakdown = calculateBreakdown(
      income: income,
      expense: expense,
      monthlyBudget: monthlyBudget,
      transactions: transactions,
    );

    return breakdown.totalScore.toDouble();
  }

  // ============================================================
  // SINGLE SOURCE OF TRUTH: STATUS HEALTH SCORE
  // ============================================================

  static String getHealthStatus(double? score) {
    if (score == null) {
      return 'Belum Ada Data';
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
  // SINGLE SOURCE OF TRUTH: ICON HEALTH SCORE
  // ============================================================

  static IconData getHealthIcon(double? score) {
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
  // SINGLE SOURCE OF TRUTH: COLOR HEALTH SCORE
  // ============================================================

  static Color getHealthColor(double? score) {
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
  // SINGLE SOURCE OF TRUTH: DESKRIPSI HEALTH SCORE
  // ============================================================

  static String getHealthDescription(
    double? score, {
    required List<TransactionModel> transactions,
    double projectedExpense = 0,
    double income = 0,
  }) {
    if (score == null) {
      if (transactions.isEmpty) {
        return 'Belum ada data transaksi. '
            'Mulai catat pemasukan dan pengeluaranmu '
            'untuk melihat kesehatan keuangan.';
      }

      return 'Data keuanganmu belum memiliki pemasukan yang tercatat. '
          'Catat pemasukanmu agar ThinkSpend dapat mengevaluasi kesehatan finansial.';
    }

    final dataDays = _calculateDataDays(transactions);
    final dataWarning = dataDays < 3 && transactions.length < 5
        ? ' (Catatan masih awal, catat minimal 3 hari untuk analisis tren yang lebih akurat)'
        : '';

    if (score >= 80) {
      return 'Kondisi keuanganmu sangat baik. '
          'Arus kas positif dan pengeluaran terkendali dengan baik.$dataWarning';
    }

    if (score >= 60) {
      return 'Kondisi keuanganmu cukup sehat, '
          'tetapi masih ada ruang untuk mengoptimalkan anggaran dan meningkatkan tabungan.$dataWarning';
    }

    if (score >= 40) {
      return 'Kondisi keuanganmu perlu perhatian. '
          'Pengeluaran mendekati pemasukan sehingga ruang tabungan menipis.$dataWarning';
    }

    return 'Kondisi keuanganmu perlu perbaikan segera. '
        'Pengeluaran sangat tinggi atau melebihi pemasukan yang ada.$dataWarning';
  }

  // ============================================================
  // IS INCOME / EXPENSE
  // ============================================================

  static bool _isIncome(TransactionModel transaction) {
    final type = transaction.type.toLowerCase().trim();
    return type == 'income' || type == 'pemasukan';
  }

  static bool _isExpense(TransactionModel transaction) {
    final type = transaction.type.toLowerCase().trim();
    return type == 'expense' || type == 'pengeluaran';
  }

  // ============================================================
  // GOAL UTILITIES
  // ============================================================

  static double totalGoalTarget(List<GoalModel> goals) {
    double total = 0;
    for (final goal in goals) {
      total += goal.targetAmount;
    }
    return total;
  }

  static double totalGoalCurrent(List<GoalModel> goals) {
    double total = 0;
    for (final goal in goals) {
      total += goal.currentAmount;
    }
    return total;
  }

  static double goalProgress(GoalModel goal) {
    if (goal.targetAmount <= 0) {
      return 0;
    }
    final progress = goal.currentAmount / goal.targetAmount;
    if (progress < 0) return 0;
    if (progress > 1) return 1;
    return progress;
  }

  // ============================================================
  // PUBLIC HEALTH STATUS & EXPLANATION
  // ============================================================

  static String financialStatus(FinancialSummary summary) {
    return summary.healthStatus;
  }

  static String healthExplanation(FinancialSummary summary) {
    if (summary.healthStatus == 'Belum Ada Data' || summary.healthScore == null) {
      return 'Data masih terbatas. '
          'ThinkSpend membutuhkan setidaknya 3 hari data untuk '
          'membaca pola pengeluaran secara komprehensif.';
    }

    return getHealthDescription(
      summary.healthScore,
      transactions: const [],
      projectedExpense: summary.projectedMonthlyExpense,
      income: summary.income,
    );
  }
}
