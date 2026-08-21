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
  });

  group('SessionService Unit Tests', () {
    test('saveSession sets isLoggedIn, userId, and lastPage', () async {
      final session = SessionService.instance;
      await session.saveSession(userId: 1, lastPage: 2);

      expect(await session.isLoggedIn(), isTrue);
      expect(await session.getSessionUserId(), equals(1));
      expect(await session.getLastPage(), equals(2));
    });

    test('saveLastPage updates last page index independently', () async {
      final session = SessionService.instance;
      await session.saveSession(userId: 1, lastPage: 0);

      // Pindah ke Transaksi (1)
      await session.saveLastPage(1);
      expect(await session.getLastPage(), equals(1));

      // Pindah ke Target (2)
      await session.saveLastPage(2);
      expect(await session.getLastPage(), equals(2));

      // Pindah ke AI (3)
      await session.saveLastPage(3);
      expect(await session.getLastPage(), equals(3));

      // Pindah ke Profil (4)
      await session.saveLastPage(4);
      expect(await session.getLastPage(), equals(4));
    });

    test('getLastPage clamps invalid out-of-range index to 0 (Beranda)', () async {
      final session = SessionService.instance;
      await session.saveLastPage(99);
      expect(await session.getLastPage(), equals(0));

      await session.saveLastPage(-5);
      expect(await session.getLastPage(), equals(0));
    });

    test('clearSession removes all session keys and resets state', () async {
      final session = SessionService.instance;
      await session.saveSession(userId: 1, lastPage: 3);

      expect(await session.isLoggedIn(), isTrue);
      expect(await session.getSessionUserId(), equals(1));

      await session.clearSession();

      expect(await session.isLoggedIn(), isFalse);
      expect(await session.getSessionUserId(), isNull);
      expect(await session.getLastPage(), equals(0));
    });
  });

  group('DatabaseHelper getUserById', () {
    test('getUserById retrieves correct user from database', () async {
      final db = await DatabaseHelper.instance.database;
      await db.delete('users');
      final insertedId = await DatabaseHelper.instance.insertUser(testUser);

      final user = await DatabaseHelper.instance.getUserById(insertedId);
      expect(user, isNotNull);
      expect(user!.name, equals(testUser.name));
      expect(user.email, equals(testUser.email));

      final nonExistent = await DatabaseHelper.instance.getUserById(99999);
      expect(nonExistent, isNull);
    });
  });

  group('MainPage & Last Page Restore Widget Tests', () {
    testWidgets('MainPage starts at initialIndex = 0 (Beranda) by default', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MainPage(user: testUser, initialIndex: 0),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, equals(0));

      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('MainPage restores initialIndex = 2 (Target) directly on open', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MainPage(user: testUser, initialIndex: 2),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, equals(2));
      expect(find.text('Target'), findsWidgets);

      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('MainPage restores initialIndex = 1 (Transaksi) directly on open', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MainPage(user: testUser, initialIndex: 1),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, equals(1));
      expect(find.text('Transaksi'), findsWidgets);

      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('MainPage restores initialIndex = 3 (AI) directly on open', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MainPage(user: testUser, initialIndex: 3),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      final navBar = tester.widget<NavigationBar>(find.byType(NavigationBar));
      expect(navBar.selectedIndex, equals(3));
      expect(find.text('AI'), findsWidgets);

      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('Selecting NavigationBar tab saves lastPage to SessionService', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: MainPage(user: testUser, initialIndex: 0),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Tap tab Target (index 2)
      await tester.tap(find.byIcon(Icons.flag_outlined));
      await tester.pump(const Duration(milliseconds: 300));

      expect(await SessionService.instance.getLastPage(), equals(2));

      // Tap tab Transaksi (index 1)
      await tester.tap(find.byIcon(Icons.receipt_long_outlined));
      await tester.pump(const Duration(milliseconds: 300));

      expect(await SessionService.instance.getLastPage(), equals(1));

      await tester.pump(const Duration(seconds: 15));
    });

    testWidgets('Logout confirmation clears session and navigates to LoginPage', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await SessionService.instance.saveSession(userId: 1, lastPage: 4);
      expect(await SessionService.instance.isLoggedIn(), isTrue);

      await tester.pumpWidget(
        MaterialApp(
          home: MainPage(user: testUser, initialIndex: 4),
        ),
      );
      await tester.pump(const Duration(milliseconds: 300));

      // Tekan tombol logout
      final logoutButton = find.text('Keluar dari Akun');
      expect(logoutButton, findsOneWidget);
      await tester.ensureVisible(logoutButton);
      await tester.tap(logoutButton);
      await tester.pump(const Duration(milliseconds: 300));

      // Dialog konfirmasi muncul
      expect(find.text('Logout?'), findsOneWidget);
      expect(find.text('Apakah kamu yakin ingin keluar dari akun ini?'), findsOneWidget);

      // Konfirmasi Logout
      final confirmLogout = find.widgetWithText(ElevatedButton, 'Logout');
      await tester.tap(confirmLogout);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pump(const Duration(milliseconds: 500));

      // Session harus bersih
      expect(await SessionService.instance.isLoggedIn(), isFalse);
      expect(await SessionService.instance.getSessionUserId(), isNull);
      expect(await SessionService.instance.getLastPage(), equals(0));

      // Harus berada di LoginPage
      expect(find.byType(LoginPage), findsOneWidget);

      await tester.pump(const Duration(seconds: 15));
    });
  });
}
