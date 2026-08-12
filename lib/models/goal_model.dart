 class GoalModel {
  final int? id;
  final String name;
  final double targetAmount;
  final double currentAmount;
  final String? deadline;
  final String? priority;

  GoalModel({
    this.id,
    required this.name,
    required this.targetAmount,
    this.currentAmount = 0,
    this.deadline,
    this.priority,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'target_amount': targetAmount,
      'current_amount': currentAmount,
      'deadline': deadline,
      'priority': priority,
    };
  }

  factory GoalModel.fromMap(Map<String, dynamic> map) {
  return GoalModel(
    id: map['id'],
    name: map['name'],
    targetAmount: (map['target_amount'] as num).toDouble(),
    currentAmount: (map['current_amount'] as num?)?.toDouble() ?? 0,
    deadline: map['deadline'],
    priority: map['priority'],
  );
}
}