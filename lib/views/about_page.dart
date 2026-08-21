import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinkspend/services/theme_service.dart';

/// Halaman informasi aplikasi "Tentang ThinkSpend".
///
/// Menampilkan identitas visual ThinkSpend, visi aplikasi, rincian fitur utama
/// (Pencatatan Transaksi, Financial Insight, Financial Health), dan informasi versi.
class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        title: Text(
          'Tentang ThinkSpend',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary(context),
          ),
        ),
        centerTitle: true,
        elevation: 0,
        scrolledUnderElevation: 0,
        backgroundColor: AppColors.background(context),
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 20,
            color: AppColors.textPrimary(context),
          ),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // ==================================================
            // LOGO THINKSPEND
            // ==================================================
            Container(
              width: 84,
              height: 84,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColors.border(context),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withValues(alpha: 0.25)
                        : const Color(0xFF0F172A).withValues(alpha: 0.06),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.asset(
                  'assets/images/Logo TS.jpg',
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(
                      Icons.account_balance_wallet_rounded,
                      color: AppColors.primaryBlue,
                      size: 40,
                    );
                  },
                ),
              ),
            ),
            const SizedBox(height: 16),

            // ==================================================
            // NAMA APLIKASI
            // ==================================================
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Think',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: isDark
                          ? AppColors.darkTextPrimary
                          : const Color(0xFF0F172A),
                      letterSpacing: -0.5,
                    ),
                  ),
                  TextSpan(
                    text: 'Spend',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryBlue,
                      letterSpacing: -0.5,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 6),

            // ==================================================
            // TAGLINE
            // ==================================================
            Text(
              'Kelola keuangan dengan lebih bijak.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w400,
                color: AppColors.textSecondary(context),
              ),
            ),
            const SizedBox(height: 28),

            // ==================================================
            // CARD: TENTANG APLIKASI
            // ==================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.border(context),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.transparent
                        : const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tentang Aplikasi',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'ThinkSpend adalah aplikasi pengelolaan keuangan yang membantu pengguna mencatat transaksi, memahami pola pengeluaran, serta memantau kondisi keuangan secara lebih sederhana dan terarah.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                      height: 1.6,
                      color: AppColors.textSecondary(context),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ==================================================
            // CARD: FITUR UTAMA
            // ==================================================
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.surface(context),
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: AppColors.border(context),
                  width: 1,
                ),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.transparent
                        : const Color(0xFF0F172A).withValues(alpha: 0.03),
                    blurRadius: 10,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Fitur Utama',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary(context),
                      letterSpacing: -0.2,
                    ),
                  ),
                  const SizedBox(height: 18),
                  _buildFeatureItem(
                    context: context,
                    icon: Icons.receipt_long_outlined,
                    title: 'Pencatatan Transaksi',
                    description: 'Catat pemasukan dan pengeluaran.',
                    isDark: isDark,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Divider(
                      color: AppColors.border(context),
                      height: 1,
                      thickness: 1,
                    ),
                  ),
                  _buildFeatureItem(
                    context: context,
                    icon: Icons.insights_outlined,
                    title: 'Financial Insight',
                    description: 'Pahami kondisi dan kebiasaan keuangan.',
                    isDark: isDark,
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Divider(
                      color: AppColors.border(context),
                      height: 1,
                      thickness: 1,
                    ),
                  ),
                  _buildFeatureItem(
                    context: context,
                    icon: Icons.health_and_safety_outlined,
                    title: 'Financial Health',
                    description:
                        'Pantau kesehatan keuangan dan dapatkan rekomendasi untuk keputusan yang lebih baik.',
                    isDark: isDark,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // ==================================================
            // VERSI & COPYRIGHT
            // ==================================================
            Text(
              'Versi 1.0.0',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.muted(context),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '© 2026 ThinkSpend',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w400,
                color: AppColors.muted(context),
              ),
            ),
            const SizedBox(height: 12),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String description,
    required bool isDark,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColors.primaryBlue.withValues(alpha: isDark ? 0.16 : 0.08),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(
            icon,
            size: 20,
            color: AppColors.primaryBlue,
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary(context),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w400,
                  height: 1.45,
                  color: AppColors.textSecondary(context),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}