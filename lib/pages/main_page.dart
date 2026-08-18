import 'package:flutter/material.dart';
import 'package:thinkspend/models/user_model.dart';

import 'login_page.dart';
import 'home_page.dart' as home;
import 'transactions_page.dart' as transaction;
import 'statistics_page.dart' as statistics;
import 'goals_page.dart' as goal;
import 'ai_page.dart' as ai;

class MainPage extends StatefulWidget {
  final UserModel user;

  const MainPage({super.key, required this.user});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;

  int aiRefreshKey = 0;

  // ============================================================
  // LOGOUT
  // ============================================================

  Future<void> logout() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Logout?'),

          content: const Text('Apakah kamu yakin ingin keluar dari akun ini?'),

          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context, false);
              },

              child: const Text('Batal'),
            ),

            ElevatedButton(
              onPressed: () {
                Navigator.pop(context, true);
              },

              child: const Text('Logout'),
            ),
          ],
        );
      },
    );

    if (confirm != true || !mounted) {
      return;
    }

    Navigator.pushAndRemoveUntil(
      context,

      MaterialPageRoute(builder: (context) => const LoginPage()),

      (route) => false,
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    final pages = <Widget>[
      // ========================================================
      // 0. HOME
      // ========================================================
      home.HomePage(user: widget.user, onLogout: logout),

      // ========================================================
      // 1. TRANSAKSI
      // ========================================================
      transaction.TransactionsPage(user: widget.user),

      // ========================================================
      // 2. STATISTIK
      // ========================================================
      statistics.StatisticsPage(user: widget.user),

      // ========================================================
      // 3. TARGET
      // ========================================================
      goal.GoalsPage(user: widget.user),

      // ========================================================
      // 4. THINKSPEND AI
      // ========================================================
      ai.AiPage(
        key: ValueKey(aiRefreshKey),
        userId: widget.user.id!,
        userName: widget.user.name,
      ),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('ThinkSpend')),

      body: IndexedStack(index: currentIndex, children: pages),

      // ========================================================
      // BOTTOM NAVIGATION
      // ========================================================
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,

        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;

            if (index == 4) {
              aiRefreshKey++;
            }
          });
        },

        destinations: const [
          // ====================================================
          // HOME
          // ====================================================
          NavigationDestination(
            icon: Icon(Icons.home_outlined),

            selectedIcon: Icon(Icons.home),

            label: 'Home',
          ),

          // ====================================================
          // TRANSAKSI
          // ====================================================
          NavigationDestination(
            icon: Icon(Icons.receipt_long_outlined),

            selectedIcon: Icon(Icons.receipt_long),

            label: 'Transaksi',
          ),

          // ====================================================
          // STATISTIK
          // ====================================================
          NavigationDestination(
            icon: Icon(Icons.bar_chart_outlined),

            selectedIcon: Icon(Icons.bar_chart),

            label: 'Statistik',
          ),

          // ====================================================
          // TARGET
          // ====================================================
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),

            selectedIcon: Icon(Icons.flag),

            label: 'Target',
          ),

          // ====================================================
          // AI
          // ====================================================
          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),

            selectedIcon: Icon(Icons.auto_awesome),

            label: 'AI',
          ),
        ],
      ),
    );
  }
}
