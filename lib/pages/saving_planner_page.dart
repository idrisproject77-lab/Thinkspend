import 'package:flutter/material.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/goal_model.dart';
import 'package:thinkspend/models/transaction_model.dart';
import 'package:thinkspend/models/user_model.dart';

class SavingPlannerPage extends StatefulWidget {
  final UserModel user;

  const SavingPlannerPage({super.key, required this.user});

  @override
  State<SavingPlannerPage> createState() => _SavingPlannerPageState();
}

class _SavingPlannerPageState extends State<SavingPlannerPage> {
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
  // UANG TERSEDIA
  // ============================================================

  double get availableMoney {
    final result = totalIncome - totalExpense;

    return result > 0 ? result : 0;
  }

  // ============================================================
  // REKOMENDASI TABUNGAN
  //
  // Untuk sementara menggunakan 40% dari uang tersedia.
  // ============================================================

  double get recommendedSaving {
    if (availableMoney <= 0) {
      return 0;
    }

    return availableMoney * 0.40;
  }

  // ============================================================
  // FORMAT RUPIAH
  // ============================================================

  String formatRupiah(double amount) {
    final value = amount.round().toString();

    final formatted = value.replaceAllMapped(
      RegExp(r'\B(?=(\d{3})+(?!\d))'),
      (match) => '.',
    );

    return 'Rp $formatted';
  }

  // ============================================================
  // TARGET PRIORITAS
  // ============================================================

  GoalModel? get nearestGoal {
    if (goals.isEmpty) {
      return null;
    }

    GoalModel? selectedGoal;

    for (final goal in goals) {
      if (goal.targetAmount <= goal.currentAmount) {
        continue;
      }

      if (selectedGoal == null) {
        selectedGoal = goal;
        continue;
      }

      if (goal.priority == 'High' && selectedGoal.priority != 'High') {
        selectedGoal = goal;
        continue;
      }

      if (goal.deadline != null && selectedGoal.deadline != null) {
        if (goal.deadline!.compareTo(selectedGoal.deadline!) < 0) {
          selectedGoal = goal;
        }
      }
    }

    return selectedGoal;
  }

  // ============================================================
  // SISA TARGET
  // ============================================================

  double getRemainingGoal(GoalModel goal) {
    final remaining = goal.targetAmount - goal.currentAmount;

    return remaining > 0 ? remaining : 0;
  }

  // ============================================================
  // HITUNG SISA BULAN
  // ============================================================

  int calculateRemainingMonths(String? deadline) {
    if (deadline == null || deadline.trim().isEmpty) {
      return 0;
    }

    final parsedDate = DateTime.tryParse(deadline);

    if (parsedDate == null) {
      return 0;
    }

    final now = DateTime.now();

    if (parsedDate.isBefore(now)) {
      return 0;
    }

    int months =
        (parsedDate.year - now.year) * 12 + parsedDate.month - now.month;

    // Jika masih ada sisa hari di bulan deadline,
    // kita hitung sebagai satu bulan tambahan.
    if (parsedDate.day > now.day) {
      months++;
    }

    if (months <= 0) {
      return 1;
    }

    return months;
  }

  // ============================================================
  // KEBUTUHAN TABUNGAN PER BULAN
  // ============================================================

  double calculateRequiredMonthlySaving(GoalModel goal) {
    final remaining = getRemainingGoal(goal);

    if (remaining <= 0) {
      return 0;
    }

    // Jika tidak ada deadline,
    // kebutuhan per bulan tidak dapat dihitung.
    if (goal.deadline == null || goal.deadline!.trim().isEmpty) {
      return 0;
    }

    final months = calculateRemainingMonths(goal.deadline);

    if (months <= 0) {
      return remaining;
    }

    return remaining / months;
  }

  // ============================================================
  // STATUS TARGET
  // ============================================================

  String getGoalStatus(GoalModel goal) {
    final remaining = getRemainingGoal(goal);

    // Target memang sudah selesai.
    if (remaining <= 0) {
      return 'Target sudah tercapai';
    }

    // Tidak ada deadline.
    // Selama masih ada kemampuan menabung,
    // target dianggap realistis tanpa menentukan
    // waktu pencapaian.
    if (goal.deadline == null || goal.deadline!.trim().isEmpty) {
      if (recommendedSaving > 0) {
        return 'Target Realistis';
      }

      return 'Belum dapat dicapai';
    }

    final required = calculateRequiredMonthlySaving(goal);

    if (recommendedSaving <= 0) {
      return 'Belum dapat dicapai';
    }

    if (recommendedSaving >= required) {
      return 'Target Realistis';
    }

    return 'Perlu Penyesuaian';
  }

