import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:otp/otp.dart';

import '../data/local_database.dart';
import '../models/user.dart';

class LoginResult {
  final bool success;
  final User? user;
  final String? message;

  const LoginResult({required this.success, this.user, this.message});
}

class AuthService {
  AuthService._();

  static final AuthService instance = AuthService._();

  User? _currentUser;

  User? get currentUser => _currentUser;

  Future<LoginResult> login(String email, String password) async {
    final normalizedEmail = email.trim().toLowerCase();
    final user = await LocalDatabase.instance.getUserByEmail(normalizedEmail);

    if (user == null || !user.isActive) {
      return const LoginResult(
        success: false,
        message: 'Utilisateur introuvable ou inactif.',
      );
    }

    final hashedPassword = sha256.convert(utf8.encode(password)).toString();
    if (hashedPassword != user.passwordHash) {
      return const LoginResult(
        success: false,
        message: 'Email ou mot de passe incorrect.',
      );
    }

    final updatedUser = user.copyWith(lastLogin: DateTime.now());
    await LocalDatabase.instance.updateUser(updatedUser);
    _currentUser = updatedUser;
    return LoginResult(success: true, user: updatedUser);
  }

  Future<bool> isLoggedIn() async {
    return _currentUser != null;
  }

  void logout() {
    _currentUser = null;
  }

  bool verifyTotp(String secret, String code) {
    final trimmed = code.replaceAll(' ', '');
    if (trimmed.length != 6) return false;
    final normSecret = secret.replaceAll(' ', '').toUpperCase();
    final nowMs = DateTime.now().millisecondsSinceEpoch;
    for (int offset = -1; offset <= 1; offset++) {
      try {
        final generated = OTP.generateTOTPCodeString(
          normSecret,
          nowMs + offset * 30 * 1000,
          interval: 30,
          length: 6,
          algorithm: Algorithm.SHA1,
          isGoogle: true,
        );
        if (generated == trimmed) return true;
      } catch (_) {}
    }
    return false;
  }
}
