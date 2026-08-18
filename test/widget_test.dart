import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thinkspend/models/goal_model.dart';
import 'package:thinkspend/models/transaction_model.dart';
import 'package:thinkspend/pages/login_page.dart';
import 'package:thinkspend/widgets/goal_card.dart';
import 'package:thinkspend/widgets/transaction_card.dart';

void main() {
  testWidgets('TransactionCard renders transaction details', (WidgetTester tester) async {
    final transaction = TransactionModel(
      id: 1,
      userId: 1,
      title: 'Beli Kopi',
      amount: 25000,
      category: 'Makanan',
      type: 'expense',
      date: '2026-08-18',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TransactionCard(transaction: transaction),
        ),
      ),
    );

    expect(find.text('Beli Kopi'), findsOneWidget);
    expect(find.text('- Rp 25.000'), findsOneWidget);
  });

  testWidgets('GoalCard renders goal details and progress', (WidgetTester tester) async {
    final goal = GoalModel(
      id: 1,
      userId: 1,
      name: 'Beli Laptop',
      targetAmount: 10000000,
      currentAmount: 5000000,
      priority: 'High',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: GoalCard(goal: goal),
        ),
      ),
    );

    expect(find.text('Beli Laptop'), findsOneWidget);
    expect(find.text('High'), findsOneWidget);
    expect(find.text('50.0%'), findsOneWidget);
  });

  testWidgets('LoginPage renders login fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(),
      ),
    );

    expect(find.byType(TextField), findsNWidgets(2));
  });
}
