class TransactionModel {
  final int? id;
  final String title;
  final double amount;
  final String category;
  final String type;
  final String date;
  final String? notes;

  TransactionModel({
    this.id,
    required this.title,
    required this.amount,
    required this.category,
    required this.type,
    required this.date,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'amount': amount,
      'category': category,
      'type': type,
      'date': date,
      'notes': notes,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
  return TransactionModel(
    id: map['id'],
    title: map['title'],
    amount: (map['amount'] as num).toDouble(),
    category: map['category'],
    type: map['type'],
    date: map['date'],
    notes: map['notes'],
  );
}
}