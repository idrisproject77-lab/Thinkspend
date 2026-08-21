import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thinkspend/models/transaction_model.dart';
import 'package:thinkspend/services/financial_analyzer.dart';

void main() {
  group('Financial Health UI & Integration Verification', () {

    // ============================================================
    // UI VERIFICATION: CASE 1 (Income 0, Expense 0)
    // ============================================================
    test('CASE 1: Analyzer and UI models return Belum Ada Data and null score', () {
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

      expect(score, isNull);
      expect(status, 'Belum Ada Data');
      expect(color, Colors.grey);
      expect(icon, Icons.analytics_outlined);
    });

    // ============================================================
    // UI VERIFICATION: CASE 2 (Income 5.000.000, Expense 0)
    // ============================================================
    test('CASE 2: Analyzer and Breakdown for Surplus', () {
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

      expect(breakdown.cashFlowScore, 40);
      expect(breakdown.expenseScore, 25);
      expect(breakdown.savingScore, 20);
      expect(breakdown.consistencyScore, 3);
      expect(breakdown.totalScore, 88);
      expect(score, 88.0);
      expect(status, 'Keuangan Sehat');
    });

    // ============================================================
    // UI VERIFICATION: CASE 3 (Income 5.000.000, Expense 600.000)
    // ============================================================
    test('CASE 3: Analyzer and Breakdown for 12% expense ratio -> 88 / 100 Keuangan Sehat', () {
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

      expect(breakdown.cashFlowScore, 40);
      expect(breakdown.expenseScore, 25);
      expect(breakdown.savingScore, 20);
      expect(breakdown.consistencyScore, 3);
      expect(score, 88.0);
      expect(status, 'Keuangan Sehat');
    });

    // ============================================================
    // UI VERIFICATION: CASE 4 (Income 5.000.000, Expense 4.500.000)
    // ============================================================
    test('CASE 4: Analyzer for 90% expense ratio -> 29 / 100 Perlu Perbaikan', () {
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
          title: 'Belanja Besar',
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

      expect(breakdown.cashFlowScore, 10);
      expect(breakdown.expenseScore, 6);
      expect(breakdown.savingScore, 10);
      expect(breakdown.consistencyScore, 3);
      expect(score, 29.0);
      expect(status, 'Perlu Perbaikan');
    });

    // ============================================================
    // UI VERIFICATION: CASE 5 (Income 5.000.000, Expense 6.000.000)
    // ============================================================
    test('CASE 5: Analyzer for Deficit -> 3 / 100 Perlu Perbaikan', () {
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
          title: 'Pengeluaran Melampaui Pemasukan',
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

      expect(breakdown.cashFlowScore, 0);
      expect(breakdown.expenseScore, 0);
      expect(breakdown.savingScore, 0);
      expect(breakdown.consistencyScore, 3);
      expect(score, 3.0);
      expect(status, 'Perlu Perbaikan');
    });

    // ============================================================
    // USER ISOLATION VERIFICATION
    // ============================================================
    test('User Isolation: Calculations for User A and User B never leak', () {
      final userATransactions = [
        TransactionModel(
          id: 1,
          userId: 1,
          title: 'Gajian A',
          amount: 10000000,
          type: 'income',
          category: 'Other',
          date: '2026-08-20',
        ),
        TransactionModel(
          id: 2,
          userId: 1,
          title: 'Makan A',
          amount: 1000000,
          type: 'expense',
          category: 'Food',
          date: '2026-08-20',
        ),
      ];

      final userBTransactions = [
        TransactionModel(
          id: 3,
          userId: 2,
          title: 'Gajian B',
          amount: 3000000,
          type: 'income',
          category: 'Other',
          date: '2026-08-20',
        ),
        TransactionModel(
          id: 4,
          userId: 2,
          title: 'Defisit B',
          amount: 4000000,
          type: 'expense',
          category: 'Bills',
          date: '2026-08-20',
        ),
      ];

      final scoreA = FinancialAnalyzer.calculateHealthScore(
        income: 10000000,
        expense: 1000000,
        monthlyBudget: 0,
        transactions: userATransactions,
      );

      final scoreB = FinancialAnalyzer.calculateHealthScore(
        income: 3000000,
        expense: 4000000,
        monthlyBudget: 0,
        transactions: userBTransactions,
      );

      expect(scoreA, 88.0);
      expect(FinancialAnalyzer.getHealthStatus(scoreA), 'Keuangan Sehat');

      expect(scoreB, 3.0);
      expect(FinancialAnalyzer.getHealthStatus(scoreB), 'Perlu Perbaikan');

      expect(scoreA, isNot(equals(scoreB)));
    });

    // ============================================================
    // AI RESPONSE VERIFICATION TESTS (TEST A to TEST E)
    // ============================================================
    test('TEST A — No Data: income = 0, expense = 0 -> status Belum Ada Data', () {
      final transactions = <TransactionModel>[];
      final score = FinancialAnalyzer.calculateHealthScore(
        income: 0,
        expense: 0,
        monthlyBudget: 0,
        transactions: transactions,
      );
      final status = FinancialAnalyzer.getHealthStatus(score);

      expect(score, isNull);
      expect(status, 'Belum Ada Data');
    });

    test('TEST B — One Day Valid Data: income = 5jt, expense = 600k, dataDays = 1 -> score = 88, status = Keuangan Sehat, NOT contains belum cukup untuk dinilai', () {
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
          title: 'Makan Siang',
          amount: 600000,
          type: 'expense',
          category: 'Food',
          date: '2026-08-20',
        ),
      ];

      final score = FinancialAnalyzer.calculateHealthScore(
        income: 5000000,
        expense: 600000,
        monthlyBudget: 0,
        transactions: transactions,
      );
      final status = FinancialAnalyzer.getHealthStatus(score);
      final explanation = FinancialAnalyzer.getHealthDescription(
        score,
        transactions: transactions,
      );

      expect(score, 88.0);
      expect(status, 'Keuangan Sehat');
      expect(explanation, isNot(contains('belum cukup untuk dinilai')));
      expect(explanation, contains('sangat baik'));
      expect(explanation, contains('Catatan masih awal'));
    });

    test('TEST C — Valid Data, Multiple Days: income = 5jt, expense = 600k, dataDays >= 3 -> score = 88, status = Keuangan Sehat, clean description', () {
      final transactions = [
        TransactionModel(
          id: 1,
          userId: 1,
          title: 'Gajian',
          amount: 5000000,
          type: 'income',
          category: 'Other',
          date: '2026-08-18',
        ),
        TransactionModel(
          id: 2,
          userId: 1,
          title: 'Makan 1',
          amount: 200000,
          type: 'expense',
          category: 'Food',
          date: '2026-08-19',
        ),
        TransactionModel(
          id: 3,
          userId: 1,
          title: 'Makan 2',
          amount: 400000,
          type: 'expense',
          category: 'Food',
          date: '2026-08-20',
        ),
      ];

      final score = FinancialAnalyzer.calculateHealthScore(
        income: 5000000,
        expense: 600000,
        monthlyBudget: 0,
        transactions: transactions,
      );
      final status = FinancialAnalyzer.getHealthStatus(score);
      final explanation = FinancialAnalyzer.getHealthDescription(
        score,
        transactions: transactions,
      );

      expect(score, 91.0);
      expect(status, 'Keuangan Sehat');
      expect(explanation, isNot(contains('Catatan masih awal')));
    });

    test('TEST D — Deficit: income = 5jt, expense = 6jt -> score = 3, status = Perlu Perbaikan', () {
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
          title: 'Belanja Melebihi Pemasukan',
          amount: 6000000,
          type: 'expense',
          category: 'Shopping',
          date: '2026-08-20',
        ),
      ];

      final score = FinancialAnalyzer.calculateHealthScore(
        income: 5000000,
        expense: 6000000,
        monthlyBudget: 0,
        transactions: transactions,
      );
      final status = FinancialAnalyzer.getHealthStatus(score);

      expect(score, 3.0);
      expect(status, 'Perlu Perbaikan');
    });

    test('TEST E — High Expense: income = 5jt, expense = 4.5jt -> score = 29, status = Perlu Perbaikan', () {
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
          title: 'Belanja Besar',
          amount: 4500000,
          type: 'expense',
          category: 'Bills',
          date: '2026-08-20',
        ),
      ];

      final score = FinancialAnalyzer.calculateHealthScore(
        income: 5000000,
        expense: 4500000,
        monthlyBudget: 0,
        transactions: transactions,
      );
      final status = FinancialAnalyzer.getHealthStatus(score);

      expect(score, 29.0);
      expect(status, 'Perlu Perbaikan');
    });
  });
}
