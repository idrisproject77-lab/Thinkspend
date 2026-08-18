import 'package:flutter/material.dart';
import 'package:thinkspend/models/transaction_model.dart';
import 'package:thinkspend/utils/currency_formatter.dart';

class TransactionCard extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onTap;

  const TransactionCard({
    super.key,
    required this.transaction,
    this.onTap,
  });

  String _formatDate(String date) {
    if (date.length >= 10) {
      return date.substring(0, 10);
    }
    return date;
  }

  @override
  Widget build(BuildContext context) {
    final isIncome = transaction.type == 'income';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: isIncome
              ? Colors.green.withValues(alpha: 0.15)
              : Colors.red.withValues(alpha: 0.15),
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
        title: Text(
          transaction.title,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        subtitle: Text(
          '${transaction.category} • ${_formatDate(transaction.date)}',
        ),
        trailing: Text(
          '${isIncome ? '+' : '-'} ${formatRupiah(transaction.amount)}',
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: isIncome ? Colors.green : Colors.red,
          ),
        ),
      ),
    );
  }
}
