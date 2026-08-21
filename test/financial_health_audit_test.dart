import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thinkspend/models/transaction_model.dart';
import 'package:thinkspend/services/financial_analyzer.dart';

void main() {
  group('Financial Health SSOT Audit Cases (CASE 1 to CASE 6)', () {
    // ============================================================
    // CASE 1: Income = 0, Expense = 0
    // ============================================================
    test('CASE 1: Income = Rp0, Expense = Rp0 -> Status "Belum Ada Data", Score is null', () {
      final transactions = <TransactionModel>[];

      final score = FinancialAnalyzer.calculateHealthScore(
        income: 0,
        expense: 0,
        monthlyBudget: 0,
        transactions: transactions,
      );

      final status = FinancialAnalyzer.getHealthStatus(score);
      final color = FinancialAnalyzer.getHealthColor(score);
      final icon = FinancialAnalyzer.getHealthIcon(score);
      final description = FinancialAnalyzer.getHealthDescription(
        score,
        transactions: transactions,
      );

      expect(score, isNull, reason: 'Score must be null when there is no data');
      expect(status, 'Belum Ada Data');
      expect(color, Colors.grey);
      expect(icon, Icons.analytics_outlined);
      expect(description, contains('Belum ada data transaksi'));
    });

    // ============================================================
    // CASE 2: Income = Rp5.000.000, Expense = Rp0
    // ============================================================
    test('CASE 2: Income = Rp5.000.000, Expense = Rp0 -> Sangat Sehat / Keuangan Sehat, high score', () {
      final transactions = [
        TransactionModel(
          id: 1,
          userId: 1,
          title: 'Gajian',
          amount: 5000000,
          type: 'income',
          category: 'Other',
          date: '2026-08-20',
        ),
      ];

      final breakdown = FinancialAnalyzer.calculateBreakdown(
        income: 5000000,
        expense: 0,
        monthlyBudget: 0,
        transactions: transactions,
      );

      final score = FinancialAnalyzer.calculateHealthScore(
        income: 5000000,
        expense: 0,
        monthlyBudget: 0,
        transactions: transactions,
      );

      final status = FinancialAnalyzer.getHealthStatus(score);
      final color = FinancialAnalyzer.getHealthColor(score);

      expect(breakdown.cashFlowScore, 40);
      expect(breakdown.expenseScore, 25);
      expect(breakdown.savingScore, 20);
      expect(breakdown.consistencyScore, 3);
      expect(breakdown.totalScore, 88);
      expect(score, 88.0);
      expect(status, 'Keuangan Sehat');
      expect(color, Colors.green);
    });

    // ============================================================
    // CASE 3: Income = Rp5.000.000, Expense = Rp600.000 (12%)
    // ============================================================
    test('CASE 3: Income = Rp5.000.000, Expense = Rp600.000 (Expense ratio 12%) -> Keuangan Sehat (Score 88)', () {
      final transactions = [
        TransactionModel(
          id: 1,
          userId: 1,
          title: 'Gajian',
          amount: 5000000,
          type: 'income',
          category: 'Other',
          date: '2026-08-20',
        ),
        TransactionModel(
          id: 2,
          userId: 1,
          title: 'Makanan',
          amount: 600000,
          type: 'expense',
          category: 'Food',
          date: '2026-08-20',
        ),
      ];

      final breakdown = FinancialAnalyzer.calculateBreakdown(
        income: 5000000,
        expense: 600000,
        monthlyBudget: 0,
        transactions: transactions,
      );

      final score = FinancialAnalyzer.calculateHealthScore(
        income: 5000000,
        expense: 600000,
        monthlyBudget: 0,
        transactions: transactions,
      );

      final status = FinancialAnalyzer.getHealthStatus(score);
      final color = FinancialAnalyzer.getHealthColor(score);

      expect(breakdown.cashFlowScore, 40); // 12% ratio <= 30%
      expect(breakdown.expenseScore, 25); // 12% ratio <= 30%
      expect(breakdown.savingScore, 20); // 88% remaining >= 40%
      expect(breakdown.consistencyScore, 3);
      expect(breakdown.totalScore, 88);
      expect(score, 88.0);
      expect(status, 'Keuangan Sehat');
      expect(color, Colors.green);
    });

    // ============================================================
    // CASE 4: Income = Rp5.000.000, Expense = Rp4.500.000 (90%)
    // ============================================================
    test('CASE 4: Income = Rp5.000.000, Expense = Rp4.500.000 (Expense ratio 90%) -> NOT Keuangan Sehat (Perlu Perbaikan, Score 29)', () {
      final transactions = [
        TransactionModel(
          id: 1,
          userId: 1,
          title: 'Gajian',
          amount: 5000000,
          type: 'income',
          category: 'Other',
          date: '2026-08-20',
        ),
        TransactionModel(
          id: 2,
          userId: 1,
          title: 'Sewa & Belanja',
          amount: 4500000,
          type: 'expense',
          category: 'Bills',
          date: '2026-08-20',
        ),
      ];

      final breakdown = FinancialAnalyzer.calculateBreakdown(
        income: 5000000,
        expense: 4500000,
        monthlyBudget: 0,
        transactions: transactions,
      );

      final score = FinancialAnalyzer.calculateHealthScore(
        income: 5000000,
        expense: 4500000,
        monthlyBudget: 0,
        transactions: transactions,
      );

      final status = FinancialAnalyzer.getHealthStatus(score);
      final color = FinancialAnalyzer.getHealthColor(score);

      expect(breakdown.cashFlowScore, 10); // 90% spending ratio
      expect(breakdown.expenseScore, 6); // 90% spending ratio
      expect(breakdown.savingScore, 10); // 10% saving ratio
      expect(breakdown.consistencyScore, 3);
      expect(breakdown.totalScore, 29);
      expect(score, 29.0);
      expect(status, 'Perlu Perbaikan');
      expect(status, isNot(equals('Keuangan Sehat')));
      expect(color, Colors.red);
    });

    // ============================================================
    // CASE 5: Income = Rp5.000.000, Expense > Rp5.000.000
    // ============================================================
    test('CASE 5: Income = Rp5.000.000, Expense = Rp6.000.000 (Expense > Income) -> Perlu Perbaikan / Berisiko', () {
      final transactions = [
        TransactionModel(
          id: 1,
          userId: 1,
          title: 'Gajian',
          amount: 5000000,
          type: 'income',
          category: 'Other',
          date: '2026-08-20',
        ),
        TransactionModel(
          id: 2,
          userId: 1,
          title: 'Pengeluaran Besar',
          amount: 6000000,
          type: 'expense',
          category: 'Shopping',
          date: '2026-08-20',
        ),
      ];

      final breakdown = FinancialAnalyzer.calculateBreakdown(
        income: 5000000,
        expense: 6000000,
        monthlyBudget: 0,
        transactions: transactions,
      );

      final score = FinancialAnalyzer.calculateHealthScore(
        income: 5000000,
        expense: 6000000,
        monthlyBudget: 0,
        transactions: transactions,
      );

      final status = FinancialAnalyzer.getHealthStatus(score);
      final color = FinancialAnalyzer.getHealthColor(score);

      expect(breakdown.cashFlowScore, 0); // Deficit
      expect(breakdown.expenseScore, 0); // Deficit
      expect(breakdown.savingScore, 0); // No saving remaining
      expect(breakdown.consistencyScore, 3);
      expect(breakdown.totalScore, 3);
      expect(score, 3.0);
      expect(status, 'Perlu Perbaikan');
      expect(color, Colors.red);
    });

    // ============================================================
    // CASE 6: Income exists, but transactions are very few
    // ============================================================
    test('CASE 6: Income exists but data is limited (<3 days) -> provides status with data warning', () {
      final transactions = [
        TransactionModel(
          id: 1,
          userId: 1,
          title: 'Gajian',
          amount: 5000000,
          type: 'income',
          category: 'Other',
          date: '2026-08-20',
        ),
      ];

      final score = FinancialAnalyzer.calculateHealthScore(
        income: 5000000,
        expense: 0,
        monthlyBudget: 0,
        transactions: transactions,
      );

      final description = FinancialAnalyzer.getHealthDescription(
        score,
        transactions: transactions,
      );

      expect(score, isNotNull);
      expect(description, contains('Catatan masih awal'));
    });
  });
}
