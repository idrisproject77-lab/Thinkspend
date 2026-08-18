import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/user_model.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  // ============================================================
  // CONTROLLERS
  // ============================================================

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  // ============================================================
  // STATE
  // ============================================================

  bool obscurePassword = true;
  bool obscureConfirmPassword = true;
  bool isLoading = false;

  // ============================================================
  // COLOR PALETTE THINKSPEND
  // ============================================================

  static const Color darkNavy = Color(0xFF0F172A);
  static const Color primaryBlue = Color(0xFF2563EB);
  static const Color lightBg = Color(0xFFF8FAFC);
  static const Color secondaryText = Color(0xFF64748B);
  static const Color mutedText = Color(0xFF94A3B8);
  static const Color borderColor = Color(0xFFE2E8F0);

  // ============================================================
  // DISPOSE
  // ============================================================

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  // ============================================================
  // REGISTER
  // ============================================================

  Future<void> register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword =
        confirmPasswordController.text.trim();

    // ==========================================================
    // VALIDASI DATA
    // ==========================================================

    if (name.isEmpty ||
        email.isEmpty ||
        phone.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      _showSnackBar(
        'Semua data wajib diisi.',
        isError: true,
      );

      return;
    }

    // ==========================================================
    // VALIDASI PASSWORD
    // ==========================================================

    if (password != confirmPassword) {
      _showSnackBar(
        'Password dan konfirmasi password tidak sama.',
        isError: true,
      );

      return;
    }

    setState(() {
      isLoading = true;
    });

    try {
      // ========================================================
      // CEK EMAIL
      // ========================================================

      final emailExists =
          await DatabaseHelper.instance.isEmailRegistered(
        email,
      );

      if (!mounted) return;

      if (emailExists) {
        _showSnackBar(
          'Email sudah terdaftar.',
          isError: true,
        );

        return;
      }

      // ========================================================
      // BUAT USER
      // ========================================================

      final user = UserModel(
        name: name,
        email: email,
        phone: phone,
        password: password,
      );

      // ========================================================
      // SIMPAN DATABASE
      // ========================================================

      final id =
          await DatabaseHelper.instance.insertUser(user);

      debugPrint('REGISTER BERHASIL');
      debugPrint('USER ID: $id');

      if (!mounted) return;

      _showSnackBar(
        'Akun berhasil dibuat. Silakan masuk.',
        isError: false,
      );

      // ========================================================
      // KEMBALI KE LOGIN
      // ========================================================

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      debugPrint('ERROR REGISTER: $e');

      _showSnackBar(
        'Terjadi kesalahan saat membuat akun.',
        isError: true,
      );
    } finally {
      if (mounted) {
        setState(() {
          isLoading = false;
        });
      }
    }
  }

  // ============================================================
  // SNACKBAR
  // ============================================================

  void _showSnackBar(
    String message, {
    required bool isError,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(
              isError
                  ? Icons.error_outline
                  : Icons.check_circle_outline,
              color: Colors.white,
              size: 20,
            ),

            const SizedBox(width: 10),

            Expanded(
              child: Text(
                message,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: isError
            ? const Color(0xFFDC2626)
            : const Color(0xFF16A34A),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
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
        padding: const EdgeInsets.only(
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
      // SUFFIX ICON
      // --------------------------------------------------------

      suffixIcon: suffixIcon,

      // --------------------------------------------------------
      // BACKGROUND
      // --------------------------------------------------------

      filled: true,
      fillColor: Colors.white,

      // --------------------------------------------------------
      // HINT
      // --------------------------------------------------------

      hintStyle: GoogleFonts.plusJakartaSans(
        color: mutedText,
        fontSize: 14,
        fontWeight: FontWeight.w400,
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

      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: borderColor,
          width: 1.2,
        ),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: borderColor,
          width: 1.2,
        ),
      ),

      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
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
      backgroundColor: lightBg,
      resizeToAvoidBottomInset: true,

      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,

          physics:
              const BouncingScrollPhysics(),

          padding: EdgeInsets.only(
            left: 24,
            right: 24,
            top: 18,
            bottom:
                MediaQuery.of(context)
                        .viewInsets
                        .bottom +
                    24,
          ),

          child: Column(
            crossAxisAlignment:
                CrossAxisAlignment.stretch,

            children: [

              // ==================================================
              // BACK BUTTON
              // ==================================================

              Align(
                alignment:
                    Alignment.centerLeft,

                child: IconButton(
                  onPressed: () {
                    Navigator.pop(context);
                  },

                  icon: const Icon(
                    Icons.arrow_back_rounded,
                  ),

                  color: darkNavy,

                  tooltip: 'Kembali',
                ),
              ),

              const SizedBox(height: 2),

              // ==================================================
              // LOGO
              // ==================================================

              Center(
                child: Container(
                  width: 70,
                  height: 70,

                  padding:
                      const EdgeInsets.all(12),

                  decoration:
                      BoxDecoration(
                    color: Colors.white,

                    borderRadius:
                        BorderRadius.circular(21),

                    border:
                        Border.all(
                      color: borderColor,
                      width: 1,
                    ),

                    boxShadow: [
                      BoxShadow(
                        color:
                            darkNavy.withValues(
                          alpha: 0.045,
                        ),
                        blurRadius: 18,
                        offset:
                            const Offset(0, 7),
                      ),
                    ],
                  ),

                  child: Image.asset(
                    'assets/images/Logo TS.jpg',

                    fit: BoxFit.contain,

                    errorBuilder: (
                      context,
                      error,
                      stackTrace,
                    ) {
                      return const Icon(
                        Icons
                            .account_balance_wallet_rounded,
                        color: primaryBlue,
                        size: 36,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

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
                          fontSize: 28,
                          fontWeight:
                              FontWeight.w800,
                          color: darkNavy,
                          letterSpacing: -1,
                        ),
                      ),

                      TextSpan(
                        text: 'Spend',

                        style:
                            GoogleFonts
                                .plusJakartaSans(
                          fontSize: 28,
                          fontWeight:
                              FontWeight.w700,
                          color: primaryBlue,
                          letterSpacing: -1,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              const SizedBox(height: 26),

              // ==================================================
              // FORM CARD
              // ==================================================

              Container(
                padding:
                    const EdgeInsets.fromLTRB(
                  22,
                  24,
                  22,
                  22,
                ),

                decoration:
                    BoxDecoration(
                  color: Colors.white,

                  borderRadius:
                      BorderRadius.circular(24),

                  border:
                      Border.all(
                    color: borderColor,
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
                          const Offset(0, 8),
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
                        'Mulai Perjalananmu ',

                        textAlign:
                            TextAlign.center,

                        style:
                            GoogleFonts
                                .plusJakartaSans(
                          fontSize: 22,
                          fontWeight:
                              FontWeight.w800,
                          color: darkNavy,
                          letterSpacing: -0.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 7),

                    Center(
                      child: Text(
                        'Buat akun dan mulai kelola\n'
                        'keuanganmu dengan lebih terarah.',

                        textAlign:
                            TextAlign.center,

                        style:
                            GoogleFonts
                                .plusJakartaSans(
                          fontSize: 13,
                          color: secondaryText,
                          fontWeight:
                              FontWeight.w500,
                          height: 1.5,
                        ),
                      ),
                    ),

                    const SizedBox(height: 25),

                    // ==========================================
                    // NAMA
                    // ==========================================

                    Text(
                      'Nama Lengkap',

                      style:
                          GoogleFonts
                              .plusJakartaSans(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w700,
                        color: darkNavy,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller:
                          nameController,

                      textInputAction:
                          TextInputAction.next,

                      style:
                          GoogleFonts
                              .plusJakartaSans(
                        fontSize: 14,
                        color: darkNavy,
                        fontWeight:
                            FontWeight.w600,
                      ),

                      decoration:
                          _buildInputDecoration(
                        hint:
                            'Masukkan nama lengkap',
                        icon:
                            Icons
                                .person_outline_rounded,
                      ),
                    ),

                    const SizedBox(height: 17),

                    // ==========================================
                    // EMAIL
                    // ==========================================

                    Text(
                      'Alamat Email',

                      style:
                          GoogleFonts
                              .plusJakartaSans(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w700,
                        color: darkNavy,
                      ),
                    ),

                    const SizedBox(height: 8),

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
                        color: darkNavy,
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

                    const SizedBox(height: 17),

                    // ==========================================
                    // NOMOR HP
                    // ==========================================

                    Text(
                      'Nomor HP',

                      style:
                          GoogleFonts
                              .plusJakartaSans(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w700,
                        color: darkNavy,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller:
                          phoneController,

                      keyboardType:
                          TextInputType.phone,

                      textInputAction:
                          TextInputAction.next,

                      style:
                          GoogleFonts
                              .plusJakartaSans(
                        fontSize: 14,
                        color: darkNavy,
                        fontWeight:
                            FontWeight.w600,
                      ),

                      decoration:
                          _buildInputDecoration(
                        hint:
                            'Masukkan nomor HP',
                        icon:
                            Icons
                                .phone_outlined,
                      ),
                    ),

                    const SizedBox(height: 17),

                    // ==========================================
                    // PASSWORD
                    // ==========================================

                    Text(
                      'Kata Sandi',

                      style:
                          GoogleFonts
                              .plusJakartaSans(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w700,
                        color: darkNavy,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller:
                          passwordController,

                      obscureText:
                          obscurePassword,

                      textInputAction:
                          TextInputAction.next,

                      style:
                          GoogleFonts
                              .plusJakartaSans(
                        fontSize: 14,
                        color: darkNavy,
                        fontWeight:
                            FontWeight.w600,
                      ),

                      decoration:
                          _buildInputDecoration(
                        hint:
                            'Buat kata sandi',
                        icon:
                            Icons
                                .lock_outline_rounded,

                        suffixIcon:
                            IconButton(
                          tooltip:
                              obscurePassword
                                  ? 'Tampilkan kata sandi'
                                  : 'Sembunyikan kata sandi',

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

                    const SizedBox(height: 17),

                    // ==========================================
                    // KONFIRMASI PASSWORD
                    // ==========================================

                    Text(
                      'Konfirmasi Kata Sandi',

                      style:
                          GoogleFonts
                              .plusJakartaSans(
                        fontSize: 13,
                        fontWeight:
                            FontWeight.w700,
                        color: darkNavy,
                      ),
                    ),

                    const SizedBox(height: 8),

                    TextField(
                      controller:
                          confirmPasswordController,

                      obscureText:
                          obscureConfirmPassword,

                      textInputAction:
                          TextInputAction.done,

                      style:
                          GoogleFonts
                              .plusJakartaSans(
                        fontSize: 14,
                        color: darkNavy,
                        fontWeight:
                            FontWeight.w600,
                      ),

                      onSubmitted: (_) {
                        if (!isLoading) {
                          register();
                        }
                      },

                      decoration:
                          _buildInputDecoration(
                        hint:
                            'Ulangi kata sandi',
                        icon:
                            Icons
                                .lock_reset_outlined,

                        suffixIcon:
                            IconButton(
                          tooltip:
                              obscureConfirmPassword
                                  ? 'Tampilkan kata sandi'
                                  : 'Sembunyikan kata sandi',

                          onPressed: () {
                            setState(() {
                              obscureConfirmPassword =
                                  !obscureConfirmPassword;
                            });
                          },

                          icon: Icon(
                            obscureConfirmPassword
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
                    // REGISTER BUTTON
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
                                : register,

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
                                        'Buat Akun',

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

              const SizedBox(height: 22),

              // ==================================================
              // LOGIN LINK
              // ==================================================

              Center(
                child: Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text:
                            'Sudah punya akun? ',

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
                            Navigator.pop(
                              context,
                            );
                          },

                          child: Text(
                            'Masuk sekarang',

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

              const SizedBox(height: 16),

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