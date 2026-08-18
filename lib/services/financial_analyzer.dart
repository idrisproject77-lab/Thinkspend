import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/goal_model.dart';
import 'package:thinkspend/models/transaction_model.dart';

class FinancialSummary {
  final double income;
  final double expense;
  final double balance;

  final int transactionCount;

  final String? topExpenseCategory;
  final double topExpenseAmount;

  final List<GoalModel> goals;

  // ============================================================
  // DATA PERIOD
  // ============================================================

  final int dataDays;

  // ============================================================
  // DAILY SPENDING
  // ============================================================

  final double averageDailyExpense;

  // ============================================================
  // MONTHLY PROJECTION
  // ============================================================

  final double projectedMonthlyExpense;

  // ============================================================
  // BUDGET
  // ============================================================

  final double monthlyBudget;

  final double budgetUsagePercentage;

  // ============================================================
  // HEALTH
  // ============================================================

  final String healthStatus;

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
      'healthStatus': healthStatus,
      'monthlyBudget': monthlyBudget,
    };
  }
}

/// Engine analisis keuangan untuk menghitung metrik, proyeksi, dan status kesehatan finansial.
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
  /// 6. Mengevaluasi status kesehatan finansial berdasarkan aturan multi-kondisi.
  static Future<FinancialSummary> analyze(int userId) async {
    // ----------------------------------------------------------
    // GET USER
    // ----------------------------------------------------------

    final users = await _database.getUsers();

    final user = users.where((item) => item.id == userId);

    if (user.isEmpty) {
      throw Exception('User tidak ditemukan.');
    }

    final currentUser = user.first;

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
    //
    // Kita tidak langsung menganggap transaksi
    // hari pertama sebagai pola bulanan.
    //
    // Proyeksi baru dianggap meaningful jika
    // data sudah tersedia minimal 3 hari.
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
    // HEALTH STATUS
    // ==========================================================

    final healthStatus = _calculateHealthStatus(
      dataDays: dataDays,
      income: income,
      expense: expense,
      projectedExpense: projectedMonthlyExpense,
      monthlyBudget: monthlyBudget,
    );

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
      healthStatus: healthStatus,
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
  // HEALTH STATUS
  // ============================================================

  /// Menentukan status kesehatan finansial berdasarkan matriks prioritas kondisi:
  /// - 'Belum cukup data': jika data kosong atau rentang hari aktif < 3 hari.
  /// - 'Berisiko': jika total pengeluaran aktual > pemasukan, atau proyeksi bulanan melebihi budget / >80% pemasukan.
  /// - 'Perlu diperhatikan': jika proyeksi pengeluaran 80-100% dari budget, atau 60-80% dari pemasukan.
  /// - 'Cukup sehat': jika proyeksi pengeluaran < 80% budget atau < 60% pemasukan.
  static String _calculateHealthStatus({
    required int dataDays,
    required double income,
    required double expense,
    required double projectedExpense,
    required double monthlyBudget,
  }) {
    // ----------------------------------------------------------
    // BELUM ADA DATA
    // ----------------------------------------------------------

    if (income <= 0 && expense <= 0) {
      return 'Belum cukup data';
    }

    // ----------------------------------------------------------
    // DATA MASIH TERLALU SEDIKIT
    // ----------------------------------------------------------

    if (dataDays < 3) {
      return 'Belum cukup data';
    }

    // ----------------------------------------------------------
    // PENGELUARAN AKTUAL SUDAH MELEBIHI PEMASUKAN
    // ----------------------------------------------------------

    if (income > 0 && expense > income) {
      return 'Berisiko';
    }
    // ----------------------------------------------------------
    // JIKA USER PUNYA MONTHLY BUDGET PRIORITASKAN BUDGET  
    // ----------------------------------------------------------

    if (monthlyBudget > 0) {
      final budgetRatio = projectedExpense / monthlyBudget;

      if (budgetRatio > 1.0) {
        return 'Berisiko';
      }

      if (budgetRatio >= 0.80) {
        return 'Perlu diperhatikan';
      }

      return 'Cukup sehat';
    }

    // ----------------------------------------------------------
    // JIKA BELUM ADA BUDGET
    //
    // GUNAKAN INCOME SEBAGAI REFERENSI
    // ----------------------------------------------------------

    if (income > 0 && projectedExpense > 0) {
      final incomeRatio = projectedExpense / income;

      // >100% pemasukan
      if (incomeRatio > 1.0) {
        return 'Berisiko';
      }

      // 80–100% pemasukan
      if (incomeRatio >= 0.80) {
        return 'Berisiko';
      }

      // 60–80% pemasukan
      if (incomeRatio >= 0.60) {
        return 'Perlu diperhatikan';
      }

      // <60%
      return 'Cukup sehat';
    }

    return 'Belum cukup data';
  }

  // ============================================================
  // IS INCOME
  // ============================================================

  static bool _isIncome(TransactionModel transaction) {
    final type = transaction.type.toLowerCase().trim();

    return type == 'income' || type == 'pemasukan';
  }

  // ============================================================
  // IS EXPENSE
  // ============================================================

  static bool _isExpense(TransactionModel transaction) {
    final type = transaction.type.toLowerCase().trim();

    return type == 'expense' || type == 'pengeluaran';
  }

  // ============================================================
  // TOTAL GOAL TARGET
  // ============================================================

  static double totalGoalTarget(List<GoalModel> goals) {
    double total = 0;

    for (final goal in goals) {
      total += goal.targetAmount;
    }

    return total;
  }

  // ============================================================
  // TOTAL CURRENT GOAL
  // ============================================================

  static double totalGoalCurrent(List<GoalModel> goals) {
    double total = 0;

    for (final goal in goals) {
      total += goal.currentAmount;
    }

    return total;
  }

  // ============================================================
  // GOAL PROGRESS
  // ============================================================

  static double goalProgress(GoalModel goal) {
    if (goal.targetAmount <= 0) {
      return 0;
    }

    final progress = goal.currentAmount / goal.targetAmount;

    if (progress < 0) {
      return 0;
    }

    if (progress > 1) {
      return 1;
    }

    return progress;
  }

  // ============================================================
  // PUBLIC HEALTH STATUS
  // ============================================================

  static String financialStatus(FinancialSummary summary) {
    return summary.healthStatus;
  }

  static String healthExplanation(
  FinancialSummary summary,
) {
  if (summary.healthStatus ==
      'Belum cukup data') {
    return 'Data masih terbatas. '
        'ThinkSpend membutuhkan '
        'setidaknya 3 hari data untuk '
        'membaca pola pengeluaran.';
  }

  if (summary.income <= 0) {
    return 'Belum ada pemasukan yang '
        'cukup untuk menjadi acuan '
        'analisis.';
  }

  final ratio =
      summary.projectedMonthlyExpense /
          summary.income;

  final percentage =
      (ratio * 100).toStringAsFixed(1);

  if (summary.healthStatus ==
      'Berisiko') {
    if (ratio > 1) {
      return 'Jika pola pengeluaran '
          'saat ini berlanjut, '
          'pengeluaranmu berpotensi '
          'melebihi pemasukan.';
    }

    return 'Proyeksi pengeluaranmu '
        'sudah mendekati batas '
        'pemasukan. Perlu mengurangi '
        'pengeluaran tertentu.';
  }

  if (summary.healthStatus ==
      'Perlu diperhatikan') {
    return 'Proyeksi pengeluaranmu '
        'menggunakan sekitar '
        '$percentage% dari pemasukan. '
        'Pola ini masih perlu dipantau.';
  }

  if (summary.healthStatus ==
      'Cukup sehat') {
    return 'Proyeksi pengeluaranmu '
        'masih relatif terkendali '
        'dibandingkan pemasukan.';
  }

  return '';
}

}