  // ============================================================
  // WARNA STATUS TARGET
  // ============================================================

  Color getGoalStatusColor(GoalModel goal) {
    final status = getGoalStatus(goal);

    if (status == 'Target Realistis') {
      return Colors.green;
    }

    if (status == 'Perlu Penyesuaian') {
      return Colors.orange;
    }

    if (status == 'Target sudah tercapai') {
      return Colors.blue;
    }

    return Colors.red;
  }

  // ============================================================
  // SELISIH KEMAMPUAN TABUNGAN
  // ============================================================

  double calculateSavingDifference(GoalModel goal) {
    final required = calculateRequiredMonthlySaving(goal);

    final difference = recommendedSaving - required;

    return difference;
  }

  // ============================================================
  // PESAN REKOMENDASI
  // ============================================================

  String getGoalRecommendation(GoalModel goal) {
    final remaining = getRemainingGoal(goal);

    if (remaining <= 0) {
      return '🎉 Target ini sudah tercapai. '
          'Kamu bisa mulai merencanakan target berikutnya.';
    }

    if (recommendedSaving <= 0) {
      return '⚠️ Saat ini belum ada uang yang '
          'cukup tersedia untuk dialokasikan '
          'ke target. Coba evaluasi pengeluaranmu.';
    }

    // ============================================================
    // TARGET TANPA DEADLINE
    // ============================================================

    if (goal.deadline == null || goal.deadline!.trim().isEmpty) {
      return '🟢 Target ini masih berada dalam '
          'jangkauan kemampuan keuanganmu. '
          'Kamu memiliki kemampuan menabung sekitar '
          '${formatRupiah(recommendedSaving)} '
          'per bulan untuk mencapai target ini.';
    }

    // ============================================================
    // TARGET DENGAN DEADLINE
    // ============================================================

    final required = calculateRequiredMonthlySaving(goal);

    final difference = recommendedSaving - required;

    if (difference >= 0) {
      return '🟢 Dengan kemampuan menabung saat ini, '
          'kamu berpotensi mencapai target tepat waktu. '
          'Kamu memiliki ruang sekitar '
          '${formatRupiah(difference)} '
          'di atas kebutuhan bulanan target.';
    }

    final shortfall = difference.abs();

    return '⚠️ Target belum sesuai kemampuan.\n\n'
        'Target membutuhkan '
        '${formatRupiah(required)} per bulan, '
        'sedangkan kemampuanmu sekitar '
        '${formatRupiah(recommendedSaving)} per bulan.\n\n'
        'Kekurangan: '
        '${formatRupiah(shortfall)} per bulan.\n\n'
        '💡 Coba perpanjang deadline atau '
        'kurangi nominal target.';
  }

  // ============================================================
  // STATUS TABUNGAN UMUM
  // ============================================================

  String getSavingStatus() {
    if (totalIncome <= 0) {
      return 'Belum dapat dihitung';
    }

    if (totalExpense >= totalIncome) {
      return 'Perlu Perhatian';
    }

    if (recommendedSaving > 0) {
      return 'Cukup Realistis';
    }

    return 'Perlu Penyesuaian';
  }

