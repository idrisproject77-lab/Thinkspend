import 'package:flutter/material.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/goal_model.dart';
import 'package:thinkspend/models/transaction_model.dart';
import 'package:thinkspend/models/user_model.dart';
import 'package:thinkspend/services/theme_service.dart';
import 'package:thinkspend/utils/currency_formatter.dart';
import 'package:thinkspend/services/privacy_service.dart';

/// Halaman fitur Saving Planner ThinkSpend.
///
/// Menganalisis kapasitas tabungan dari sisa arus kas (Pemasukan - Pengeluaran),
/// membandingkan total kebutuhan seluruh target tabungan, dan memberikan
/// rekomendasi alokasi tabungan bulanan berbasis prioritas.
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
  // REKOMENDASI TABUNGAN (40% UANG TERSEDIA)
  // ============================================================

  double get recommendedSaving {
    if (availableMoney <= 0) {
      return 0;
    }
    return availableMoney * 0.40;
  }

  String formatPlannerAmount(double value) {
    if (!PrivacyService.instance.isAmountVisible) {
      return '••••';
    }

    final amount = value.abs();

    if (amount >= 1000000) {
      final juta = amount / 1000000;
      return 'Rp ${juta.toStringAsFixed(1)} jt';
    }

    if (amount >= 1000) {
      final ribu = amount / 1000;
      return 'Rp ${ribu.toStringAsFixed(0)} ribu';
    }

    return 'Rp ${amount.round()}';
  }

  // ============================================================
  // FORMAT TANGGAL FRIENDLY
  // ============================================================

  String formatFriendlyDate(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) {
      return '-';
    }

    final parsedDate = DateTime.tryParse(dateStr.trim());
    if (parsedDate == null) {
      return dateStr;
    }

    const months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'Mei',
      'Jun',
      'Jul',
      'Agu',
      'Sep',
      'Okt',
      'Nov',
      'Des',
    ];

    return '${parsedDate.day} ${months[parsedDate.month - 1]} ${parsedDate.year}';
  }

  // ============================================================
  // TARGET PRIORITAS
  // ============================================================

  GoalModel? get nearestGoal {
    if (goals.isEmpty) {
      return null;
    }

    GoalModel? selectedGoal;
    GoalModel? completedGoal;

    for (final goal in goals) {
      final isCompleted = goal.targetAmount <= goal.currentAmount;

      // Simpan target yang sudah selesai sebagai fallback.
      if (isCompleted) {
        completedGoal ??= goal;
        continue;
      }

      // Pilih target yang belum selesai.
      if (selectedGoal == null) {
        selectedGoal = goal;
        continue;
      }

      // Prioritaskan High.
      if (goal.priority == 'High' && selectedGoal.priority != 'High') {
        selectedGoal = goal;
        continue;
      }

      // Jika sama-sama punya deadline,
      // pilih deadline yang lebih dekat.
      if (goal.deadline != null && selectedGoal.deadline != null) {
        if (goal.deadline!.compareTo(selectedGoal.deadline!) < 0) {
          selectedGoal = goal;
        }
      }
    }

    // Kalau masih ada target yang belum tercapai,
    // tampilkan target tersebut.
    if (selectedGoal != null) {
      return selectedGoal;
    }

    // Kalau semua target sudah tercapai,
    // tetap tampilkan target yang selesai.
    return completedGoal;
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

    // Bandingkan tanggal saja, tanpa memperhitungkan jam.
    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
    );

    // Deadline hari ini masih dianggap valid.
    if (deadlineDate.isBefore(today)) {
      return 0;
    }

    int months =
        (deadlineDate.year - today.year) * 12 +
        deadlineDate.month -
        today.month;

    if (deadlineDate.day > today.day) {
      months++;
    }

    return months <= 0 ? 1 : months;
  }

  bool isDeadlinePassed(String? deadline) {
    if (deadline == null || deadline.trim().isEmpty) {
      return false;
    }

    final parsedDate = DateTime.tryParse(deadline);

    if (parsedDate == null) {
      return false;
    }

    final now = DateTime.now();

    final today = DateTime(now.year, now.month, now.day);
    final deadlineDate = DateTime(
      parsedDate.year,
      parsedDate.month,
      parsedDate.day,
    );

    return deadlineDate.isBefore(today);
  }

  // ============================================================
  // KEBUTUHAN TABUNGAN PER BULAN
  // ============================================================

  double calculateRequiredMonthlySaving(GoalModel goal) {
    final remaining = getRemainingGoal(goal);

    if (remaining <= 0) {
      return 0;
    }

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

    if (remaining <= 0) {
      return 'Target Tercapai';
    }

    if (isDeadlinePassed(goal.deadline)) {
      return 'Deadline Terlewat';
    }

    if (goal.deadline == null || goal.deadline!.trim().isEmpty) {
      if (recommendedSaving > 0) {
        return 'Target Terjangkau';
      }

      return 'Perlu Penyesuaian';
    }

    final required = calculateRequiredMonthlySaving(goal);

    if (recommendedSaving <= 0) {
      return 'Perlu Penyesuaian';
    }

    if (recommendedSaving >= required) {
      return 'Target Terjangkau';
    }

    return 'Perlu Penyesuaian';
  }

  Color getGoalStatusColor(GoalModel goal) {
    final status = getGoalStatus(goal);

    if (status == 'Target Terjangkau' || status == 'Target Tercapai') {
      return AppColors.green;
    }

    if (status == 'Deadline Terlewat') {
      return AppColors.red;
    }

    return AppColors.orange;
  }

  IconData getGoalStatusIcon(GoalModel goal) {
    final status = getGoalStatus(goal);

    if (status == 'Target Terjangkau' || status == 'Target Tercapai') {
      return Icons.check_circle_rounded;
    }

    if (status == 'Deadline Terlewat') {
      return Icons.event_busy_rounded;
    }

    return Icons.warning_amber_rounded;
  }

  // ============================================================
  // SELISIH KEMAMPUAN TABUNGAN
  // ============================================================

  double calculateSavingDifference(GoalModel goal) {
    final required = calculateRequiredMonthlySaving(goal);
    return recommendedSaving - required;
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
      return 'Kondisi Keuangan Cukup Realistis';
    }

    return 'Perlu Penyesuaian';
  }

  Color getSavingStatusColor() {
    if (totalIncome <= 0) {
      return AppColors.lightMuted;
    }

    if (totalExpense >= totalIncome) {
      return AppColors.red;
    }

    return AppColors.green;
  }

  Color _getPriorityColor(String? priority) {
    switch (priority) {
      case 'High':
        return AppColors.red;
      case 'Medium':
        return AppColors.orange;
      case 'Low':
        return AppColors.green;
      default:
        return AppColors.lightTextSecondary;
    }
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
    final background = AppColors.background(context);

    if (isLoading) {
      return Scaffold(
        backgroundColor: background,
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    final goal = nearestGoal;

    return Scaffold(
      backgroundColor: background,
      appBar: AppBar(title: const Text('Smart Saving Planner'), elevation: 0),
      body: RefreshIndicator(
        onRefresh: loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ==================================================
              // HEADER
              // ==================================================
              Text(
                'Smart Saving Planner',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Rencanakan target tabunganmu dengan lebih realistis.',
                style: TextStyle(
                  fontSize: 14,
                  color: textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),

              // ==================================================
              // RINGKASAN KEUANGAN
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
                          backgroundColor: AppColors.primaryBlue.withValues(
                            alpha: 0.12,
                          ),
                          child: const Icon(
                            Icons.account_balance_wallet_outlined,
                            size: 18,
                            color: AppColors.primaryBlue,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Ringkasan Keuangan',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    _summaryRow(
                      context,
                      'Pemasukan',
                      formatRupiah(totalIncome),
                      AppColors.green,
                    ),
                    const SizedBox(height: 10),
                    _summaryRow(
                      context,
                      'Pengeluaran',
                      formatRupiah(totalExpense),
                      AppColors.red,
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      child: Divider(height: 1, color: border),
                    ),
                    _summaryRow(
                      context,
                      'Uang Tersedia',
                      formatRupiah(availableMoney),
                      AppColors.primaryBlue,
                      isBold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // ==================================================
              // KEMAMPUAN MENABUNG
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
                          backgroundColor: AppColors.green.withValues(
                            alpha: 0.12,
                          ),
                          child: const Icon(
                            Icons.savings_outlined,
                            size: 18,
                            color: AppColors.green,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          'Rekomendasi Menabung',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: textPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Center(
                      child: Column(
                        children: [
                          Text(
                            formatPlannerAmount(recommendedSaving),
                            style: const TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              color: AppColors.green,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Rekomendasi menabung per bulan',
                            style: TextStyle(
                              fontSize: 12,
                              color: textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                      decoration: BoxDecoration(
                        color: getSavingStatusColor().withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: getSavingStatusColor().withValues(alpha: 0.20),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.info_outline_rounded,
                            size: 16,
                            color: getSavingStatusColor(),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              getSavingStatus(),
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
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
              const SizedBox(height: 16),

              // ==================================================
              // TARGET PRIORITAS
              // ==================================================
              if (goal != null)
                _buildPriorityGoalCard(context, goal)
              else
                _buildEmptyGoalCard(context),
            ],
          ),
        ),
      ),
    );
  }

  // ============================================================
  // TARGET PRIORITAS CARD
  // ============================================================

  Widget _buildPriorityGoalCard(BuildContext context, GoalModel goal) {
    final surface = AppColors.surface(context);
    final border = AppColors.border(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);
    final subtleBg = AppColors.subtleBg(context);

    final remaining = getRemainingGoal(goal);
    final hasDeadline =
        goal.deadline != null && goal.deadline!.trim().isNotEmpty;
    final required = hasDeadline ? calculateRequiredMonthlySaving(goal) : 0.0;
    final progress = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount).clamp(0.0, 1.0)
        : 0.0;
    final progressPercentage = goal.targetAmount > 0
        ? (goal.currentAmount / goal.targetAmount) * 100
        : 0.0;

    final priorityColor = _getPriorityColor(goal.priority);

    return Container(
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
          // Header Card: Icon + Title + Priority Tag
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 16,
                    backgroundColor: AppColors.primaryBlue.withValues(
                      alpha: 0.12,
                    ),
                    child: const Icon(
                      Icons.flag_outlined,
                      size: 18,
                      color: AppColors.primaryBlue,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Text(
                    'Target Prioritas',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                ],
              ),
              if (goal.priority != null && goal.priority!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: priorityColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    goal.priority!,
                    style: TextStyle(
                      color: priorityColor,
                      fontWeight: FontWeight.w600,
                      fontSize: 11,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Nama Target
          Text(
            goal.name,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 10),

          // 2. Progress
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                formatRupiah(goal.currentAmount),
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: textPrimary,
                ),
              ),
              Text(
                'dari ${formatRupiah(goal.targetAmount)}',
                style: TextStyle(fontSize: 12, color: textSecondary),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: subtleBg,
              valueColor: AlwaysStoppedAnimation<Color>(
                progress >= 1.0 ? AppColors.green : AppColors.primaryBlue,
              ),
            ),
          ),
          const SizedBox(height: 6),
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              '${progressPercentage.clamp(0, 100).toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: textPrimary,
              ),
            ),
          ),
          const SizedBox(height: 14),

          // 3. Sisa Target
          _summaryRow(
            context,
            'Sisa target',
            formatPlannerAmount(remaining),
            AppColors.orange,
          ),
          const SizedBox(height: 10),

          // 4. Perlu ditabung / bulan
          if (hasDeadline) ...[
            _summaryRow(
              context,
              'Perlu ditabung / bulan',
             formatPlannerAmount(required),
              AppColors.primaryBlue,
            ),
            const SizedBox(height: 10),
          ],

          // 5. Estimasi Kemampuan
          _summaryRow(
            context,
            'Estimasi kemampuan',
            formatPlannerAmount(recommendedSaving),
            AppColors.green,
          ),
          const SizedBox(height: 10),

          // 6. Deadline
          _summaryRow(
            context,
            'Deadline',
            formatFriendlyDate(goal.deadline),
            textPrimary,
          ),
          const SizedBox(height: 16),

          // 7. Status & Rekomendasi Assistant Card
          _buildGoalStatusCard(context, goal, remaining, hasDeadline, required),
        ],
      ),
    );
  }

  // ============================================================
  // STATUS & REKOMENDASI CARD (COMPACT FINANCIAL ASSISTANT)
  // ============================================================

  Widget _buildGoalStatusCard(
    BuildContext context,
    GoalModel goal,
    double remaining,
    bool hasDeadline,
    double required,
  ) {
    final status = getGoalStatus(goal);
    final statusColor = getGoalStatusColor(goal);
    final statusIcon = getGoalStatusIcon(goal);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);

    // Is Completed
    if (remaining <= 0) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Selamat! Target ini sudah berhasil kamu capai.',
              style: TextStyle(fontSize: 13, color: textPrimary, height: 1.4),
            ),
          ],
        ),
      );
    }

    // Is Realistic / Terjangkau
    if (status == 'Target Terjangkau') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: statusColor.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: statusColor.withValues(alpha: 0.22),
            width: 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(statusIcon, color: statusColor, size: 20),
                const SizedBox(width: 8),
                Text(
                  status,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: statusColor,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              hasDeadline
                  ? 'Dengan rekomendasi menabungmu saat ini, target ini masih realistis untuk dicapai sebelum deadline.'
                  : 'Dengan rekomendasi menabungmu saat ini, target ini masih realistis untuk dicapai secara bertahap.',
              style: TextStyle(fontSize: 13, color: textPrimary, height: 1.4),
            ),
          ],
        ),
      );
    }

    // Needs Adjustment / Perlu Penyesuaian
    final shortfall = (required - recommendedSaving) > 0
        ? (required - recommendedSaving)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: statusColor.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: statusColor.withValues(alpha: 0.22),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(statusIcon, color: statusColor, size: 20),
              const SizedBox(width: 8),
              Text(
                status,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (hasDeadline && required > 0) ...[
            Text(
             'Target ini membutuhkan sekitar ${formatPlannerAmount(required)}/bulan, sementara rekomendasi menabungmu sekitar ${formatPlannerAmount(recommendedSaving)}/bulan.',
            ),
            if (shortfall > 0) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: AppColors.surface(context),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.border(context),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'Selisih kebutuhan',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    Text(
                      '${formatPlannerAmount(shortfall)}/bulan',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.orange,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            const SizedBox(height: 8),
            Text(
              'Agar target lebih realistis, kamu bisa memperpanjang deadline atau menyesuaikan nominal target.',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
                height: 1.35,
              ),
            ),
          ] else ...[
            Text(
              'Saat ini belum ada rekomendasi menabung yang cukup untuk dialokasikan ke target ini.',
              style: TextStyle(fontSize: 13, color: textPrimary, height: 1.4),
            ),
            const SizedBox(height: 8),
            Text(
              'Agar target lebih realistis, kamu bisa mengevaluasi pos pengeluaran harian atau menyesuaikan nominal target.',
              style: TextStyle(
                fontSize: 12,
                color: textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ============================================================
  // EMPTY STATE GOAL CARD
  // ============================================================

  Widget _buildEmptyGoalCard(BuildContext context) {
    final surface = AppColors.surface(context);
    final border = AppColors.border(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: border, width: 1),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.lightMuted.withValues(alpha: 0.15),
            child: const Icon(
              Icons.flag_outlined,
              size: 24,
              color: AppColors.lightMuted,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Belum ada target tabungan',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Buat target tabungan terlebih dahulu agar ThinkSpend dapat memperkirakan kebutuhan dan rencana menabungmu.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 13, color: textSecondary, height: 1.4),
          ),
        ],
      ),
    );
  }

  // ============================================================
  // SUMMARY ROW
  // ============================================================

  Widget _summaryRow(
    BuildContext context,
    String title,
    String value,
    Color valueColor, {
    bool isBold = false,
  }) {
    final textSecondary = AppColors.textSecondary(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(fontSize: 13, color: textSecondary),
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: TextStyle(
            fontSize: isBold ? 14 : 13,
            fontWeight: isBold ? FontWeight.bold : FontWeight.w600,
            color: valueColor,
          ),
        ),
      ],
    );
  }
}
