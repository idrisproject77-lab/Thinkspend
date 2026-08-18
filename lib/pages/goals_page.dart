import 'package:flutter/material.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/goal_model.dart';
import 'package:thinkspend/models/user_model.dart';
import 'package:thinkspend/utils/currency_formatter.dart';

import 'add_goal_page.dart';
import 'goal_detail_page.dart';

class GoalsPage extends StatefulWidget {
  final UserModel user;

  const GoalsPage({
    super.key,
    required this.user,
  });

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  List<GoalModel> goals = [];

  @override
  void initState() {
    super.initState();
    loadGoals();
  }

  Future<void> loadGoals() async {
    final data = await DatabaseHelper.instance.getGoals(
      widget.user.id!,
    );

    if (!mounted) return;

    setState(() {
      goals = data;
    });
  }

  double calculateProgress(GoalModel goal) {
    if (goal.targetAmount <= 0) {
      return 0;
    }

    final progress =
        goal.currentAmount / goal.targetAmount;

    if (progress > 1) {
      return 1;
    }

    if (progress < 0) {
      return 0;
    }

    return progress;
  }

  Color getPriorityColor(String? priority) {
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('Target Tabungan'),
      ),

      body: goals.isEmpty
          ? const Center(
              child: Text(
                'Belum ada target tabungan.',
                style: TextStyle(
                  color: Colors.grey,
                ),
              ),
            )
          : RefreshIndicator(
              onRefresh: loadGoals,

              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: goals.length,

                itemBuilder: (context, index) {
                  final goal = goals[index];
                  final progress =
                      calculateProgress(goal);

                  final priorityColor =
                      getPriorityColor(
                    goal.priority,
                  );

                  return Card(
                    margin:
                        const EdgeInsets.only(
                      bottom: 16,
                    ),

                    child: InkWell(
                      borderRadius:
                          BorderRadius.circular(12),

                      onTap: () async {
                        final result =
                            await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) =>
                                GoalDetailPage(
                              goal: goal,
                            ),
                          ),
                        );

                        if (result == true) {
                          await loadGoals();
                        }
                      },

                      child: Padding(
                        padding:
                            const EdgeInsets.all(16),

                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,

                          children: [

                            // =========================
                            // NAMA + PRIORITAS
                            // =========================

                            Row(
                              children: [

                                Expanded(
                                  child: Text(
                                    goal.name,

                                    style:
                                        const TextStyle(
                                      fontSize: 20,
                                      fontWeight:
                                          FontWeight.bold,
                                    ),
                                  ),
                                ),

                                if (goal.priority !=
                                    null)
                                  Container(
                                    padding:
                                        const EdgeInsets
                                            .symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),

                                    decoration:
                                        BoxDecoration(
                                      color:
                                          priorityColor
                                              .withValues(
                                        alpha: 0.12,
                                      ),

                                      borderRadius:
                                          BorderRadius
                                              .circular(
                                        20,
                                      ),
                                    ),

                                    child: Text(
                                      goal.priority!,

                                      style: TextStyle(
                                        color:
                                            priorityColor,
                                        fontWeight:
                                            FontWeight.bold,
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
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,

                              children: [

                                Text(
                                formatRupiah(goal.currentAmount),
                                  style:
                                      const TextStyle(
                                    fontSize: 16,
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                Text(
                                  'dari ${formatRupiah(goal.targetAmount)}',

                                  style:
                                      const TextStyle(
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
                              borderRadius:
                                  BorderRadius
                                      .circular(
                                10,
                              ),

                              child:
                                  LinearProgressIndicator(
                                value: progress,
                                minHeight: 10,
                              ),
                            ),

                            const SizedBox(height: 8),

                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment
                                      .spaceBetween,

                              children: [

                                Text(
                                  '${(progress * 100).toStringAsFixed(1)}%',

                                  style:
                                      const TextStyle(
                                    fontWeight:
                                        FontWeight.bold,
                                  ),
                                ),

                                if (goal.deadline !=
                                    null)
                                  Text(
                                    'Deadline: ${goal.deadline}',

                                    style:
                                        const TextStyle(
                                      color:
                                          Colors.grey,
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
              ),
            ),

      floatingActionButton:
          FloatingActionButton(
        onPressed: () async {
          final result =
              await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) =>
                  AddGoalPage(
                user: widget.user,
              ),
            ),
          );

          if (result == true) {
            await loadGoals();
          }
        },

        child: const Icon(Icons.add),
      ),
    );
  }
}