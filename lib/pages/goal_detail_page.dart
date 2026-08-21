import 'package:flutter/material.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/goal_model.dart';
import 'package:thinkspend/utils/currency_formatter.dart';

import 'edit_goal_page.dart';

/// Halaman rincian target tabungan spesifik.
///
/// Menampilkan visualisasi progres bar, persentase ketercapaian, sisa dana yang dibutuhkan,
/// tanggal target, dan aksi untuk mengedit atau menghapus target.
class GoalDetailPage extends StatelessWidget {
  final GoalModel goal;

  const GoalDetailPage({super.key, required this.goal});

  double calculateProgress() {
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

  @override
  Widget build(BuildContext context) {
    final progress = calculateProgress();

    return Scaffold(
      appBar: AppBar(title: const Text('Detail Target')),

      body: Padding(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            Text(
              goal.name,

              style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            const Text(
              'Progress Tabungan',

              style: TextStyle(color: Colors.grey),
            ),

            const SizedBox(height: 8),

            Text(
              '${formatRupiah(goal.currentAmount)} '
              '/ ${formatRupiah(goal.targetAmount)}',

              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            ClipRRect(
              borderRadius: BorderRadius.circular(10),

              child: LinearProgressIndicator(value: progress, minHeight: 12),
            ),

            const SizedBox(height: 8),

            Text(
              '${(progress * 100).toStringAsFixed(1)}%',

              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 24),

            const Text('Prioritas', style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 4),

            Text(goal.priority ?? '-', style: const TextStyle(fontSize: 18)),

            const SizedBox(height: 20),

            const Text('Deadline', style: TextStyle(color: Colors.grey)),

            const SizedBox(height: 4),

            Text(goal.deadline ?? '-', style: const TextStyle(fontSize: 18)),

            const Spacer(),

            // =========================
            // EDIT
            // =========================
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => EditGoalPage(goal: goal),
                    ),
                  );

                  if (result == true && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },

                icon: const Icon(Icons.edit),

                label: const Text('Edit Target'),
              ),
            ),

            const SizedBox(height: 12),

            // =========================
            // DELETE
            // =========================
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: () async {
                  if (goal.id == null) {
                    return;
                  }

                  final confirm = await showDialog<bool>(
                    context: context,

                    builder: (context) {
                      return AlertDialog(
                        title: const Text('Hapus Target?'),

                        content: const Text(
                          'Target ini akan dihapus '
                          'secara permanen.',
                        ),

                        actions: [
                          TextButton(
                            onPressed: () {
                              Navigator.pop(context, false);
                            },

                            child: const Text('Batal'),
                          ),

                          ElevatedButton(
                            onPressed: () {
                              Navigator.pop(context, true);
                            },

                            child: const Text('Hapus'),
                          ),
                        ],
                      );
                    },
                  );

                  if (confirm != true) {
                    return;
                  }

                  final result = await DatabaseHelper.instance.deleteGoal(
                    goal.id!,
                    goal.userId,
                  );

                  if (result > 0 && context.mounted) {
                    Navigator.pop(context, true);
                  }
                },

                icon: const Icon(Icons.delete),

                label: const Text('Hapus Target'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
