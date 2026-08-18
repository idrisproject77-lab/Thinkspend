import 'package:flutter/material.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/user_model.dart';

class ChangePasswordPage extends StatefulWidget {
  final UserModel user;

  const ChangePasswordPage({
    super.key,
    required this.user,
  });

  @override
  State<ChangePasswordPage> createState() =>
      _ChangePasswordPageState();
}

class _ChangePasswordPageState
    extends State<ChangePasswordPage> {
  final oldPasswordController =
      TextEditingController();

  final newPasswordController =
      TextEditingController();

  final confirmPasswordController =
      TextEditingController();

  bool obscureOldPassword = true;
  bool obscureNewPassword = true;
  bool obscureConfirmPassword = true;

  @override
  void dispose() {
    oldPasswordController.dispose();
    newPasswordController.dispose();
    confirmPasswordController.dispose();

    super.dispose();
  }

  // ============================================================
  // UBAH PASSWORD
  // ============================================================

  Future<void> changePassword() async {
    final oldPassword =
        oldPasswordController.text;

    final newPassword =
        newPasswordController.text;

    final confirmPassword =
        confirmPasswordController.text;

    // ----------------------------------------------------------
    // VALIDASI KOSONG
    // ----------------------------------------------------------

    if (oldPassword.isEmpty ||
        newPassword.isEmpty ||
        confirmPassword.isEmpty) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Semua kolom password wajib diisi.',
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // CEK PASSWORD LAMA
    // ----------------------------------------------------------

    if (oldPassword != widget.user.password) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Password lama tidak sesuai.',
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // CEK PASSWORD BARU
    // ----------------------------------------------------------

    if (newPassword.length < 6) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Password baru minimal 6 karakter.',
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // KONFIRMASI PASSWORD
    // ----------------------------------------------------------

    if (newPassword != confirmPassword) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Konfirmasi password tidak sesuai.',
          ),
        ),
      );

      return;
    }

    // ----------------------------------------------------------
    // BUAT USER DENGAN PASSWORD BARU
    // ----------------------------------------------------------

    final updatedUser = UserModel(
      id: widget.user.id,
      name: widget.user.name,
      email: widget.user.email,
      phone: widget.user.phone,
      password: newPassword,
      income: widget.user.income,
      monthlyBudget: widget.user.monthlyBudget,
    );

    // ----------------------------------------------------------
    // UPDATE DATABASE
    // ----------------------------------------------------------

    final result =
        await DatabaseHelper.instance.updateUser(
      updatedUser,
    );

    if (!mounted) return;

    if (result > 0) {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Password berhasil diubah.',
          ),
        ),
      );

      Navigator.pop(
        context,
        updatedUser,
      );
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(
        const SnackBar(
          content: Text(
            'Password gagal diubah.',
          ),
        ),
      );
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Ubah Password',
        ),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment:
              CrossAxisAlignment.start,

          children: [
            const Text(
              'Ubah Password',

              style: TextStyle(
                fontSize: 26,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // PASSWORD LAMA
            // ==================================================

            TextField(
              controller:
                  oldPasswordController,

              obscureText:
                  obscureOldPassword,

              decoration:
                  InputDecoration(
                labelText:
                    'Password Lama',

                prefixIcon:
                    const Icon(
                  Icons.lock_outline,
                ),

                suffixIcon:
                    IconButton(
                  onPressed: () {
                    setState(() {
                      obscureOldPassword =
                          !obscureOldPassword;
                    });
                  },

                  icon: Icon(
                    obscureOldPassword
                        ? Icons.visibility_outlined
                        : Icons
                            .visibility_off_outlined,
                  ),
                ),

                border:
                    const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // PASSWORD BARU
            // ==================================================

            TextField(
              controller:
                  newPasswordController,

              obscureText:
                  obscureNewPassword,

              decoration:
                  InputDecoration(
                labelText:
                    'Password Baru',

                prefixIcon:
                    const Icon(
                  Icons.lock_outline,
                ),

                suffixIcon:
                    IconButton(
                  onPressed: () {
                    setState(() {
                      obscureNewPassword =
                          !obscureNewPassword;
                    });
                  },

                  icon: Icon(
                    obscureNewPassword
                        ? Icons.visibility_outlined
                        : Icons
                            .visibility_off_outlined,
                  ),
                ),

                border:
                    const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // KONFIRMASI PASSWORD
            // ==================================================

            TextField(
              controller:
                  confirmPasswordController,

              obscureText:
                  obscureConfirmPassword,

              decoration:
                  InputDecoration(
                labelText:
                    'Konfirmasi Password',

                prefixIcon:
                    const Icon(
                  Icons.lock_outline,
                ),

                suffixIcon:
                    IconButton(
                  onPressed: () {
                    setState(() {
                      obscureConfirmPassword =
                          !obscureConfirmPassword;
                    });
                  },

                  icon: Icon(
                    obscureConfirmPassword
                        ? Icons.visibility_outlined
                        : Icons
                            .visibility_off_outlined,
                  ),
                ),

                border:
                    const OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 12),

            const Text(
              'Password baru minimal 6 karakter.',

              style: TextStyle(
                color: Colors.grey,
                fontSize: 13,
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // SIMPAN
            // ==================================================

            SizedBox(
              width: double.infinity,

              child:
                  ElevatedButton.icon(
                onPressed:
                    changePassword,

                icon: const Icon(
                  Icons.save_outlined,
                ),

                label: const Padding(
                  padding:
                      EdgeInsets.symmetric(
                    vertical: 14,
                  ),

                  child: Text(
                    'Simpan Password',

                    style: TextStyle(
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}