  Color getSavingStatusColor() {
    if (totalIncome <= 0) {
      return Colors.grey;
    }

    if (totalExpense >= totalIncome) {
      return Colors.red;
    }

    return Colors.green;
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    if (isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    final goal = nearestGoal;

    return Scaffold(
      appBar: AppBar(title: const Text('Smart Saving Planner')),

      body: RefreshIndicator(
        onRefresh: loadData,

        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),

          padding: const EdgeInsets.all(24),

          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,

            children: [
              // ==================================================
              // HEADER
              // ==================================================
              const Text(
                'Rencana Menabung',

                style: TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
              ),

              const SizedBox(height: 8),

              const Text(
                'ThinkSpend membantu memperkirakan '
                'kemampuan menabung dan memberikan '
                'rekomendasi berdasarkan kondisi '
                'keuanganmu.',
                style: TextStyle(color: Colors.grey, height: 1.5),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // RINGKASAN KEUANGAN
              // ==================================================
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(20),

                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,

                    children: [
                      const Text(
                        'Ringkasan Keuangan',

                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 20),

                      _summaryRow(
                        'Pemasukan',
                        formatRupiah(totalIncome),
                        Colors.green,
                      ),

                      const SizedBox(height: 12),

                      _summaryRow(
                        'Pengeluaran',
                        formatRupiah(totalExpense),
                        Colors.red,
                      ),

                      const Divider(height: 28),

                      _summaryRow(
                        'Uang Tersedia',
                        formatRupiah(availableMoney),
                        Theme.of(context).colorScheme.primary,
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // SARAN MENABUNG
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
                              'Kemampuan Menabung',

                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      Center(
                        child: Text(
                          formatRupiah(recommendedSaving),

                          style: const TextStyle(
                            fontSize: 32,
                            fontWeight: FontWeight.bold,
                            color: Colors.green,
                          ),
                        ),
                      ),

                      const SizedBox(height: 8),

                      const Center(
                        child: Text(
                          'perkiraan kemampuan menabung per bulan',

                          style: TextStyle(color: Colors.grey),
                        ),
                      ),

                      const SizedBox(height: 20),

                      Container(
                        width: double.infinity,

                        padding: const EdgeInsets.all(16),

                        decoration: BoxDecoration(
                          color: getSavingStatusColor().withValues(alpha: 0.10),

                          borderRadius: BorderRadius.circular(12),
                        ),

                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle_outline,

                              color: getSavingStatusColor(),
                            ),

                            const SizedBox(width: 10),

                            Expanded(
                              child: Text(
                                getSavingStatus(),

                                style: TextStyle(
                                  fontWeight: FontWeight.bold,

                                  color: getSavingStatusColor(),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // ==================================================
              // TARGET PRIORITAS
              // ==================================================
              if (goal != null)
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
                                color: Theme.of(
                                  context,
                                ).colorScheme.primaryContainer,

                                borderRadius: BorderRadius.circular(12),
                              ),

                              child: Icon(
                                Icons.flag_outlined,

                                color: Theme.of(
                                  context,
                                ).colorScheme.onPrimaryContainer,
                              ),
                            ),

                            const SizedBox(width: 12),

                            const Expanded(
                              child: Text(
                                'Target Prioritas',

                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 20),

                        Text(
                          goal.name,

                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),

                        const SizedBox(height: 8),

                        Text(
                          '${formatRupiah(goal.currentAmount)}'
                          ' / '
                          '${formatRupiah(goal.targetAmount)}',
                        ),

                        const SizedBox(height: 12),

                        LinearProgressIndicator(
                          value: goal.targetAmount > 0
                              ? (goal.currentAmount / goal.targetAmount).clamp(
                                  0.0,
                                  1.0,
                                )
                              : 0,

                          minHeight: 10,
                        ),

                        const SizedBox(height: 8),

                        Text(
                          '${((goal.currentAmount / goal.targetAmount) * 100).clamp(0, 100).toStringAsFixed(1)}%',

                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 16),

                        _summaryRow(
                          'Sisa target',
                          formatRupiah(getRemainingGoal(goal)),
                          Colors.orange,
                        ),

                        const SizedBox(height: 12),

                        if (goal.deadline != null &&
                            goal.deadline!.trim().isNotEmpty) ...[
                          _summaryRow(
                            'Kebutuhan / bulan',
                            formatRupiah(calculateRequiredMonthlySaving(goal)),
                            Colors.blue,
                          ),

                          const SizedBox(height: 12),
                        ],

                        _summaryRow(
                          'Kemampuan saat ini',
                          formatRupiah(recommendedSaving),
                          Colors.green,
                        ),

                        if (goal.deadline != null) ...[
                          const SizedBox(height: 12),

                          _summaryRow('Deadline', goal.deadline!, Colors.grey),
                        ],

                        const SizedBox(height: 20),

                        // STATUS TARGET
                        Container(
                          width: double.infinity,

                          padding: const EdgeInsets.all(16),

                          decoration: BoxDecoration(
                            color: getGoalStatusColor(
                              goal,
                            ).withValues(alpha: 0.10),

                            borderRadius: BorderRadius.circular(12),
                          ),

                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,

                            children: [
                              Icon(
                                getGoalStatus(goal) == 'Target Realistis'
                                    ? Icons.check_circle_outline
                                    : Icons.warning_amber_rounded,

                                color: getGoalStatusColor(goal),
                              ),

                              const SizedBox(width: 10),

                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,

                                  children: [
                                    Text(
                                      getGoalStatus(goal),

                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,

                                        color: getGoalStatusColor(goal),
                                      ),
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      getGoalRecommendation(goal),

                                      style: const TextStyle(height: 1.5),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(20),

                    child: Column(
                      children: [
                        const Icon(
                          Icons.flag_outlined,

                          size: 40,

                          color: Colors.grey,
                        ),

                        const SizedBox(height: 12),

                        const Text(
                          'Belum ada target tabungan.',

                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),

                        const SizedBox(height: 6),

                        const Text(
                          'Buat target tabungan agar '
                          'ThinkSpend dapat menghitung '
                          'kebutuhan tabunganmu.',

                          textAlign: TextAlign.center,

                          style: TextStyle(color: Colors.grey, height: 1.5),
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
