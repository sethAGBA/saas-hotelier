// lib/main.dart
import 'package:flutter/material.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'dart:io' show Platform;
import 'package:firebase_core/firebase_core.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'firebase_options.dart';

import 'app.dart';
import 'services/database_service.dart';
import 'services/auth_service.dart';
import 'services/sync_service.dart';
import 'screen/login_screen.dart';
import 'screen/main_screen.dart';
import 'dart:convert'; // For utf8.encode
import 'package:crypto/crypto.dart'; // For sha256
import 'models/user.dart'; // For User and UserRole
import 'package:shared_preferences/shared_preferences.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  // Initialize Firebase (desktop/web) with optional emulator support
  await _initFirebase();
  await initializeDateFormatting('fr_FR', null);
  await DatabaseService().init(); // Initialize database
  // For initial setup, create a default admin user if none exists
  final users = await DatabaseService().getUsers();
  if (users.isEmpty) {
    // Create a default admin user (password: admin123)
    final defaultAdmin = User(
      id: 'admin',
      name: 'Admin',
      email: 'admin@afroforma.com',
      passwordHash: sha256.convert(utf8.encode('admin123')).toString(), // Hashed password for 'admin123'
      role: UserRole.admin,
      permissions: [],
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      isActive: true,
    );
    await DatabaseService().insertUser(defaultAdmin);
  }

  Widget initialScreen;
  // In a real app, you'd check for a persistent session here
  // For now, we'll always start with LoginScreen unless a user is already "logged in" (AuthService._currentUser is set)
  if (await AuthService.checkLoggedIn()) {
    initialScreen =  MainScreen();
  } else {
    initialScreen = const LoginScreen();
  }

  // Start a lightweight background sync (non-blocking)
  Future.microtask(() async {
    try {
      // Start initial sync and periodic sync thereafter
      final sync = SyncService();
      await sync.runOnce();
      sync.startPeriodic(interval: const Duration(minutes: 5));
    } catch (_) {}
  });

  runApp(FormationManagementApp(initialScreen: initialScreen));
}

const String kFirebaseEmail = String.fromEnvironment('FIREBASE_EMAIL', defaultValue: '');
const String kFirebasePassword = String.fromEnvironment('FIREBASE_PASSWORD', defaultValue: '');

Future<void> _initFirebase() async {
  try {
    // Initialize on supported targets (web, macOS, Windows, Android, iOS)
    if (kIsWeb || Platform.isMacOS || Platform.isWindows || Platform.isAndroid || Platform.isIOS) {
      await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

      // Sur desktop (macOS/Windows), on évite la connexion automatique via plugin
      // La connexion se fait via REST dans l'écran de login si nécessaire.
      if (!(Platform.isMacOS || Platform.isWindows)) {
        // Optional: sign-in with a technical account provided via dart-defines or saved prefs
        String email = kFirebaseEmail;
        String pass = kFirebasePassword;
        try {
          if (email.isEmpty || pass.isEmpty) {
            final sp = await SharedPreferences.getInstance();
            email = sp.getString('firebase_email') ?? '';
            pass = sp.getString('firebase_password') ?? '';
          }
        } catch (_) {}
        if (email.isNotEmpty && pass.isNotEmpty) {
          try {
            await fb_auth.FirebaseAuth.instance.signInWithEmailAndPassword(email: email, password: pass);
          } catch (e) {
            // ignore: avoid_print
            print('Firebase Auth sign-in failed: $e');
          }
        }
      }
    }
  } catch (e) {
    // Swallow init errors to avoid blocking the app if Firebase is misconfigured on some targets
    // ignore: avoid_print
    print('Firebase init skipped or failed: $e');
  }
}
