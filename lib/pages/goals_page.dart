import 'package:flutter/material.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/goal_model.dart';
import 'package:thinkspend/models/user_model.dart';
import 'package:thinkspend/widgets/goal_card.dart';

import 'add_goal_page.dart';
import 'goal_detail_page.dart';

class GoalsPage extends StatefulWidget {
  final UserModel user;

  const GoalsPage({
    super.key,
    required this.user,
  });

  @override
  State<GoalsPage> createState() => _GoalsPageState();
}

class _GoalsPageState extends State<GoalsPage> {
  /// Objek Future disimpan sebagai variabel state untuk menjaga siklus hidup data.
  /// Hal ini mencegah FutureBuilder mengeksekusi ulang query SQLite getGoals() setiap kali widget di-rebuild.
  late Future<List<GoalModel>> _goalsFuture;

  @override
  void initState() {
    super.initState();
    _loadGoals();
  }

  void _loadGoals() {
    _goalsFuture = DatabaseHelper.instance.getGoals(
      widget.user.id!,
    );
  }

  /// Memperbarui _goalsFuture dan memicu re-render reaktif setelah operasi Create, Update, atau Delete.
  Future<void> _refreshGoals() async {
    setState(() {
      _loadGoals();
    });
    await _goalsFuture;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Target Tabungan'),
      ),

      /// FutureBuilder menangani 4 state asinkron pembacaan SQLite:
      /// 1. Loading state (ConnectionState.waiting): Menampilkan indikator loading saat query berjalan.
      /// 2. Error state (snapshot.hasError): Menampilkan pesan error dan opsi 'Coba Lagi'.
      /// 3. Data kosong state: Menampilkan layout informatif kosong yang tetap dapat di-refresh.
      /// 4. Data berhasil ditampilkan: Merender daftar kartu target tabungan secara reaktif.
      body: FutureBuilder<List<GoalModel>>(
        future: _goalsFuture,
        builder: (context, snapshot) {
          // 1. Loading state
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // 2. Error state
          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline,
                      size: 48,
                      color: Colors.red,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Terjadi kesalahan saat memuat data target:\n${snapshot.error}',
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.red),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: _refreshGoals,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Coba Lagi'),
                    ),
                  ],
                ),
              ),
            );
          }

          final goals = snapshot.data ?? [];

          // 3. Data kosong state
          if (goals.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshGoals,
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  physics: const AlwaysScrollableScrollPhysics(),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: const Center(
                      child: Text(
                        'Belum ada target tabungan.',
                        style: TextStyle(
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          }

          // 4. Data berhasil ditampilkan
          return RefreshIndicator(
            onRefresh: _refreshGoals,
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: goals.length,
              itemBuilder: (context, index) {
                final goal = goals[index];

                return GoalCard(
                  goal: goal,
                  onTap: () async {
                    final result = await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => GoalDetailPage(
                          goal: goal,
                        ),
                      ),
                    );

                    if (result == true) {
                      _refreshGoals();
                    }
                  },
                );
              },
            ),
          );
        },
      ),

      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => AddGoalPage(
                user: widget.user,
              ),
            ),
          );

          if (result == true) {
            _refreshGoals();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}