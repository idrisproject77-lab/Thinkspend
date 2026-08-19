import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thinkspend/models/goal_model.dart';
import 'package:thinkspend/models/transaction_model.dart';
import 'package:thinkspend/pages/login_page.dart';
import 'package:thinkspend/services/privacy_service.dart';
import 'package:thinkspend/services/theme_service.dart';
import 'package:thinkspend/utils/currency_formatter.dart';
import 'package:thinkspend/widgets/goal_card.dart';
import 'package:thinkspend/widgets/transaction_card.dart';

void main() {
  setUp(() {
    PrivacyService.instance.showAmounts();
  });

  testWidgets('TransactionCard renders transaction details and responds to PrivacyService', (WidgetTester tester) async {
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

    // Toggle Privacy to Hidden
    PrivacyService.instance.toggleVisibility();
    await tester.pump();

    expect(find.text('- ••••••••'), findsOneWidget);
    expect(find.text('- Rp 25.000'), findsNothing);

    // Toggle back to Visible
    PrivacyService.instance.toggleVisibility();
    await tester.pump();

    expect(find.text('- Rp 25.000'), findsOneWidget);
  });

  testWidgets('GoalCard renders goal details and responds to PrivacyService', (WidgetTester tester) async {
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
    expect(find.text('Rp 5.000.000'), findsOneWidget);
    expect(find.text('dari Rp 10.000.000'), findsOneWidget);

    // Toggle Privacy to Hidden
    PrivacyService.instance.hideAmounts();
    await tester.pump();

    expect(find.text('••••••••'), findsOneWidget);
    expect(find.text('dari ••••••••'), findsOneWidget);
    expect(find.text('50.0%'), findsOneWidget); // Percentage remains visible
    expect(find.text('High'), findsOneWidget); // Priority remains visible
  });

  testWidgets('LoginPage renders login fields', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: LoginPage(),
      ),
    );

    expect(find.byType(TextField), findsNWidgets(2));
  });

  test('ThemeService toggles theme modes properly', () {
    final themeService = ThemeService.instance;
    themeService.setThemeMode(ThemeMode.light);
    expect(themeService.themeMode, ThemeMode.light);
    expect(themeService.themeModeName, 'Terang');

    themeService.setThemeMode(ThemeMode.dark);
    expect(themeService.themeMode, ThemeMode.dark);
    expect(themeService.themeModeName, 'Gelap');

    themeService.setThemeMode(ThemeMode.system);
    expect(themeService.themeMode, ThemeMode.system);
    expect(themeService.themeModeName, 'Ikuti Sistem');
  });

  test('PrivacyService state management and formatRupiah masking work correctly', () {
    final privacy = PrivacyService.instance;

    // 1. Default visibility
    privacy.showAmounts();
    expect(privacy.isAmountVisible, true);
    expect(formatRupiah(50000), 'Rp 50.000');

    // 2. Toggle to hidden
    privacy.toggleVisibility();
    expect(privacy.isAmountVisible, false);
    expect(formatRupiah(50000), '••••••••');

    // 3. Toggle back to visible
    privacy.toggleVisibility();
    expect(privacy.isAmountVisible, true);
    expect(formatRupiah(50000), 'Rp 50.000');

    // 4. hideAmounts and showAmounts explicit methods
    privacy.hideAmounts();
    expect(privacy.isAmountVisible, false);
    expect(formatRupiah(1250000), '••••••••');

    privacy.showAmounts();
    expect(privacy.isAmountVisible, true);
    expect(formatRupiah(1250000), 'Rp 1.250.000');
  });
}
