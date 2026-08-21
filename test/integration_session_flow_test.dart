import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:thinkspend/databases/database_helper.dart';
import 'package:thinkspend/models/user_model.dart';
import 'package:thinkspend/pages/login_page.dart';
import 'package:thinkspend/pages/main_page.dart';
import 'package:thinkspend/services/session_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final testUser = UserModel(
    id: 1,
    name: 'Akun A',
    email: 'akuna@example.com',
    phone: '08123456789',
    password: 'password123',
    income: 5000000,
    monthlyBudget: 3000000,
  );

  setUpAll(() async {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final db = await DatabaseHelper.instance.database;
    await db.delete('users');
    await DatabaseHelper.instance.insertUser(testUser);
  });

  /// Helper untuk mensimulasikan proses startup aplikasi seperti pada SplashScreen
  Future<Widget> simulateAppLaunch() async {
    final userId = await SessionService.instance.getSessionUserId();
    if (userId != null) {
      final user = await DatabaseHelper.instance.getUserById(userId);
      if (user != null) {
        final lastPage = await SessionService.instance.getLastPage();
        return MainPage(user: user, initialIndex: lastPage);
      }
    }
    await SessionService.instance.clearSession();
    return const LoginPage();
  }

  group('Runtime Test Scenarios (TEST 1 to TEST 6)', () {
    test('TEST 1: Login -> masuk Beranda -> tutup aplikasi -> buka kembali -> langsung masuk Beranda tanpa Login', () async {
      // 1. Simulasikan Login berhasil
      await SessionService.instance.saveSession(userId: testUser.id!, lastPage: 0);

      // 2. Simulasikan buka kembali aplikasi (Cold Boot)
      final screen = await simulateAppLaunch();

      // Verifikasi: langsung membuka MainPage pada index 0 (Beranda)
      expect(screen, isA<MainPage>());
      final mainPage = screen as MainPage;
      expect(mainPage.user.name, equals('Akun A'));
      expect(mainPage.initialIndex, equals(0));
    });

    test('TEST 2: Login -> buka Target -> tutup aplikasi -> buka kembali -> langsung masuk Target', () async {
      // 1. User login dan pindah ke tab Target (index 2)
      await SessionService.instance.saveSession(userId: testUser.id!, lastPage: 0);
      await SessionService.instance.saveLastPage(2);

      // 2. Simulasikan tutup & buka kembali aplikasi
      final screen = await simulateAppLaunch();

      // Verifikasi: langsung masuk ke Target (index 2)
      expect(screen, isA<MainPage>());
      final mainPage = screen as MainPage;
      expect(mainPage.initialIndex, equals(2));
    });

    test('TEST 3: Login -> buka Transaksi -> tutup aplikasi -> buka kembali -> langsung masuk Transaksi', () async {
      // 1. User login dan pindah ke tab Transaksi (index 1)
      await SessionService.instance.saveSession(userId: testUser.id!, lastPage: 0);
      await SessionService.instance.saveLastPage(1);

      // 2. Simulasikan tutup & buka kembali aplikasi
      final screen = await simulateAppLaunch();

      // Verifikasi: langsung masuk ke Transaksi (index 1)
      expect(screen, isA<MainPage>());
      final mainPage = screen as MainPage;
      expect(mainPage.initialIndex, equals(1));
    });

    test('TEST 4: Login -> buka AI -> tutup aplikasi -> buka kembali -> langsung masuk AI', () async {
      // 1. User login dan pindah ke tab AI (index 3)
      await SessionService.instance.saveSession(userId: testUser.id!, lastPage: 0);
      await SessionService.instance.saveLastPage(3);

      // 2. Simulasikan tutup & buka kembali aplikasi
      final screen = await simulateAppLaunch();

      // Verifikasi: langsung masuk ke AI (index 3)
      expect(screen, isA<MainPage>());
      final mainPage = screen as MainPage;
      expect(mainPage.initialIndex, equals(3));
    });

    test('TEST 5: Login -> tekan Logout -> tutup aplikasi -> buka kembali -> tetap di LoginPage dan TIDAK auto-login', () async {
      // 1. Awalnya login di halaman Target (2)
      await SessionService.instance.saveSession(userId: testUser.id!, lastPage: 2);

      // 2. User logout
      await SessionService.instance.clearSession();

      // 3. Simulasikan buka kembali aplikasi
      final screen = await simulateAppLaunch();

      // Verifikasi: tetap berada di LoginPage dan session bersih
      expect(screen, isA<LoginPage>());
      expect(await SessionService.instance.isLoggedIn(), isFalse);
      expect(await SessionService.instance.getSessionUserId(), isNull);
      expect(await SessionService.instance.getLastPage(), equals(0));
    });

    test('TEST 6: Restart beberapa kali -> session dan last page tetap konsisten, tanpa crash dan tanpa loop', () async {
      // Restart 1: Login awal, buka Target (2)
      await SessionService.instance.saveSession(userId: testUser.id!, lastPage: 2);
      var currentApp = await simulateAppLaunch();
      expect(currentApp, isA<MainPage>());
      expect((currentApp as MainPage).initialIndex, equals(2));

      // Restart 2: Ganti ke Transaksi (1), lalu buka ulang aplikasi
      await SessionService.instance.saveLastPage(1);
      currentApp = await simulateAppLaunch();
      expect(currentApp, isA<MainPage>());
      expect((currentApp as MainPage).initialIndex, equals(1));

      // Restart 3: Ganti ke Profil (4), lalu buka ulang aplikasi
      await SessionService.instance.saveLastPage(4);
      currentApp = await simulateAppLaunch();
      expect(currentApp, isA<MainPage>());
      expect((currentApp as MainPage).initialIndex, equals(4));

      // Restart 4: Logout, lalu buka ulang aplikasi
      await SessionService.instance.clearSession();
      currentApp = await simulateAppLaunch();
      expect(currentApp, isA<LoginPage>());
    });
  });
}
