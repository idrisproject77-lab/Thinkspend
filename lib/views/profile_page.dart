import 'package:flutter/material.dart';
import 'package:thinkspend/models/user_model.dart';
import 'package:thinkspend/services/privacy_service.dart';
import 'package:thinkspend/services/theme_service.dart';
import 'package:thinkspend/views/edit_profile_page.dart';
import 'package:thinkspend/views/change_password_page.dart';
import 'package:thinkspend/views/about_page.dart';

class ProfilePage extends StatelessWidget {
  final UserModel user;
  final VoidCallback onLogout;

  const ProfilePage({super.key, required this.user, required this.onLogout});

  void _showThemeDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) {
        final currentMode = ThemeService.instance.themeMode;

        return AlertDialog(
          title: Text(
            'Tema Aplikasi',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 18,
              color: AppColors.textPrimary(context),
            ),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildThemeOption(
                context,
                title: 'Terang',
                mode: ThemeMode.light,
                isSelected: currentMode == ThemeMode.light,
              ),
              _buildThemeOption(
                context,
                title: 'Gelap',
                mode: ThemeMode.dark,
                isSelected: currentMode == ThemeMode.dark,
              ),
              _buildThemeOption(
                context,
                title: 'Ikuti Sistem',
                mode: ThemeMode.system,
                isSelected: currentMode == ThemeMode.system,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Tutup'),
            ),
          ],
        );
      },
    );
  }

  Widget _buildThemeOption(
    BuildContext context, {
    required String title,
    required ThemeMode mode,
    required bool isSelected,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(
        isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked,
        color: isSelected ? AppColors.primaryBlue : AppColors.textSecondary(context),
      ),
      title: Text(
        title,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
          color: AppColors.textPrimary(context),
        ),
      ),
      onTap: () {
        ThemeService.instance.setThemeMode(mode);
        Navigator.pop(context);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final surface = AppColors.surface(context);
    final border = AppColors.border(context);
    final textPrimary = AppColors.textPrimary(context);
    final textSecondary = AppColors.textSecondary(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
        child: Column(
          children: [
            // ==================================================
            // AVATAR & USER IDENTITY
            // ==================================================
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primaryBlue.withValues(alpha: 0.12),
                    child: Text(
                      user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
                      style: const TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primaryBlue,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user.name,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(
                      fontSize: 13,
                      color: textSecondary,
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // PENGATURAN AKUN
            // ==================================================
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Akun',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.person_outline, size: 20, color: textSecondary),
                    title: Text(
                      'Edit Profil',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
                    ),
                    trailing: Icon(Icons.chevron_right, size: 20, color: textSecondary),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => EditProfilePage(user: user),
                        ),
                      );

                      if (result is UserModel && context.mounted) {
                        Navigator.pop(context, result);
                      }
                    },
                  ),
                  Divider(height: 1, color: border),
                  ListTile(
                    leading: Icon(Icons.lock_outline, size: 20, color: textSecondary),
                    title: Text(
                      'Ubah Password',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
                    ),
                    trailing: Icon(Icons.chevron_right, size: 20, color: textSecondary),
                    onTap: () async {
                      final result = await Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              ChangePasswordPage(user: user),
                        ),
                      );

                      if (result is UserModel && context.mounted) {
                        Navigator.pop(context, result);
                      }
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // TAMPILAN / TEMA
            // ==================================================
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tampilan',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: Column(
                children: [
                  ListTile(
                    leading: Icon(Icons.brightness_6_outlined, size: 20, color: textSecondary),
                    title: Text(
                      'Tema Aplikasi',
                      style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
                    ),
                    subtitle: Text(
                      ThemeService.instance.themeModeName,
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    trailing: Icon(Icons.chevron_right, size: 20, color: textSecondary),
                    onTap: () => _showThemeDialog(context),
                  ),
                  Divider(height: 1, color: border),
                  ListTile(
                    leading: Icon(
                      PrivacyService.instance.isAmountVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      size: 20,
                      color: textSecondary,
                    ),
                    title: Text(
                      'Privasi Nominal',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: textPrimary,
                      ),
                    ),
                    subtitle: Text(
                      PrivacyService.instance.isAmountVisible
                          ? 'Nominal ditampilkan'
                          : 'Nominal disembunyikan',
                      style: TextStyle(fontSize: 12, color: textSecondary),
                    ),
                    trailing: Switch(
                      value: PrivacyService.instance.isAmountVisible,
                      onChanged: (_) =>
                          PrivacyService.instance.toggleVisibility(),
                    ),
                    onTap: () => PrivacyService.instance.toggleVisibility(),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 20),

            // ==================================================
            // TENTANG APLIKASI
            // ==================================================
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                'Tentang',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 8),

            Container(
              decoration: BoxDecoration(
                color: surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: border),
              ),
              child: ListTile(
                leading: Icon(Icons.info_outline, size: 20, color: textSecondary),
                title: Text(
                  'Tentang ThinkSpend',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500, color: textPrimary),
                ),
                trailing: Icon(Icons.chevron_right, size: 20, color: textSecondary),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
                },
              ),
            ),

            const SizedBox(height: 32),

            // ==================================================
            // LOGOUT
            // ==================================================
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.red,
                  side: BorderSide(color: AppColors.red.withValues(alpha: 0.3)),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: onLogout,
                icon: const Icon(Icons.logout, size: 18),
                label: const Text(
                  'Keluar dari Akun',
                  style: TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
