import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/pages/main_page.dart';
import 'package:thinkspend/pages/register_page.dart';
import 'package:thinkspend/services/session_service.dart';

/// Halaman autentikasi masuk (Login) ThinkSpend.
///
/// Memverifikasi email dan password ke database SQLite via [DatabaseHelper.loginUser],
/// serta menyimpan status login persisten melalui [SessionService.saveSession].
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final TextEditingController emailController =
      TextEditingController();

  final TextEditingController passwordController =
      TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  bool isLoading = false;
  bool obscurePassword = true;

  // ============================================================
  // COLOR PALETTE THINKSPEND
  // ============================================================

  static const Color darkNavy =
      Color(0xFF0F172A);

  static const Color primaryBlue =
      Color(0xFF2563EB);

  static const Color lightBg =
      Color(0xFFF8FAFC);

  static const Color secondaryText =
      Color(0xFF64748B);

  static const Color mutedText =
      Color(0xFF94A3B8);

  static const Color borderColor =
      Color(0xFFE2E8F0);

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();

    super.dispose();
  }

  // ============================================================
  // LOGIN
  // ============================================================

  Future<void> login() async {
    final email =
        emailController.text.trim();

    final password =
        passwordController.text.trim();

    // ==========================================================
    // VALIDASI
    // ==========================================================

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(
                Icons.info_outline,
                color: Colors.white,
                size: 20,
              ),

              const SizedBox(width: 10),

              Text(
                'Email dan password wajib diisi.',
                style:
                    GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                ),
              ),
            ],
          ),

          backgroundColor:
              darkNavy,

          behavior:
              SnackBarBehavior.floating,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      );

      return;
    }

    // ==========================================================
    // LOADING
    // ==========================================================

    setState(() {
      isLoading = true;
    });

    try {
      // ========================================================
      // LOGIN DATABASE
      // ========================================================

      final user =
          await DatabaseHelper.instance.loginUser(
        email,
        password,
      );

      if (!mounted) return;

      // ========================================================
      // LOGIN BERHASIL
      // ========================================================

      if (user != null) {
        debugPrint(
          'LOGIN BERHASIL: ${user.name} (${user.email})',
        );

        // KENAPA SESSION DISIMPAN:
        // Menyimpan status login dan user ID ke SharedPreferences agar ketika aplikasi
        // dibuka kembali, user langsung masuk tanpa perlu memasukkan kredensial lagi.
        await SessionService.instance.saveSession(
          userId: user.id!,
          lastPage: 0,
        );

        if (!mounted) return;

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => MainPage(
              user: user,
              initialIndex: 0,
            ),
          ),
        );
      }

      // ========================================================
      // LOGIN GAGAL
      // ========================================================

      else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(
                  Icons.error_outline,
                  color: Colors.white,
                  size: 20,
                ),

                const SizedBox(width: 10),

                Text(
                  'Email atau password salah.',
                  style:
                      GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                  ),
                ),
              ],
            ),

            backgroundColor:
                const Color(0xFFDC2626),

            behavior:
                SnackBarBehavior.floating,

            shape:
                RoundedRectangleBorder(
              borderRadius:
                  BorderRadius.circular(12),
            ),
          ),
        );
      }
    }

    // ==========================================================
    // ERROR
    // ==========================================================

    catch (e) {
      if (!mounted) return;

      debugPrint(
        'ERROR LOGIN: $e',
      );

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Terjadi kesalahan saat login: $e',

            style:
                GoogleFonts.plusJakartaSans(
              fontSize: 13,
            ),
          ),

          backgroundColor:
              const Color(0xFFDC2626),

          behavior:
              SnackBarBehavior.floating,

          shape:
              RoundedRectangleBorder(
            borderRadius:
                BorderRadius.circular(12),
          ),
        ),
      );
    }

    // ==========================================================
    // STOP LOADING
    // ==========================================================

    finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // INPUT DECORATION
  // ============================================================

  InputDecoration _buildInputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,

      // --------------------------------------------------------
      // PREFIX ICON
      // --------------------------------------------------------

      prefixIcon: Padding(
        padding:
            const EdgeInsets.only(
          left: 16,
          right: 12,
        ),

        child: Icon(
          icon,
          color: secondaryText,
          size: 21,
        ),
      ),

      prefixIconConstraints:
          const BoxConstraints(
        minWidth: 48,
      ),

      // --------------------------------------------------------
      // SUFFIX
      // --------------------------------------------------------

      suffixIcon:
          suffixIcon,

      // --------------------------------------------------------
      // BACKGROUND
      // --------------------------------------------------------

      filled: true,

      fillColor:
          Colors.white,

      // --------------------------------------------------------
      // HINT
      // --------------------------------------------------------

      hintStyle:
          GoogleFonts.plusJakartaSans(
        color: mutedText,
        fontSize: 14,
        fontWeight:
            FontWeight.w400,
      ),

      // --------------------------------------------------------
      // PADDING
      // --------------------------------------------------------

      contentPadding:
          const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 16,
      ),

      // --------------------------------------------------------
      // BORDER
      // --------------------------------------------------------

      border:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),

        borderSide:
            const BorderSide(
          color: borderColor,
          width: 1.2,
        ),
      ),

      enabledBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),

        borderSide:
            const BorderSide(
          color: borderColor,
          width: 1.2,
        ),
      ),

      focusedBorder:
          OutlineInputBorder(
        borderRadius:
            BorderRadius.circular(15),

        borderSide:
            const BorderSide(
          color: primaryBlue,
          width: 1.8,
        ),
      ),
    );
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor:
          lightBg,

      body: SafeArea(
        child: SingleChildScrollView(
          physics:
              const BouncingScrollPhysics(),

          padding:
              const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 20,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,

            children: [

              // ==================================================
              // TOP SPACING
              // ==================================================

              const SizedBox(height: 18),

              // ==================================================
              // LOGO
              // ==================================================

              Center(
                child: Container(
                  width: 68,
                  height: 68,

                  padding:
                      const EdgeInsets.all(11),

                  decoration:
                      BoxDecoration(
                    color:
                        Colors.white,

                    borderRadius:
                        BorderRadius.circular(22),

                    boxShadow: [
                      BoxShadow(
                        color:
                            darkNavy.withValues(
                          alpha: 0.05,
                        ),

                        blurRadius: 4,

                        offset:
                            const Offset(
                          0,
                          7,
                        ),
                      ),
                    ],
                  ),

                  child: Image.asset(
                    'assets/images/Logo TS.jpg',

                    fit:
                        BoxFit.contain,

                    errorBuilder:
                        (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return const Icon(
                        Icons
                            .account_balance_wallet_rounded,

                        color:
                            primaryBlue,

                        size: 500,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // ==================================================
              // BRAND
              // ==================================================

              Center(
                child: Text.rich(
                  TextSpan(
                    children: [

                      TextSpan(
                        text: 'Think',

                        style:
                            GoogleFonts
                                .plusJakartaSans(
                          fontSize: 27,

                          fontWeight:
                              FontWeight.w800,

                          color:
                              darkNavy,

                          letterSpacing:
                              -1,
                        ),
                      ),

                      TextSpan(
                        text: 'Spend',

                        style:
                            GoogleFonts
                                .plusJakartaSans(
                          fontSize: 29,

                          fontWeight:
                              FontWeight.w700,

                          color:
                              primaryBlue,

                          letterSpacing:
                              -1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // FORM CARD
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.fromLTRB(
                  20,
                  22,
                  20,
                  20,
                ),

                decoration:
                    BoxDecoration(
                  color:
                      Colors.white,

                  borderRadius:
                      BorderRadius.circular(24),

                  border:
                      Border.all(
                    color:
                        borderColor,

                    width: 1,
                  ),

                  boxShadow: [
                    BoxShadow(
                      color:
                          darkNavy.withValues(
                        alpha: 0.045,
                      ),

                      blurRadius: 20,

                      offset:
                          const Offset(
                        0,
                        8,
                      ),
                    ),
                  ],
                ),

                child: Column(
                  crossAxisAlignment:
                      CrossAxisAlignment.start,

                  children: [

                    // ==========================================
                    // TITLE
                    // ==========================================

                    Center(
                      child: Text(
                        'Mulai Kelola Keuanganmu',

                        textAlign:
                            TextAlign.center,

                        style:
                            GoogleFonts
                                .plusJakartaSans(
                          fontSize: 22,

                          fontWeight:
                              FontWeight.w800,

                          color:
                              darkNavy,

                          letterSpacing:
                              -0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 7),

                    Center(
                      child: Text(
                        'Catat, pantau, dan  rencanakan keuanganmu  dalam satu tempat.',

                        textAlign:
                            TextAlign.center,

                        style:
                            GoogleFonts
                                .plusJakartaSans(
                          fontSize: 13,

                          color:
                              secondaryText,

                          fontWeight:
                              FontWeight.w500,

                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ==========================================
                    // EMAIL LABEL
                    // ==========================================

                    Text(
                      'Alamat Email',

                      style:
                          GoogleFonts
                              .plusJakartaSans(
                        fontSize: 13,

                        fontWeight:
                            FontWeight.w700,

                        color:
                            darkNavy,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ==========================================
                    // EMAIL
                    // ==========================================

                    TextField(
                      controller:
                          emailController,

                      keyboardType:
                          TextInputType
                              .emailAddress,

                      textInputAction:
                          TextInputAction.next,

                      style:
                          GoogleFonts
                              .plusJakartaSans(
                        fontSize: 14,

                        color:
                            darkNavy,

                        fontWeight:
                            FontWeight.w600,
                      ),

                      decoration:
                          _buildInputDecoration(
                        hint:
                            'Masukkan email kamu',

                        icon:
                            Icons
                                .email_outlined,
                      ),
                    ),

                    const SizedBox(height: 18),

                    // ==========================================
                    // PASSWORD LABEL
                    // ==========================================

                    Text(
                      'Kata Sandi',

                      style:
                          GoogleFonts
                              .plusJakartaSans(
                        fontSize: 13,

                        fontWeight:
                            FontWeight.w700,

                        color:
                            darkNavy,
                      ),
                    ),

                    const SizedBox(height: 8),

                    // ==========================================
                    // PASSWORD
                    // ==========================================

                    TextField(
                      controller:
                          passwordController,

                      obscureText:
                          obscurePassword,

                      textInputAction:
                          TextInputAction.done,

                      style:
                          GoogleFonts
                              .plusJakartaSans(
                        fontSize: 14,

                        color:
                            darkNavy,

                        fontWeight:
                            FontWeight.w600,
                      ),

                      onSubmitted:
                          (_) {
                        if (!isLoading) {
                          login();
                        }
                      },

                      decoration:
                          _buildInputDecoration(
                        hint:
                            'Masukkan kata sandi',

                        icon:
                            Icons
                                .lock_outline_rounded,

                        suffixIcon:
                            IconButton(
                          onPressed: () {
                            setState(() {
                              obscurePassword =
                                  !obscurePassword;
                            });
                          },

                          icon: Icon(
                            obscurePassword
                                ? Icons
                                    .visibility_outlined
                                : Icons
                                    .visibility_off_outlined,

                            color:
                                secondaryText,

                            size: 21,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ==========================================
                    // LOGIN BUTTON
                    // ==========================================

                    SizedBox(
                      width:
                          double.infinity,

                      height: 54,

                      child:
                          ElevatedButton(
                        onPressed:
                            isLoading
                                ? null
                                : login,

                        style:
                            ElevatedButton.styleFrom(
                          backgroundColor:
                              primaryBlue,

                          disabledBackgroundColor:
                              primaryBlue
                                  .withValues(
                            alpha: 0.55,
                          ),

                          foregroundColor:
                              Colors.white,

                          elevation: 0,

                          shape:
                              RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(
                              15,
                            ),
                          ),
                        ),

                        child:
                            isLoading
                                ? const SizedBox(
                                    width: 22,
                                    height: 22,

                                    child:
                                        CircularProgressIndicator(
                                      color:
                                          Colors.white,

                                      strokeWidth:
                                          2.4,
                                    ),
                                  )
                                : Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment
                                            .center,

                                    children: [
                                      Text(
                                        'Masuk',

                                        style:
                                            GoogleFonts
                                                .plusJakartaSans(
                                          fontSize:
                                              15,

                                          fontWeight:
                                              FontWeight.w800,
                                        ),
                                      ),

                                      const SizedBox(
                                        width: 8,
                                      ),

                                      const Icon(
                                        Icons
                                            .arrow_forward_rounded,

                                        size: 20,
                                      ),
                                    ],
                                  ),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ==================================================
              // REGISTER
              // ==================================================

              Center(
                child: Text.rich(
                  TextSpan(
                    children: [

                      TextSpan(
                        text:
                            'Belum punya akun? ',

                        style:
                            GoogleFonts
                                .plusJakartaSans(
                          fontSize: 13,

                          color:
                              secondaryText,

                          fontWeight:
                              FontWeight.w500,
                        ),
                      ),

                      WidgetSpan(
                        alignment:
                            PlaceholderAlignment
                                .middle,

                        child:
                            GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,

                              MaterialPageRoute(
                                builder:
                                    (context) =>
                                        const RegisterPage(),
                              ),
                            );
                          },

                          child: Text(
                            'Daftar sekarang',

                            style:
                                GoogleFonts
                                    .plusJakartaSans(
                              fontSize: 13,

                              color:
                                  primaryBlue,

                              fontWeight:
                                  FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 18),

              // ==================================================
              // FOOTER
              // ==================================================

              Center(
                child: Text(
                  'ThinkSpend • Kelola Keuangan Lebih Cerdas',

                  textAlign:
                      TextAlign.center,

                  style:
                      GoogleFonts
                          .plusJakartaSans(
                    fontSize: 10.5,

                    color:
                        mutedText,

                    fontWeight:
                        FontWeight.w500,
                  ),
                ),
              ),

              const SizedBox(height: 8),
            ],
          ),
        ),
      ),
    );
  }
}