import 'package:flutter/material.dart';
import 'package:thinkspend/models/user_model.dart';
import 'package:thinkspend/views/edit_profile_page.dart';
import 'package:thinkspend/views/change_password_page.dart';
import 'package:thinkspend/views/about_page.dart';

class ProfilePage extends StatelessWidget {
  final UserModel user;
  final VoidCallback onLogout;

  const ProfilePage({super.key, required this.user, required this.onLogout});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Profil')),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24),

        child: Column(
          children: [
            // ==================================================
            // AVATAR
            // ==================================================
            CircleAvatar(
              radius: 50,
              child: Text(
                user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',

                style: const TextStyle(
                  fontSize: 36,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // NAMA
            // ==================================================
            Text(
              user.name,

              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
            ),

            const SizedBox(height: 4),

            // ==================================================
            // EMAIL
            // ==================================================
            Text(user.email, style: const TextStyle(color: Colors.grey)),

            const SizedBox(height: 32),

            // ==================================================
            // INFORMASI PROFIL
            // ==================================================
            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.person_outline),

                    title: const Text('Nama'),

                    subtitle: Text(user.name),
                  ),

                  const Divider(height: 1),

                  ListTile(
                    leading: const Icon(Icons.email_outlined),

                    title: const Text('Email'),

                    subtitle: Text(user.email),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 16),

            // ==================================================
            // EDIT PROFIL
            // ==================================================
            SizedBox(
              width: double.infinity,

              child: ElevatedButton.icon(
                onPressed: () async {
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

                icon: const Icon(Icons.edit_outlined),

                label: const Text('Edit Profil'),
              ),
            ),

            const SizedBox(height: 12),

            // ==================================================
            // UBAH PASSWORD
            // ==================================================
            SizedBox(
              width: double.infinity,

              child: OutlinedButton.icon(
                onPressed: () async {
                  final result = await Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ChangePasswordPage(user: user),
                    ),
                  );

                  if (result is UserModel && context.mounted) {
                    Navigator.pop(context, result);
                  }
                },

                icon: const Icon(Icons.lock_outline),

                label: const Text('Ubah Password'),
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // TENTANG
            // ==================================================
            Card(
              child: ListTile(
                leading: const Icon(Icons.info_outline),

                title: const Text('Tentang ThinkSpend'),

                trailing: const Icon(Icons.chevron_right),

                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => const AboutPage()),
                  );
                },
              ),
            ),

            const SizedBox(height: 24),

            // ==================================================
            // LOGOUT
            // ==================================================
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout),
                label: const Text('Logout'),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
