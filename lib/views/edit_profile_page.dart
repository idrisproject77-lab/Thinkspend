import 'package:flutter/material.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/user_model.dart';

/// Halaman untuk memperbarui data identitas pengguna (nama, email, no telepon).
///
/// Menyimpan perubahan langsung ke SQLite melalui [DatabaseHelper.updateUser].
class EditProfilePage extends StatefulWidget {
  final UserModel user;

  const EditProfilePage({super.key, required this.user});

  @override
  State<EditProfilePage> createState() => _EditProfilePageState();
}

class _EditProfilePageState extends State<EditProfilePage> {
  late TextEditingController nameController;
  late TextEditingController emailController;
  late TextEditingController phoneController;

  @override
  void initState() {
    super.initState();

    nameController = TextEditingController(text: widget.user.name);

    emailController = TextEditingController(text: widget.user.email);

    phoneController = TextEditingController(text: widget.user.phone);
  }

  @override
  void dispose() {
    nameController.dispose();
    emailController.dispose();
    phoneController.dispose();

    super.dispose();
  }

  // ============================================================
  // UPDATE PROFILE
  // ============================================================

  Future<void> updateProfile() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final phone = phoneController.text.trim();

    // ----------------------------------------------------------
    // VALIDASI
    // ----------------------------------------------------------

    if (name.isEmpty || email.isEmpty || phone.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nama, email, dan nomor HP wajib diisi.')),
      );

      return;
    }

    // ----------------------------------------------------------
    // CEK EMAIL
    // ----------------------------------------------------------

    if (email != widget.user.email) {
      final isRegistered = await DatabaseHelper.instance.isEmailRegistered(
        email,
      );

      if (!mounted) return;

      if (isRegistered) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Email tersebut sudah digunakan.')),
        );

        return;
      }
    }

    // ----------------------------------------------------------
    // BUAT USER BARU
    // ----------------------------------------------------------

    final updatedUser = UserModel(
      id: widget.user.id,

      name: name,
      email: email,
      phone: phone,

      // Password TETAP menggunakan password lama.
      password: widget.user.password,

      // Data keuangan tetap dipertahankan.
      income: widget.user.income,
      monthlyBudget: widget.user.monthlyBudget,
    );

    // ----------------------------------------------------------
    // UPDATE DATABASE
    // ----------------------------------------------------------

    final result = await DatabaseHelper.instance.updateUser(updatedUser);

    if (!mounted) return;

    if (result > 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profil berhasil diperbarui.')),
      );

      Navigator.pop(context, updatedUser);
    } else {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profil gagal diperbarui.')));
    }
  }

  // ============================================================
  // BUILD
  // ============================================================

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Edit Profil')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,

          children: [
            const Text(
              'Edit Profil',

              style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // NAMA
            // ==================================================
            TextField(
              controller: nameController,

              textInputAction: TextInputAction.next,

              decoration: const InputDecoration(
                labelText: 'Nama',
                hintText: 'Masukkan nama',
                prefixIcon: Icon(Icons.person_outline),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // EMAIL
            // ==================================================
            TextField(
              controller: emailController,

              keyboardType: TextInputType.emailAddress,

              textInputAction: TextInputAction.next,

              decoration: const InputDecoration(
                labelText: 'Email',
                hintText: 'Masukkan email',
                prefixIcon: Icon(Icons.email_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // NOMOR HP
            // ==================================================
            TextField(
              controller: phoneController,

              keyboardType: TextInputType.phone,

              textInputAction: TextInputAction.done,

              decoration: const InputDecoration(
                labelText: 'Nomor HP',
                hintText: 'Masukkan nomor HP',
                prefixIcon: Icon(Icons.phone_outlined),
                border: OutlineInputBorder(),
              ),
            ),

            const SizedBox(height: 28),

            // ==================================================
            // SIMPAN
            // ==================================================
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: updateProfile,

                icon: const Icon(Icons.save_outlined),

                label: const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),

                  child: Text(
                    'Simpan Perubahan',

                    style: TextStyle(fontSize: 16),
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
