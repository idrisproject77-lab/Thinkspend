import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/goal_model.dart';
import 'package:thinkspend/models/transaction_model.dart';
import 'package:thinkspend/models/user_model.dart';
import 'package:thinkspend/services/financial_analyzer.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late Database inMemoryDb;

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
    inMemoryDb = await databaseFactoryFfi.openDatabase(
      inMemoryDatabasePath,
      options: OpenDatabaseOptions(
        version: 2,
        onCreate: (db, version) => DatabaseHelper.instance.createDBForTesting(db, version),
      ),
    );
    DatabaseHelper.setDatabaseForTesting(inMemoryDb);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await inMemoryDb.delete('transactions');
    await inMemoryDb.delete('goals');
    await inMemoryDb.delete('users');

    // Inisialisasi User A (id: 1) dan User B (id: 2)
    await DatabaseHelper.instance.insertUser(
      UserModel(
        id: 1,
        name: 'User A',
        email: 'usera@example.com',
        phone: '08123456781',
        password: 'password123',
        income: 5000000,
        monthlyBudget: 3000000,
      ),
    );

    await DatabaseHelper.instance.insertUser(
      UserModel(
        id: 2,
        name: 'User B',
        email: 'userb@example.com',
        phone: '08123456782',
        password: 'password123',
        income: 10000000,
        monthlyBudget: 6000000,
      ),
    );
  });

  tearDownAll(() async {
    await inMemoryDb.close();
    DatabaseHelper.setDatabaseForTesting(null);
  });

  group('ThinkSpend AI Live Data & Lifecycle Regression Tests (TEST 1 to TEST 10)', () {
    // ============================================================
    // TEST 1: Database berisi 3 transaksi -> AI membaca 3 transaksi
    // ============================================================
    test('TEST 1: AI reads 3 transactions on open', () async {
      await DatabaseHelper.instance.insertTransaction(
        TransactionModel(userId: 1, title: 'Gaji', amount: 5000000, category: 'Other', type: 'income', date: '2026-08-18'),
      );
      await DatabaseHelper.instance.insertTransaction(
        TransactionModel(userId: 1, title: 'Makan', amount: 150000, category: 'Food', type: 'expense', date: '2026-08-19'),
      );
      await DatabaseHelper.instance.insertTransaction(
        TransactionModel(userId: 1, title: 'Bensin', amount: 50000, category: 'Transport', type: 'expense', date: '2026-08-20'),
      );

      final summary = await FinancialAnalyzer.analyze(1);
      expect(summary.transactionCount, equals(3));
      expect(summary.income, equals(5000000));
      expect(summary.expense, equals(200000));
      expect(summary.balance, equals(4800000));
    });

    // ============================================================
    // TEST 2: Database berisi 3 target -> AI membaca 3 target
    // ============================================================
    test('TEST 2: AI reads 3 goals on open', () async {
      await DatabaseHelper.instance.insertGoal(
        GoalModel(userId: 1, name: 'Dana Darurat', targetAmount: 10000000, currentAmount: 3000000, deadline: '2026-12-31', priority: 'High'),
      );
      await DatabaseHelper.instance.insertGoal(
        GoalModel(userId: 1, name: 'Beli Laptop', targetAmount: 15000000, currentAmount: 5000000, deadline: '2026-11-30', priority: 'Medium'),
      );
      await DatabaseHelper.instance.insertGoal(
        GoalModel(userId: 1, name: 'Liburan', targetAmount: 5000000, currentAmount: 1000000, deadline: '2027-06-30', priority: 'Low'),
      );

      final summary = await FinancialAnalyzer.analyze(1);
      expect(summary.goals.length, equals(3));
      expect(summary.goals.map((g) => g.name).toList(), containsAll(['Dana Darurat', 'Beli Laptop', 'Liburan']));
    });

    // ============================================================
    // TEST 3: Tambah transaksi setelah AI dibuka -> Kembali ke AI -> AI update tanpa restart
    // ============================================================
    test('TEST 3: Add transaction updates AI without restart', () async {
      // 1. Initial state (kosong)
      var summary = await FinancialAnalyzer.analyze(1);
      expect(summary.transactionCount, equals(0));

      // 2. Tambah transaksi baru (simulasi user catat transaksi di tab Transaksi)
      await DatabaseHelper.instance.insertTransaction(
        TransactionModel(userId: 1, title: 'Bonus Project', amount: 3000000, category: 'Other', type: 'income', date: '2026-08-21'),
      );

      // 3. AI membaca data terbaru saat user kembali ke tab AI / bertanya ke AI
      summary = await FinancialAnalyzer.analyze(1);
      expect(summary.transactionCount, equals(1));
      expect(summary.income, equals(3000000));
      expect(summary.balance, equals(3000000));
    });

    // ============================================================
    // TEST 4: Edit transaksi -> Kembali ke AI -> AI membaca nominal baru
    // ============================================================
    test('TEST 4: Edit transaction reflects in AI without restart', () async {
      final txId = await DatabaseHelper.instance.insertTransaction(
        TransactionModel(userId: 1, title: 'Gaji Pokok', amount: 5000000, category: 'Other', type: 'income', date: '2026-08-20'),
      );

      var summary = await FinancialAnalyzer.analyze(1);
      expect(summary.income, equals(5000000));

      // Edit nominal transaksi dari 5.000.000 menjadi 8.000.000
      await DatabaseHelper.instance.updateTransaction(
        TransactionModel(id: txId, userId: 1, title: 'Gaji Pokok', amount: 8000000, category: 'Other', type: 'income', date: '2026-08-20'),
      );

      // AI otomatis membaca data termutakhir
      summary = await FinancialAnalyzer.analyze(1);
      expect(summary.income, equals(8000000));
      expect(summary.balance, equals(8000000));
    });

    // ============================================================
    // TEST 5: Delete transaksi -> Kembali ke AI -> AI membaca data setelah penghapusan
    // ============================================================
    test('TEST 5: Delete transaction reflects in AI without restart', () async {
      final txId = await DatabaseHelper.instance.insertTransaction(
        TransactionModel(userId: 1, title: 'Belanja Salah', amount: 2000000, category: 'Shopping', type: 'expense', date: '2026-08-20'),
      );

      var summary = await FinancialAnalyzer.analyze(1);
      expect(summary.expense, equals(2000000));

      // Hapus transaksi
      await DatabaseHelper.instance.deleteTransaction(txId, 1);

      // AI membaca data setelah penghapusan
      summary = await FinancialAnalyzer.analyze(1);
      expect(summary.expense, equals(0));
      expect(summary.transactionCount, equals(0));
    });

    // ============================================================
    // TEST 6: Tambah target -> Kembali ke AI -> AI membaca target terbaru
    // ============================================================
    test('TEST 6: Add goal reflects in AI without restart', () async {
      var summary = await FinancialAnalyzer.analyze(1);
      expect(summary.goals, isEmpty);

      // Tambah target
      await DatabaseHelper.instance.insertGoal(
        GoalModel(userId: 1, name: 'Beli Rumah', targetAmount: 500000000, currentAmount: 50000000, deadline: '2030-12-31', priority: 'High'),
      );

      // AI mendeteksi target baru
      summary = await FinancialAnalyzer.analyze(1);
      expect(summary.goals.length, equals(1));
      expect(summary.goals.first.name, equals('Beli Rumah'));
      expect(summary.goals.first.targetAmount, equals(500000000));
    });

    // ============================================================
    // TEST 7: Edit target -> Kembali ke AI -> AI membaca target yang diubah
    // ============================================================
    test('TEST 7: Edit goal reflects in AI without restart', () async {
      final goalId = await DatabaseHelper.instance.insertGoal(
        GoalModel(userId: 1, name: 'Mobil Lama', targetAmount: 200000000, currentAmount: 20000000, deadline: '2028-12-31', priority: 'High'),
      );

      var summary = await FinancialAnalyzer.analyze(1);
      expect(summary.goals.first.name, equals('Mobil Lama'));

      // Edit target
      await DatabaseHelper.instance.updateGoal(
        GoalModel(id: goalId, userId: 1, name: 'Mobil Baru Impian', targetAmount: 350000000, currentAmount: 350000000, deadline: '2028-12-31', priority: 'High'),
      );

      // AI membaca data target yang telah diupdate
      summary = await FinancialAnalyzer.analyze(1);
      expect(summary.goals.first.name, equals('Mobil Baru Impian'));
      expect(summary.goals.first.targetAmount, equals(350000000));
      expect(summary.goals.first.currentAmount, equals(350000000));
      expect(summary.goals.first.currentAmount / summary.goals.first.targetAmount, equals(1.0));
    });

    // ============================================================
    // TEST 8: Delete target -> Kembali ke AI -> AI membaca setelah penghapusan
    // ============================================================
    test('TEST 8: Delete goal reflects in AI without restart', () async {
      final goalId = await DatabaseHelper.instance.insertGoal(
        GoalModel(userId: 1, name: 'Target Batal', targetAmount: 10000000, currentAmount: 1000000, deadline: '2026-12-31', priority: 'Low'),
      );

      var summary = await FinancialAnalyzer.analyze(1);
      expect(summary.goals.length, equals(1));

      // Hapus target
      await DatabaseHelper.instance.deleteGoal(goalId, 1);

      // AI membaca target yang sudah dihapus
      summary = await FinancialAnalyzer.analyze(1);
      expect(summary.goals, isEmpty);
    });

    // ============================================================
    // TEST 9: User Isolation -> User A dan User B tidak saling melihat data
    // ============================================================
    test('TEST 9: User isolation between User A and User B in AI', () async {
      // User A (userId: 1) data
      await DatabaseHelper.instance.insertTransaction(
        TransactionModel(userId: 1, title: 'Gaji User A', amount: 5000000, category: 'Other', type: 'income', date: '2026-08-20'),
      );
      await DatabaseHelper.instance.insertGoal(
        GoalModel(userId: 1, name: 'Target User A', targetAmount: 10000000, currentAmount: 2000000, deadline: '2026-12-31'),
      );

      // User B (userId: 2) data
      await DatabaseHelper.instance.insertTransaction(
        TransactionModel(userId: 2, title: 'Gaji User B', amount: 15000000, category: 'Other', type: 'income', date: '2026-08-20'),
      );
      await DatabaseHelper.instance.insertGoal(
        GoalModel(userId: 2, name: 'Target User B', targetAmount: 50000000, currentAmount: 10000000, deadline: '2027-12-31'),
      );

      final summaryA = await FinancialAnalyzer.analyze(1);
      final summaryB = await FinancialAnalyzer.analyze(2);

      expect(summaryA.income, equals(5000000));
      expect(summaryA.goals.first.name, equals('Target User A'));

      expect(summaryB.income, equals(15000000));
      expect(summaryB.goals.first.name, equals('Target User B'));
    });

    // ============================================================
    // TEST 10: Financial Health di AI konsisten dengan FinancialAnalyzer
    // ============================================================
    test('TEST 10: Financial Health in AI matches FinancialAnalyzer SSOT', () async {
      await DatabaseHelper.instance.insertTransaction(
        TransactionModel(userId: 1, title: 'Income Rutin', amount: 6000000, category: 'Other', type: 'income', date: '2026-08-20'),
      );
      await DatabaseHelper.instance.insertTransaction(
        TransactionModel(userId: 1, title: 'Makan', amount: 1200000, category: 'Food', type: 'expense', date: '2026-08-20'),
      );

      final summary = await FinancialAnalyzer.analyze(1);
      final expectedStatus = FinancialAnalyzer.getHealthStatus(summary.healthScore);

      expect(summary.healthScore, isNotNull);
      expect(summary.healthStatus, equals(expectedStatus));
    });
  });
}
