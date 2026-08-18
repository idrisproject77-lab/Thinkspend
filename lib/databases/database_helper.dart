import 'package:flutter/foundation.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import 'package:thinkspend/models/goal_model.dart';
import '../models/user_model.dart';
import '../models/transaction_model.dart';

/// Helper singleton untuk mengelola SQLite database ThinkSpend.
/// Pola Singleton memastikan hanya ada satu koneksi database yang aktif
/// di seluruh lifecycle aplikasi guna mencegah data lock dan inkonsistensi.
class DatabaseHelper {
  static final DatabaseHelper instance =
      DatabaseHelper._init();

  static Database? _database;

  DatabaseHelper._init();

  /// Getter database asinkron: membuka koneksi baru jika belum ada (lazy initialization).
  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDB('thinkspend.db');

    return _database!;
  }

  /// Inisialisasi file database SQLite pada path sistem perangkat dan menangani migrasi versi.
  Future<Database> _initDB(String filePath) async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, filePath);

    return await openDatabase(
      path,

      // DATABASE VERSION BARU
      version: 2,

      onCreate: _createDB,

      // Migrasi database: jika ada pembaruan versi skema, tabel lama dihapus dan dibuat ulang.
      onUpgrade: (db, oldVersion, newVersion) async {
        await db.execute(
          'DROP TABLE IF EXISTS transactions',
        );

        await db.execute(
          'DROP TABLE IF EXISTS goals',
        );

        await db.execute(
          'DROP TABLE IF EXISTS users',
        );

        await _createDB(db, newVersion);
      },
    );
  }

  // ============================================================
  // CREATE DATABASE
  // ============================================================

  Future<void> _createDB(
    Database db,
    int version,
  ) async {
    // ----------------------------------------------------------
    // USERS
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE users (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        name TEXT NOT NULL,
        email TEXT NOT NULL UNIQUE,
        phone TEXT NOT NULL,
        password TEXT NOT NULL,
        income REAL DEFAULT 0,
        monthly_budget REAL DEFAULT 0
      )
    ''');

    // ----------------------------------------------------------
    // TRANSACTIONS
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE transactions (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        title TEXT NOT NULL,
        amount REAL NOT NULL,
        category TEXT NOT NULL,
        type TEXT NOT NULL,
        date TEXT NOT NULL,
        notes TEXT
      )
    ''');

    // ----------------------------------------------------------
    // GOALS
    // ----------------------------------------------------------

    await db.execute('''
      CREATE TABLE goals (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        user_id INTEGER NOT NULL,
        name TEXT NOT NULL,
        target_amount REAL NOT NULL,
        current_amount REAL DEFAULT 0,
        deadline TEXT,
        priority TEXT
      )
    ''');
  }

  // ============================================================
  // USER
  // ============================================================

  Future<int> insertUser(
    UserModel user,
  ) async {
    final db = await database;

    return await db.insert(
      'users',
      user.toMap(),
    );
  }

  Future<List<UserModel>> getUsers() async {
    final db = await database;

    final result =
        await db.query('users');

    return result.map((map) {
      return UserModel.fromMap(map);
    }).toList();
  }

  Future<UserModel?> loginUser(
    String email,
    String password,
  ) async {
    final db = await database;

    final result = await db.query(
      'users',
      where: 'email = ? AND password = ?',
      whereArgs: [
        email,
        password,
      ],
      limit: 1,
    );

    if (result.isEmpty) {
      return null;
    }

    return UserModel.fromMap(
      result.first,
    );
  }

  Future<int> updateUser(
    UserModel user,
  ) async {
    final db = await database;

    return await db.update(
      'users',
      user.toMap(),
      where: 'id = ?',
      whereArgs: [user.id],
    );
  }

  Future<int> deleteUser(
    int id,
  ) async {
    final db = await database;

    return await db.delete(
      'users',
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  // ============================================================
  // TRANSACTION
  // ============================================================

  Future<int> insertTransaction(
    TransactionModel transaction,
  ) async {
    final db = await database;

    return await db.insert(
      'transactions',
      transaction.toMap(),
    );
  }

  /// Mengambil daftar transaksi yang difilter khusus berdasarkan user_id aktif.
  Future<List<TransactionModel>> getTransactions(
    int userId,
  ) async {
    final db = await database;

    final result = await db.query(
      'transactions',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id ASC',
    );

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
      where: 'id = ? AND user_id = ?',
      whereArgs: [
        transaction.id,
        transaction.userId,
      ],
    );
  }

  Future<int> deleteTransaction(
    int id,
    int userId,
  ) async {
    final db = await database;

    return await db.delete(
      'transactions',
      where: 'id = ? AND user_id = ?',
      whereArgs: [
        id,
        userId,
      ],
    );
  }

  // ============================================================
  // GOALS
  // ============================================================

  Future<int> insertGoal(
    GoalModel goal,
  ) async {
    final db = await database;

    return await db.insert(
      'goals',
      goal.toMap(),
    );
  }

  /// Mengambil daftar target tabungan yang difilter khusus berdasarkan user_id aktif.
  Future<List<GoalModel>> getGoals(
    int userId,
  ) async {
    final db = await database;

    final result = await db.query(
      'goals',
      where: 'user_id = ?',
      whereArgs: [userId],
      orderBy: 'id ASC',
    );

    return result.map((map) {
      return GoalModel.fromMap(map);
    }).toList();
  }

  Future<int> updateGoal(
    GoalModel goal,
  ) async {
    final db = await database;

    return await db.update(
      'goals',
      goal.toMap(),
      where: 'id = ? AND user_id = ?',
      whereArgs: [
        goal.id,
        goal.userId,
      ],
    );
  }

  Future<int> deleteGoal(
    int id,
    int userId,
  ) async {
    final db = await database;

    return await db.delete(
      'goals',
      where: 'id = ? AND user_id = ?',
      whereArgs: [
        id,
        userId,
      ],
    );
  }

  // ============================================================
  // TEST DATABASE
  // ============================================================

  Future<void> testDatabase() async {
    final db = await database;

    final tables = await db.rawQuery(
      "SELECT name FROM sqlite_master "
      "WHERE type='table'",
    );

    debugPrint(
      'DATABASE THINKSPEND BERHASIL DIBUKA',
    );

    debugPrint(
      'TABLES: $tables',
    );
  }
  Future<bool> isEmailRegistered(String email) async {
  final db = await database;

  final result = await db.query(
    'users',
    columns: ['id'],
    where: 'email = ?',
    whereArgs: [email],
    limit: 1,
  );

  return result.isNotEmpty;
}
}