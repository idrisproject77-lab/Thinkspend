import 'package:flutter/material.dart';
import 'package:thinkspend/models/goal_model.dart';
import 'package:thinkspend/utils/currency_formatter.dart';

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
        return Colors.red;
      case 'Medium':
        return Colors.orange;
      case 'Low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  @override
  Widget build(BuildContext context) {
    final progress = _calculateProgress();
    final priorityColor = _getPriorityColor(goal.priority);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
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
                children: [
                  Expanded(
                    child: Text(
                      goal.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (goal.priority != null)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 5,
                      ),
                      decoration: BoxDecoration(
                        color: priorityColor.withValues(
                          alpha: 0.12,
                        ),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        goal.priority!,
                        style: TextStyle(
                          color: priorityColor,
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                        ),
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 16),

              // =========================
              // NOMINAL
              // =========================
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    formatRupiah(goal.currentAmount),
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    'dari ${formatRupiah(goal.targetAmount)}',
                    style: const TextStyle(
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 10),

              // =========================
              // PROGRESS
              // =========================
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: LinearProgressIndicator(
                  value: progress,
                  minHeight: 10,
                ),
              ),

              const SizedBox(height: 8),

              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    '${(progress * 100).toStringAsFixed(1)}%',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (goal.deadline != null)
                    Text(
                      'Deadline: ${goal.deadline}',
                      style: const TextStyle(
                        color: Colors.grey,
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
  }
}
