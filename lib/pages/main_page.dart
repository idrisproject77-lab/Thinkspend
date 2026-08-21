import 'package:flutter/material.dart';
import 'package:thinkspend/models/user_model.dart';
import 'package:thinkspend/services/session_service.dart';
import 'package:thinkspend/views/profile_page.dart';

import 'login_page.dart';
import 'home_page.dart' as home;
import 'transactions_page.dart' as transaction;
import 'goals_page.dart' as goal;
import 'ai_page.dart';

/// Shell utama aplikasi ThinkSpend dengan Bottom Navigation Bar 5 tab:
/// 1. Beranda (index 0) - Ringkasan saldo, statistik, dan pintasan cepat.
/// 2. Transaksi (index 1) - Riwayat dan filter pemasukan/pengeluaran.
/// 3. Target (index 2) - Manajemen tujuan dan perencanaan tabungan.
/// 4. AI (index 3) - Chatbot asisten finansial berbasis AI.
/// 5. Profil (index 4) - Pengaturan akun, tema, privasi, dan info aplikasi.
///
/// Mengintegrasikan [SessionService] untuk menyimpan dan memulihkan tab terakhir yang dibuka.
class MainPage extends StatefulWidget {
  final UserModel user;
  final int initialIndex;

  const MainPage({
    super.key,
    required this.user,
    this.initialIndex = 0,
  });

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  late int currentIndex;

  @override
  void initState() {
    super.initState();
    // BAGAIMANA CURRENT INDEX DIPULIHKAN:
    // Menggunakan index halaman yang diteruskan saat inisialisasi MainPage
    // (didapat dari SharedPreferences) dengan validasi rentang yang aman (0..4).
    currentIndex = (widget.initialIndex >= 0 && widget.initialIndex <= 4)
        ? widget.initialIndex
        : 0;
  }

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

    // BAGAIMANA LOGOUT MEMBERSIHKAN SESSION:
    // Hapus sesi login dan reset index halaman terakhir sebelum kembali ke LoginPage.
    await SessionService.instance.clearSession();

    if (!mounted) return;

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
      // 3. THINKSPEND AI
      // ========================================================
      AiPage(
        userId: widget.user.id!,
        userName: widget.user.name,
        isActive: currentIndex == 3,
      ),

      // ========================================================
      // 4. PROFIL
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
          // BAGAIMANA CURRENT INDEX DISIMPAN:
          // Menyimpan index tab terakhir yang dipilih ke SharedPreferences secara asinkron.
          SessionService.instance.saveLastPage(index);
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

          NavigationDestination(
            icon: Icon(Icons.auto_awesome_outlined),
            selectedIcon: Icon(Icons.auto_awesome),
            label: 'AI',
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
