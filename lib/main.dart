import 'package:flutter/material.dart';
import 'databases/database_helper.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final database = DatabaseHelper.instance;

  // READ goal yang sudah ada
  final goals = await database.getGoals();

  if (goals.isNotEmpty) {
    final goal = goals.first;

    print('DATA GOAL SEBELUM DELETE:');
    print(goal.toMap());

    // DELETE goal berdasarkan ID
    final result = await database.deleteGoal(
      goal.id!,
    );

    print('JUMLAH GOAL YANG DIHAPUS: $result');

    // READ kembali setelah DELETE
    final remainingGoals = await database.getGoals();

    print(
      'JUMLAH GOAL SETELAH DELETE: '
      '${remainingGoals.length}',
    );

    print('DATA GOAL SETELAH DELETE:');

    for (final goal in remainingGoals) {
      print(goal.toMap());
    }
  } else {
    print('TIDAK ADA GOAL UNTUK DIHAPUS');
  }

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'ThinkSpend',
      home: Scaffold(
        appBar: AppBar(
          title: const Text('ThinkSpend'),
        ),
        body: const Center(
          child: Text(
            'Goal DELETE sedang diuji.\n'
            'Cek hasilnya di terminal.',
            textAlign: TextAlign.center,
          ),
        ),
      ),
    );
  }
}