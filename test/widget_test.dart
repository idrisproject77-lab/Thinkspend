import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:thinkspend/models/goal_model.dart';
import 'package:thinkspend/models/transaction_model.dart';
import 'package:thinkspend/pages/login_page.dart';
import 'package:thinkspend/pages/transaction_detail_page.dart';
import 'package:thinkspend/services/privacy_service.dart';
import 'package:thinkspend/services/theme_service.dart';
import 'package:thinkspend/utils/currency_formatter.dart';
import 'package:thinkspend/views/about_page.dart';
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

  test('Category grouping correctly sums duplicate categories, calculates percentages and sorts descending', () {
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
      TransactionModel(
        id: 3,
        userId: 1,
        title: 'Gojek 1',
        amount: 75000,
        type: 'expense',
        category: 'Transport',
        date: '2026-08-20',
      ),
      TransactionModel(
        id: 4,
        userId: 1,
        title: 'Gojek 2',
        amount: 75000,
        type: 'expense',
        category: ' transport ',
        date: '2026-08-20',
      ),
    ];

    double totalIncome = 0;
    double totalExpense = 0;
    final Map<String, double> categoryTotals = {};

    String normalizeCategory(String rawCategory) {
      final trimmed = rawCategory.trim();
      if (trimmed.isEmpty) return 'Other';
      const standardCategories = ['Food', 'Transport', 'Shopping', 'Bills', 'Entertainment', 'Other'];
      for (final standard in standardCategories) {
        if (standard.toLowerCase() == trimmed.toLowerCase()) return standard;
      }
      return '${trimmed[0].toUpperCase()}${trimmed.substring(1)}';
    }

    for (final tx in transactions) {
      if (tx.type == 'income') {
        totalIncome += tx.amount;
      }
      if (tx.type == 'expense') {
        totalExpense += tx.amount;
        final cat = normalizeCategory(tx.category);
        categoryTotals[cat] = (categoryTotals[cat] ?? 0) + tx.amount;
      }
    }

    final sortedCategories = categoryTotals.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    expect(totalIncome, 5000000);
    expect(totalExpense, 750000);
    expect(sortedCategories.length, 2);

    // Food
    expect(sortedCategories[0].key, 'Food');
    expect(sortedCategories[0].value, 600000);
    final foodPercent = (sortedCategories[0].value / totalExpense) * 100;
    expect(foodPercent, 80.0);

    // Transport (75k + 75k = 150k, only 1 item)
    expect(sortedCategories[1].key, 'Transport');
    expect(sortedCategories[1].value, 150000);
    final transportPercent = (sortedCategories[1].value / totalExpense) * 100;
    expect(transportPercent, 20.0);
  });

  testWidgets('TransactionDetailPage renders properly and responds to PrivacyService', (WidgetTester tester) async {
    final transaction = TransactionModel(
      id: 1,
      userId: 1,
      title: 'Makan Siang Enak',
      amount: 45000,
      category: 'Food',
      type: 'expense',
      date: '2026-08-20',
      notes: 'Traktir kawan',
    );

    await tester.pumpWidget(
      MaterialApp(
        home: TransactionDetailPage(transaction: transaction),
      ),
    );

    // Header & Summary Card
    expect(find.text('Detail Transaksi'), findsOneWidget);
    expect(find.text('Makan Siang Enak'), findsOneWidget);
    expect(find.text('Pengeluaran'), findsNWidgets(2)); // Badge and InfoRow
    expect(find.text('- Rp 45.000'), findsOneWidget);

    // Information Section
    expect(find.text('Informasi Transaksi'), findsOneWidget);
    expect(find.text('Food'), findsOneWidget);
    expect(find.text('20 Agustus 2026'), findsOneWidget);
    expect(find.text('Traktir kawan'), findsOneWidget);

    // Action Buttons
    expect(find.text('Edit Transaksi'), findsOneWidget);
    expect(find.text('Hapus'), findsOneWidget);

    // Toggle Privacy to Hidden
    PrivacyService.instance.hideAmounts();
    await tester.pump();

    expect(find.text('- ••••••••'), findsOneWidget);
    expect(find.text('- Rp 45.000'), findsNothing);

    // Toggle Privacy to Visible
    PrivacyService.instance.showAmounts();
    await tester.pump();

    expect(find.text('- Rp 45.000'), findsOneWidget);
  });

  testWidgets('AboutPage renders ThinkSpend branding, logo, about content, and features', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: AboutPage(),
      ),
    );

    // AppBar
    expect(find.text('Tentang ThinkSpend'), findsOneWidget);

    // Brand Name and Tagline
    expect(find.textContaining('Think', findRichText: true), findsWidgets);
    expect(find.textContaining('Spend', findRichText: true), findsWidgets);
    expect(find.text('Kelola keuangan dengan lebih bijak.'), findsOneWidget);

    // About Section
    expect(find.text('Tentang Aplikasi'), findsOneWidget);
    expect(
      find.text(
        'ThinkSpend adalah aplikasi pengelolaan keuangan yang membantu pengguna mencatat transaksi, memahami pola pengeluaran, serta memantau kondisi keuangan secara lebih sederhana dan terarah.',
      ),
      findsOneWidget,
    );

    // Feature Section
    expect(find.text('Fitur Utama'), findsOneWidget);
    expect(find.text('Pencatatan Transaksi'), findsOneWidget);
    expect(find.text('Catat pemasukan dan pengeluaran.'), findsOneWidget);
    expect(find.text('Financial Insight'), findsOneWidget);
    expect(find.text('Pahami kondisi dan kebiasaan keuangan.'), findsOneWidget);
    expect(find.text('Financial Health'), findsOneWidget);
    expect(
      find.text(
        'Pantau kesehatan keuangan dan dapatkan rekomendasi untuk keputusan yang lebih baik.',
      ),
      findsOneWidget,
    );

    // Footer
    expect(find.text('Versi 1.0.0'), findsOneWidget);
    expect(find.text('© 2026 ThinkSpend'), findsOneWidget);

    // Logo image is loaded
    expect(find.byType(Image), findsOneWidget);
  });
}


