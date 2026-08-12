import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import '../models/goal_model.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('thinkspend.db');
    return _database!;
  }

  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,
      version: 1,
      onCreate: _createDB,
    );
  }

  Future<void> _createDB(Database db, int version) async {
    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL,
        phone TEXT NOT NULL,
        password TEXT NOT NULL,
        income REAL DEFAULT 0,
        monthly_budget REAL DEFAULT 0
      )
    ''');

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT
      )
    ''');

    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL DEFAULT 0,
        deadline TEXT,
        priority TEXT
      )
    ''');
  }

  Future<void> testDatabase() async {
    final db = await database;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master WHERE type='table'",
    );

    print('DATABASE THINKSPEND BERHASIL DIBUKA');
    print('TABLES: $tables');
  }

  Future<int> insertUser(UserModel user) async {
  final db = await database;

  return await db.insert(
    'users',
    user.toMap(),
  );
}

Future<List<UserModel>> getUsers() async {
  final db = await database;

  final result = await db.query('users');

  return result.map((map) {
    return UserModel.fromMap(map);
  }).toList();
}
Future<int> updateUser(UserModel user) async {
  final db = await database;

  return await db.update(
    'users',
    user.toMap(),
    where: 'id = ?',
    whereArgs: [user.id],
  );
}
Future<int> deleteUser(int id) async {
  final db = await database;

  return await db.delete(
    'users',
    where: 'id = ?',
    whereArgs: [id],
  );
}
Future<int> insertTransaction(TransactionModel transaction) async {
  final db = await database;

  return await db.insert(
    'transactions',
    transaction.toMap(),
  );
  
}
Future<List<TransactionModel>> getTransactions() async {
  final db = await database;

  final result = await db.query('transactions');

  return result.map((map) {
    return TransactionModel.fromMap(map);
  }).toList();
}
Future<int> updateTransaction(
  TransactionModel transaction,
) async {
  final db = await database;

  return await db.update(
    'transactions',
    transaction.toMap(),
    where: 'id = ?',
    whereArgs: [transaction.id],
  );

}
Future<int> deleteTransaction(int id) async {
  final db = await database;

  return await db.delete(
    'transactions',
    where: 'id = ?',
    whereArgs: [id],
  );
}

Future<int> insertGoal(GoalModel goal) async {
  final db = await database;

  return await db.insert(
    'goals',
    goal.toMap(),
  );
}

Future<List<GoalModel>> getGoals() async {
  final db = await database;

  final result = await db.query('goals');

  return result.map((map) {
    return GoalModel.fromMap(map);
  }).toList();
}

Future<int> updateGoal(GoalModel goal) async {
  final db = await database;

  return await db.update(
    'goals',
    goal.toMap(),
    where: 'id = ?',
    whereArgs: [goal.id],
  );
}

Future<int> deleteGoal(int id) async {
  final db = await database;

  return await db.delete(
    'goals',
    where: 'id = ?',
    whereArgs: [id],
  );
}
}