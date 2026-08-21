import 'package:flutter/material.dart';
import 'package:thinkspend/pages/splash_screen.dart';
import 'package:thinkspend/services/privacy_service.dart';
import 'package:thinkspend/services/theme_service.dart';

/// Entry point utama aplikasi ThinkSpend.
///
/// Menginisialisasi aplikasi Flutter dan mengonfigurasi tema global
/// serta state reaktif (ThemeService & PrivacyService).
void main() {
  runApp(const MyApp());
}

/// Root widget aplikasi ThinkSpend.
///
/// Mendengarkan perubahan tema (Light/Dark) dan status privasi (Sensor Saldo)
/// secara global menggunakan [ListenableBuilder] agar seluruh UI aplikasi
/// langsung ter-update secara reaktif dan konsisten.
class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        ThemeService.instance,
        PrivacyService.instance,
      ]),
      builder: (context, _) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          title: 'ThinkSpend',
          themeMode: ThemeService.instance.themeMode,

          // ====================================================
          // LIGHT THEME
          // ====================================================
          theme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.light,
            colorSchemeSeed: AppColors.primaryBlue,
            scaffoldBackgroundColor: AppColors.lightBg,
            cardColor: AppColors.lightSurface,
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: AppColors.lightBg,
              iconTheme: IconThemeData(color: AppColors.lightTextPrimary),
              titleTextStyle: TextStyle(
                color: AppColors.lightTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: AppColors.lightSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: AppColors.lightBorder,
                  width: 1,
                ),
              ),
              margin: EdgeInsets.zero,
            ),
            navigationBarTheme: NavigationBarThemeData(
              height: 68,
              elevation: 0,
              backgroundColor: AppColors.lightSurface,
              indicatorColor: AppColors.primaryBlue.withValues(alpha: 0.12),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(color: AppColors.primaryBlue);
                }
                return const IconThemeData(color: AppColors.lightTextSecondary);
              }),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  );
                }
                return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.lightTextSecondary,
                );
              }),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.lightSurface,
              hintStyle: const TextStyle(color: AppColors.lightMuted, fontSize: 14),
              prefixIconColor: AppColors.lightTextSecondary,
              suffixIconColor: AppColors.lightTextSecondary,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.lightBorder, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.lightBorder, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.8),
              ),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: AppColors.lightSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),

          // ====================================================
          // DARK THEME
          // ====================================================
          darkTheme: ThemeData(
            useMaterial3: true,
            brightness: Brightness.dark,
            colorSchemeSeed: AppColors.primaryBlue,
            scaffoldBackgroundColor: AppColors.darkBg,
            cardColor: AppColors.darkSurface,
            appBarTheme: const AppBarTheme(
              centerTitle: false,
              elevation: 0,
              scrolledUnderElevation: 0,
              backgroundColor: AppColors.darkBg,
              iconTheme: IconThemeData(color: AppColors.darkTextPrimary),
              titleTextStyle: TextStyle(
                color: AppColors.darkTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            cardTheme: CardThemeData(
              elevation: 0,
              color: AppColors.darkSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: const BorderSide(
                  color: AppColors.darkBorder,
                  width: 1,
                ),
              ),
              margin: EdgeInsets.zero,
            ),
            navigationBarTheme: NavigationBarThemeData(
              height: 68,
              elevation: 0,
              backgroundColor: AppColors.darkSurface,
              indicatorColor: AppColors.primaryBlue.withValues(alpha: 0.20),
              iconTheme: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const IconThemeData(color: AppColors.primaryBlue);
                }
                return const IconThemeData(color: AppColors.darkTextSecondary);
              }),
              labelTextStyle: WidgetStateProperty.resolveWith((states) {
                if (states.contains(WidgetState.selected)) {
                  return const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primaryBlue,
                  );
                }
                return const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.darkTextSecondary,
                );
              }),
            ),
            floatingActionButtonTheme: FloatingActionButtonThemeData(
              backgroundColor: AppColors.primaryBlue,
              foregroundColor: Colors.white,
              elevation: 2,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            inputDecorationTheme: InputDecorationTheme(
              filled: true,
              fillColor: AppColors.darkSurface,
              hintStyle: const TextStyle(color: AppColors.darkMuted, fontSize: 14),
              prefixIconColor: AppColors.darkTextSecondary,
              suffixIconColor: AppColors.darkTextSecondary,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 14,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.darkBorder, width: 1.2),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.darkBorder, width: 1.2),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primaryBlue, width: 1.8),
              ),
            ),
            dialogTheme: DialogThemeData(
              backgroundColor: AppColors.darkSurface,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(18),
              ),
            ),
          ),
          home: const SplashScreen(),
        );
      },
    );
  }
}