import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;

import '../data/local_database.dart';
import '../services/auth_service.dart';
import '../data/api_config.dart';
import '../models/user.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum _RemoteLoginResult { success, authError, networkError }

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isPasswordVisible = false;
  bool _isLoading = false;
  String? _errorMessage;
  final _tenantController = TextEditingController(text: 'demo');

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _tenantController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });

    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final tenant = _tenantController.text.trim();

    if (email.isEmpty || password.isEmpty || tenant.isEmpty) {
      setState(() {
        _errorMessage = 'Renseignez tenant, email et mot de passe.';
        _isLoading = false;
      });
      return;
    }

    final emailRegex = RegExp(
      r"^[a-zA-Z0-9.a-zA-Z0-9.!#$%&'*+-/=?^_`{|}~]+@[a-zA-Z0-9]+\.[a-zA-Z]+",
    );
    if (!emailRegex.hasMatch(email)) {
      setState(() {
        _errorMessage = 'Email invalide.';
        _isLoading = false;
      });
      return;
    }

    final remoteResult = await _tryRemoteLogin(tenant, email, password);
    if (remoteResult == _RemoteLoginResult.success) {
      if (!mounted) return;
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const MainScreen()),
      );
      return;
    }
    if (remoteResult == _RemoteLoginResult.authError) {
      setState(() {
        _errorMessage = 'Identifiants invalides (serveur).';
        _isLoading = false;
      });
      return;
    }
    // remoteResult == networkError
    setState(() {
      _errorMessage =
          'Serveur indisponible. Vérifiez la connexion ou essayez le mode local.';
      _isLoading = false;
    });
  }

  Future<void> _loginLocal() async {
    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      setState(() {
        _errorMessage = 'Renseignez votre email et votre mot de passe.';
        _isLoading = false;
      });
      return;
    }

    final result = await AuthService.instance.login(email, password);
    if (!mounted) return;

    if (result.success) {
      final user = result.user!;
      if (user.is2faEnabled && user.twoFaSecret.isNotEmpty) {
        final codeOk = await _promptOtp(user.twoFaSecret);
        if (!codeOk) {
          setState(() {
            _errorMessage = 'Code TOTP invalide.';
            _isLoading = false;
          });
          return;
        }
      }
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const MainScreen()));
    } else {
      setState(() {
        _errorMessage = result.message ?? 'Impossible de se connecter.';
        _isLoading = false;
      });
    }
  }

  Future<void> _resetAdmin() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Réinitialiser l\'admin'),
        content: const Text(
          'Cette action recrée le compte admin et supprime les comptes existants. Continuer ?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Annuler'),
          ),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: Colors.redAccent),
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Oui, réinitialiser'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() {
      _errorMessage = null;
      _isLoading = true;
    });
    try {
      final result = await LocalDatabase.instance.resetAdminUser();
      if (!mounted) return;

      await showDialog(
        context: context,
        builder: (context) {
          return AlertDialog(
            backgroundColor: const Color(0xFF1A1A2E),
            title: const Text(
              'Admin réinitialisé',
              style: TextStyle(color: Colors.white),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Nouveau compte créé :',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                SelectableText(
                  result['email'] ?? '',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 8),
                SelectableText(
                  result['password'] ?? '',
                  style: const TextStyle(
                    color: Color(0xFF43e97b),
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Pensez à changer ce mot de passe dès la première connexion.',
                  style: TextStyle(color: Colors.white70),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Fermer'),
              ),
              TextButton(
                onPressed: () async {
                  final pw = result['password'] ?? '';
                  if (pw.isNotEmpty) {
                    await Clipboard.setData(ClipboardData(text: pw));
                  }
                  if (mounted) Navigator.of(context).pop();
                },
                child: const Text('Copier'),
              ),
            ],
          );
        },
      );

      setState(() {
        _passwordController.clear();
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Réinitialisation impossible: $e';
        _isLoading = false;
      });
    }
  }

  Future<_RemoteLoginResult> _tryRemoteLogin(
    String tenant,
    String email,
    String password,
  ) async {
    try {
      final resp = await http.post(
        Uri.parse('${ApiConfig.baseUrl}/api/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'tenant': tenant,
          'email': email,
          'password': password,
        }),
      );
      if (resp.statusCode == 401 || resp.statusCode == 400) {
        setState(() => _errorMessage = 'Identifiants invalides (serveur)');
        return _RemoteLoginResult.authError;
      }
      if (resp.statusCode != 200) {
        setState(() => _errorMessage = 'Serveur indisponible (${resp.statusCode}) : ${resp.body}');
        return _RemoteLoginResult.networkError;
      }
      final parsed = jsonDecode(resp.body) as Map<String, dynamic>;
      final token = parsed['accessToken'] as String?;
      final userPayload = parsed['user'] as Map<String, dynamic>?;
      final tenantId = userPayload?['tenantId'] as String?;
      if (token == null || tenantId == null) {
        setState(() => _errorMessage = 'Réponse invalide du serveur.');
        return _RemoteLoginResult.networkError;
      }

    final current = AuthService.instance.currentUser ??
        User(
          id: 'remote-user',
          name: email.split('@').first,
          email: email,
          passwordHash: '',
          role: UserRole.admin,
          isActive: true,
          createdAt: DateTime.now(),
          lastLogin: DateTime.now(),
          twoFaSecret: '',
          is2faEnabled: false,
          tenantId: tenantId,
        );
      AuthService.instance.setRemoteSession(
        user: current,
        jwt: token,
        tenantId: tenantId,
      );
      setState(() => _isLoading = false);
      return _RemoteLoginResult.success;
    } catch (e) {
      setState(() => _errorMessage = 'Erreur réseau: $e (URL: ${ApiConfig.baseUrl})');
      return _RemoteLoginResult.networkError;
    }
  }
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Container(
            width: double.infinity,
            height: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [Color(0xFF0F0F1E), Color(0xFF1A1A2E)],
              ),
            ),
          ),
          Positioned(
            top: -80,
            right: -60,
            child: Container(
              width: 260,
              height: 260,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF6C63FF).withOpacity(0.28),
                    const Color(0xFF43e97b).withOpacity(0.18),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF6C63FF).withOpacity(0.18),
                    blurRadius: 60,
                    spreadRadius: 10,
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: -120,
            left: -100,
            child: Container(
              width: 280,
              height: 280,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4facfe).withOpacity(0.2),
                    const Color(0xFF00f2fe).withOpacity(0.14),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(32),
              child: Container(
                width: 440,
                padding: const EdgeInsets.all(30),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.05),
                  borderRadius: BorderRadius.circular(22),
                  border: Border.all(color: Colors.white.withOpacity(0.08)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.35),
                      blurRadius: 30,
                      offset: const Offset(0, 18),
                    ),
                    BoxShadow(
                      color: const Color(0xFF6C63FF).withOpacity(0.16),
                      blurRadius: 40,
                      spreadRadius: 6,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF6C63FF), Color(0xFF5A52D5)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(
                                  0xFF6C63FF,
                                ).withOpacity(0.35),
                                blurRadius: 20,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: const Icon(
                            Icons.key_rounded,
                            color: Colors.white,
                            size: 28,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: const [
                            Text(
                              'Roommaster',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 22,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'Connexion sécurisée',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 26),
                    const Text(
                      'Bienvenue',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Accédez au tableau de bord hôtelier.',
                      style: TextStyle(color: Colors.white70, fontSize: 14),
                    ),
                    const SizedBox(height: 20),
                    TextField(
                      controller: _tenantController,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Tenant',
                        labelStyle: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                        ),
                        prefixIcon: const Icon(
                          Icons.apartment_rounded,
                          color: Colors.white70,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF6C63FF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Email',
                        labelStyle: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                        ),
                        prefixIcon: const Icon(
                          Icons.mail_outline,
                          color: Colors.white70,
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF6C63FF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: _passwordController,
                      obscureText: !_isPasswordVisible,
                      style: const TextStyle(color: Colors.white),
                      decoration: InputDecoration(
                        labelText: 'Mot de passe',
                        labelStyle: TextStyle(
                          color: Colors.white.withOpacity(0.7),
                        ),
                        prefixIcon: const Icon(
                          Icons.lock_outline,
                          color: Colors.white70,
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _isPasswordVisible
                                ? Icons.visibility
                                : Icons.visibility_off,
                            color: Colors.white70,
                          ),
                          onPressed: () {
                            setState(() {
                              _isPasswordVisible = !_isPasswordVisible;
                            });
                          },
                        ),
                        filled: true,
                        fillColor: Colors.white.withOpacity(0.06),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: Colors.white.withOpacity(0.1),
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(
                            color: Color(0xFF6C63FF),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 14),
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.withOpacity(0.08),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.red.withOpacity(0.3),
                          ),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: const TextStyle(color: Colors.redAccent),
                        ),
                      ),
                    const SizedBox(height: 12),
                    Row(
                      children: const [
                        Icon(
                          Icons.shield_moon_rounded,
                          size: 18,
                          color: Color(0xFF43e97b),
                        ),
                        SizedBox(width: 8),
                        Text(
                          'Connexion chiffrée en local',
                          style: TextStyle(color: Colors.white70, fontSize: 13),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Column(
                      children: [
                        ElevatedButton(
                          onPressed: _isLoading ? null : _login,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF6C63FF),
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                              horizontal: 20,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              if (_isLoading)
                                const Padding(
                                  padding: EdgeInsets.only(right: 12),
                                  child: SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.4,
                                      color: Colors.white,
                                    ),
                                  ),
                                ),
                              const Text(
                                'Se connecter (API)',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 10),
                        OutlinedButton(
                          onPressed: _isLoading ? null : _loginLocal,
                          style: OutlinedButton.styleFrom(
                            side: BorderSide(color: Colors.white.withOpacity(0.3)),
                          ),
                          child: const Text(
                            'Essayer en mode local',
                            style: TextStyle(color: Colors.white70),
                          ),
                        ),
                        const SizedBox(height: 10),
                        TextButton(
                          onPressed: _isLoading ? null : _resetAdmin,
                          child: const Text("Réinitialiser l'admin"),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<bool> _promptOtp(String secret) async {
    final codeCtrl = TextEditingController();
    final ok = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Vérification TOTP'),
        content: TextField(
          controller: codeCtrl,
          keyboardType: TextInputType.number,
          maxLength: 6,
          decoration: const InputDecoration(labelText: 'Code à 6 chiffres'),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.pop(context, AuthService.instance.verifyTotp(secret, codeCtrl.text)),
            child: const Text('Valider'),
          ),
        ],
      ),
    );
    return ok ?? false;
  }
}
