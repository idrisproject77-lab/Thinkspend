/// Model entitas data transaksi pemasukan (income) dan pengeluaran (expense).
///
/// Terikat pada [userId] tertentu untuk isolasi multi-user dan menjadi
/// sumber data utama penghitungan saldo, kategori, dan Financial Health.
class TransactionModel {
  final int? id;
  final int userId;
  final String title;
  final double amount;
  final String category;
  final String type;
  final String date;
  final String? notes;

  TransactionModel({
    this.id,
    required this.userId,
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
      'user_id': userId,
      'title': title,
      'amount': amount,
      'category': category,
      'type': type,
      'date': date,
      'notes': notes,
    };
  }

  factory TransactionModel.fromMap(
    Map<String, dynamic> map,
  ) {
    return TransactionModel(
      id: map['id'],
      userId: map['user_id'] as int,
      title: map['title'] as String,
      amount: (map['amount'] as num).toDouble(),
      category: map['category'] as String,
      type: map['type'] as String,
      date: map['date'] as String,
      notes: map['notes'] as String?,
    );
  }
}