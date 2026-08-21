import 'dart:async';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';

// Pastikan file ini ada di folder yang sama, atau sesuaikan path-nya
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/user_model.dart';
import 'package:thinkspend/pages/main_page.dart';
import 'package:thinkspend/services/session_service.dart';
import 'login_page.dart';

/// Splash screen pembuka aplikasi ThinkSpend dengan video/animasi logo.
///
/// Bertanggung jawab memeriksa persistent session login ([SessionService])
/// dan langsung memulihkan navigasi ke halaman terakhir ([MainPage]) jika sudah login,
/// atau mengarahkan ke [LoginPage] jika belum memiliki sesi aktif.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;

  VideoPlayerController? _videoController;
  bool _isVideoInitialized = false;
  bool _hasVideoError = false;

  UserModel? _restoredUser;
  int _restoredLastPage = 0;
  late final Future<void> _sessionCheckFuture;

  @override
  void initState() {
    super.initState();

    // 1. Inisialisasi controller animasi teks & UI
    _animationController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeIn),
    );

    _scaleAnimation = Tween<double>(begin: 0.8, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeOutBack),
    );

    _animationController.forward();

    // 2. Inisialisasi Pemutar Video
    _initVideoPlayer();

    // 3. Pengecekan persistent session & last page restore secara asinkron
    _sessionCheckFuture = _checkSession();

    // 4. Timer untuk pindah otomatis (setelah 3.5 detik)
    Timer(const Duration(milliseconds: 3500), () async {
      await _sessionCheckFuture;
      if (!mounted) return;

      if (_restoredUser != null) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainPage(
              user: _restoredUser!,
              initialIndex: _restoredLastPage,
            ),
          ),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const LoginPage()),
        );
      }
    });
  }

  /// BAGAIMANA SESSION DIPULIHKAN:
  /// Mengecek apakah ada session login aktif di SharedPreferences, lalu
  /// memvalidasi ketersediaan user di database SQLite secara asinkron.
  /// Jika valid, user dan last page index dipulihkan untuk langsung membuka MainPage.
  Future<void> _checkSession() async {
    try {
      final userId = await SessionService.instance.getSessionUserId();
      if (userId != null) {
        final user = await DatabaseHelper.instance.getUserById(userId);
        if (user != null) {
          final lastPage = await SessionService.instance.getLastPage();
          _restoredUser = user;
          _restoredLastPage = lastPage;
          return;
        }
      }
      // Jika session tidak valid atau user telah dihapus, bersihkan session
      await SessionService.instance.clearSession();
    } catch (e) {
      debugPrint('Error validating startup session: $e');
    }
  }

  Future<void> _initVideoPlayer() async {
    try {
      // Menggunakan nama file yang sudah di-rename (tanpa spasi)
      _videoController = VideoPlayerController.asset(
        'assets/videos/animasi_splashscreen.mp4',
      );

      await _videoController!.initialize();

      if (mounted) {
        setState(() {
          _isVideoInitialized = true;
        });
        _videoController!.play();
        _videoController!.setLooping(false);
      }
    } catch (e) {
      debugPrint("Gagal memuat video splash screen: $e");
      if (mounted) {
        setState(() {
          _hasVideoError = true;
        });
      }
    }
  }

  @override
  void dispose() {
    _animationController.dispose();
    _videoController?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Stack(
          children: [
            // Konten Utama (Video / Fallback + Nama App) di Tengah
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Area Video / Logo
                      SizedBox(
                        width: 180,
                        height: 180,
                        child: _isVideoInitialized && _videoController != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: AspectRatio(
                                  aspectRatio:
                                      _videoController!.value.aspectRatio,
                                  child: VideoPlayer(_videoController!),
                                ),
                              )
                            : _hasVideoError
                            ? Image.asset(
                                "assets/images/Logo TS.jpg",
                                fit: BoxFit.contain,
                                errorBuilder: (context, error, stackTrace) {
                                  return const Icon(
                                    Icons.monetization_on_rounded,
                                    size: 100,
                                    color: Colors.green,
                                  );
                                },
                              )
                            : const Center(
                                child: CircularProgressIndicator(
                                  color: Colors.green,
                                ),
                              ),
                      ),
                      const SizedBox(height: 15),

                      // Teks Logo Think$pend
                      Text.rich(
                        TextSpan(
                          children: [
                            TextSpan(
                              text: 'Think',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 28,
                                fontWeight: FontWeight.w800, // Bold tegas
                                color: const Color(
                                  0xFF0F172A,
                                ), // Slate ultra dark / hampir hitam
                                letterSpacing: -0.5,
                              ),
                            ),
                            TextSpan(
                              text: 'Spend',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 28,
                                fontWeight: FontWeight.w800, // Bold tegas
                                color: const Color(
                                  0xFF2563EB,
                                ), // Accent Blue elegan (bisa diganti 0xFF059669 untuk hijau)
                                letterSpacing: -0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),

                      // Tagline
                      Text(
                        'Kelola Keuangan Lebih Cerdas',
                        style: GoogleFonts.montserrat(
                          fontSize: 13,
                          color: Colors.grey[600],
                          fontWeight: FontWeight.w500,
                          letterSpacing: 0.3,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Indikator Loading & Footer di Bagian Bawah
            Positioned(
              bottom: 30,
              left: 0,
              right: 0,
              child: Column(
                children: [
                  const SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      color: Colors.blueAccent,
                      strokeWidth: 2.5,
                    ),
                  ),
                  const SizedBox(height: 15),
                  Text(
                    'v1.0.0',
                    style: TextStyle(color: Colors.grey[400], fontSize: 12),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}