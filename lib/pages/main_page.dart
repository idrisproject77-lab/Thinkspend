import 'package:flutter/material.dart';
import 'package:thinkspend/models/user_model.dart';
import 'package:thinkspend/views/profile_page.dart';

import 'login_page.dart';
import 'home_page.dart' as home;
import 'transactions_page.dart' as transaction;
import 'goals_page.dart' as goal;

class MainPage extends StatefulWidget {
  final UserModel user;

  const MainPage({super.key, required this.user});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int currentIndex = 0;

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
      // 0. BERANDA
      // ========================================================
      home.HomePage(user: widget.user, onLogout: logout),

      // ========================================================
      // 1. TRANSAKSI (RIWAYAT & STATISTIK)
      // ========================================================
      transaction.TransactionsPage(user: widget.user),

      // ========================================================
      // 2. TARGET
      // ========================================================
      goal.GoalsPage(user: widget.user),

      // ========================================================
      // 3. PROFIL
      // ========================================================
      ProfilePage(user: widget.user, onLogout: logout),
    ];

    return Scaffold(
      body: IndexedStack(index: currentIndex, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            currentIndex = index;
          });
        },
        destinations: const [
          // ====================================================
          // BERANDA
          // ====================================================
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home),
            label: 'Beranda',
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
          // TARGET
          // ====================================================
          NavigationDestination(
            icon: Icon(Icons.flag_outlined),
            selectedIcon: Icon(Icons.flag),
            label: 'Target',
          ),

          // ====================================================
          // PROFIL
          // ====================================================
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Profil',
          ),
        ],
      ),
    );
  }
}
