import 'package:flutter/material.dart';
import 'package:thinkspend/models/goal_model.dart';
import 'package:thinkspend/services/privacy_service.dart';
import 'package:thinkspend/services/theme_service.dart';
import 'package:thinkspend/utils/currency_formatter.dart';

/// Widget kartu untuk menampilkan progres target tabungan (Saving Goal).
///
/// Menampilkan persentase pencapaian, nominal terkumpul/target (dengan sensor privasi),
/// badge prioritas (Low/Medium/High), dan deadline.
class GoalCard extends StatelessWidget {
  final GoalModel goal;
  final VoidCallback? onTap;

  const GoalCard({
    super.key,
    required this.goal,
    this.onTap,
  });

  double _calculateProgress() {
    if (goal.targetAmount <= 0) {
      return 0;
    }

    final progress = goal.currentAmount / goal.targetAmount;

    if (progress > 1) {
      return 1;
    }

    if (progress < 0) {
      return 0;
    }

    return progress;
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

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: PrivacyService.instance,
      builder: (context, _) {
        final progress = _calculateProgress();
        final priorityColor = _getPriorityColor(goal.priority);
        final textPrimary = AppColors.textPrimary(context);
        final textSecondary = AppColors.textSecondary(context);


    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: AppColors.surface(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border(context), width: 1),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // =========================
              // NAMA + PRIORITAS
              // =========================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      goal.name,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.bold,
                        color: textPrimary,
                      ),
                    ),
                  ),
                  if (goal.priority != null)
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

              const SizedBox(height: 14),

              // =========================
              // NOMINAL
              // =========================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatRupiah(goal.currentAmount),
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  Text(
                    'dari ${formatRupiah(goal.targetAmount)}',
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // =========================
              // PROGRESS BAR
              // =========================
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 8,
                  backgroundColor: AppColors.subtleBg(context),
                  valueColor: AlwaysStoppedAnimation<Color>(
                    progress >= 1.0 ? AppColors.green : AppColors.primaryBlue,
                  ),
                ),
              ),

              const SizedBox(height: 10),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: textPrimary,
                    ),
                  ),
                  if (goal.deadline != null)
                    Text(
                      'Deadline: ${goal.deadline}',
                      style: TextStyle(
                        color: textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
      },
    );
  }
}