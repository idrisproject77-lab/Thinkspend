import 'package:flutter/material.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tentang ThinkSpend',
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [
            // ==================================================
            // LOGO
            // ==================================================

            CircleAvatar(
              radius: 50,

              child: const Icon(
                Icons.account_balance_wallet_outlined,
                size: 50,
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // NAMA APLIKASI
            // ==================================================

            const Text(
              'ThinkSpend',

              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              'Kelola keuangan dengan lebih bijak.',
              textAlign: TextAlign.center,

              style: TextStyle(
                fontSize: 16,
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 32),

            // ==================================================
            // TENTANG APLIKASI
            // ==================================================

            Card(
              child: Padding(
                padding: const EdgeInsets.all(20),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [
                    const Text(
                      'Tentang Aplikasi',

                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),

                    const SizedBox(height: 12),

                    const Text(
                      'ThinkSpend adalah aplikasi pengelolaan '
                      'keuangan yang membantu pengguna mencatat '
                      'transaksi, memahami pola pengeluaran, '
                      'serta memantau kondisi keuangan secara '
                      'lebih sederhana dan terarah.',
                      
                      style: TextStyle(
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // FITUR
            // ==================================================

            Card(
              child: Column(
                children: [
                  const ListTile(
                    leading: Icon(
                      Icons.receipt_long_outlined,
                    ),

                    title: Text(
                      'Pencatatan Transaksi',
                    ),

                    subtitle: Text(
                      'Catat pemasukan dan pengeluaran.',
                    ),
                  ),

                  const Divider(
                    height: 1,
                  ),

                  const ListTile(
                    leading: Icon(
                      Icons.insights_outlined,
                    ),

                    title: Text(
                      'Financial Insight',
                    ),

                    subtitle: Text(
                      'Pahami kondisi dan kebiasaan keuangan.',
                    ),
                  ),

                  const Divider(
                    height: 1,
                  ),

                  const ListTile(
                    leading: Icon(
                      Icons.health_and_safety_outlined,
                    ),

                    title: Text(
                      'Financial Health',
                    ),

                    subtitle: Text(
                      'Pantau kesehatan keuangan secara berkala.',
                    ),
                  ),

                  const Divider(
                    height: 1,
                  ),

                  const ListTile(
                    leading: Icon(
                      Icons.savings_outlined,
                    ),

                    title: Text(
                      'Saving Planner',
                    ),

                    subtitle: Text(
                      'Bantu merencanakan dan mencapai target tabungan.',
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // VERSI
            // ==================================================

            const Text(
              'Versi 1.0.0',

              style: TextStyle(
                color: Colors.grey,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              '© 2026 ThinkSpend',
              
              style: TextStyle(
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}