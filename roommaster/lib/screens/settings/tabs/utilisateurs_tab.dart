import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/material.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:otp/otp.dart';

import '../../../data/local_database.dart';
import '../../../models/user.dart';
import '../../../services/auth_service.dart';
import '../widgets/setting_card.dart';

class UtilisateursTab extends StatefulWidget {
  const UtilisateursTab({super.key});

  @override
  State<UtilisateursTab> createState() => _UtilisateursTabState();
}

class _UtilisateursTabState extends State<UtilisateursTab> {
  List<User> _users = [];
  String _roleFilter = 'Tous';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final users = await LocalDatabase.instance.getUsers();
    setState(() {
      _users = users;
      _loading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _roleFilter == 'Tous'
        ? _users
        : _users.where((u) => _roleToString(u.role) == _roleFilter).toList();

    return Column(
      children: [
        SettingCard(
          title: 'Utilisateurs',
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _roleFilter,
                  dropdownColor: const Color(0xFF1E293B),
                  style: const TextStyle(color: Colors.white),
                  decoration: InputDecoration(
                    labelText: 'Filtrer par rôle',
                    labelStyle: const TextStyle(color: Colors.white70),
                    filled: true,
                    fillColor: Colors.white.withOpacity(0.05),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(
                        color: Colors.white.withOpacity(0.1),
                      ),
                    ),
                    focusedBorder: const OutlineInputBorder(
                      borderRadius: BorderRadius.all(Radius.circular(12)),
                      borderSide: BorderSide(color: Color(0xFF6366F1)),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Tous', child: Text('Tous')),
                    DropdownMenuItem(value: 'Admin', child: Text('Admin')),
                    DropdownMenuItem(
                      value: 'Réception',
                      child: Text('Réception'),
                    ),
                    DropdownMenuItem(
                      value: 'Maintenance',
                      child: Text('Maintenance'),
                    ),
                  ],
                  onChanged: (v) => setState(() => _roleFilter = v ?? 'Tous'),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: _showCreateUserDialog,
                icon: const Icon(Icons.person_add, color: Colors.white),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF10B981),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 18,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                label: const Text(
                  'Nouvel utilisateur',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        Expanded(
          child: _loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) =>
                      _buildUserCard(filtered[index]),
                ),
        ),
      ],
    );
  }

  Widget _buildUserCard(User user) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.03),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withOpacity(0.08)),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: const Color(0xFF6C63FF),
            child: Text(
              user.name.isNotEmpty ? user.name[0].toUpperCase() : '?',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  user.name,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  user.email,
                  style: TextStyle(color: Colors.white.withOpacity(0.7)),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Chip(
                      label: Text(_roleToString(user.role)),
                      backgroundColor: Colors.white.withOpacity(0.08),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                    const SizedBox(width: 8),
                    Chip(
                      label: Text(user.isActive ? 'Actif' : 'Inactif'),
                      backgroundColor: user.isActive
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      labelStyle: const TextStyle(color: Colors.white),
                    ),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.edit, color: Colors.white70),
            onPressed: () => _showEditUserDialog(user),
          ),
          IconButton(
            icon: const Icon(Icons.lock_reset, color: Colors.orange),
            tooltip: 'Réinitialiser le mot de passe',
            onPressed: () => _resetPassword(user),
          ),
          Switch(
            value: user.isActive,
            onChanged: (v) => _toggleActive(user, v),
            activeColor: const Color(0xFF10B981),
          ),
        ],
      ),
    );
  }

  Future<void> _showCreateUserDialog() async {
    final nameCtrl = TextEditingController();
    final emailCtrl = TextEditingController();
    final passwordCtrl = TextEditingController();
    UserRole role = UserRole.reception;
    final created = await showDialog<User>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Nouvel utilisateur'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: nameCtrl,
                  decoration: const InputDecoration(labelText: 'Nom'),
                ),
                TextField(
                  controller: emailCtrl,
                  decoration: const InputDecoration(labelText: 'Email'),
                ),
                TextField(
                  controller: passwordCtrl,
                  decoration: const InputDecoration(labelText: 'Mot de passe'),
                  obscureText: true,
                ),
                const SizedBox(height: 8),
                DropdownButtonFormField<UserRole>(
                  value: role,
                  decoration: const InputDecoration(labelText: 'Rôle'),
                  items: const [
                    DropdownMenuItem(
                      value: UserRole.admin,
                      child: Text('Admin'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.reception,
                      child: Text('Réception'),
                    ),
                    DropdownMenuItem(
                      value: UserRole.maintenance,
                      child: Text('Maintenance'),
                    ),
                  ],
                  onChanged: (v) => role = v ?? UserRole.reception,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                if (nameCtrl.text.isEmpty ||
                    emailCtrl.text.isEmpty ||
                    passwordCtrl.text.isEmpty ||
                    !_isValidEmail(emailCtrl.text)) {
                  return;
                }
                final now = DateTime.now();
                final hashed = sha256
                    .convert(utf8.encode(passwordCtrl.text))
                    .toString();
                final newUser = User(
                  id: 'user_${now.millisecondsSinceEpoch}',
                  name: nameCtrl.text.trim(),
                  email: emailCtrl.text.trim(),
                  role: role,
                  passwordHash: hashed,
                  createdAt: now,
                  lastLogin: now,
                  isActive: true,
                );
                Navigator.pop(context, newUser);
              },
              child: const Text('Créer'),
            ),
          ],
        );
      },
    );

    if (created != null) {
      await LocalDatabase.instance.saveUser(created);
      _loadUsers();
    }
  }

  Future<void> _showEditUserDialog(User user) async {
    final nameCtrl = TextEditingController(text: user.name);
    final emailCtrl = TextEditingController(text: user.email);
    UserRole role = user.role;
    final newPassCtrl = TextEditingController();
    final updated = await showDialog<User>(
      context: context,
      builder: (context) {
        bool twoFa = user.is2faEnabled;
        String secret = user.twoFaSecret;
        return StatefulBuilder(
          builder: (context, setStateDialog) {
            return AlertDialog(
              title: const Text('Modifier utilisateur'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextField(
                      controller: nameCtrl,
                      decoration: const InputDecoration(labelText: 'Nom'),
                    ),
                    TextField(
                      controller: emailCtrl,
                      decoration: const InputDecoration(labelText: 'Email'),
                    ),
                    const SizedBox(height: 8),
                    TextField(
                      controller: newPassCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Nouveau mot de passe',
                      ),
                      obscureText: true,
                    ),
                    const SizedBox(height: 8),
                    DropdownButtonFormField<UserRole>(
                      value: role,
                      decoration: const InputDecoration(labelText: 'Rôle'),
                      items: const [
                        DropdownMenuItem(
                          value: UserRole.admin,
                          child: Text('Admin'),
                        ),
                        DropdownMenuItem(
                          value: UserRole.reception,
                          child: Text('Réception'),
                        ),
                        DropdownMenuItem(
                          value: UserRole.maintenance,
                          child: Text('Maintenance'),
                        ),
                      ],
                      onChanged: (v) => role = v ?? UserRole.reception,
                    ),
                    const SizedBox(height: 8),
                    SwitchListTile(
                      value: twoFa,
                      onChanged: (v) {
                        setStateDialog(() => twoFa = v);
                        if (v) {
                          _showTotpDialog(
                            emailCtrl.text.trim(),
                            secret.isNotEmpty ? secret : null,
                          ).then((result) {
                            if (result != null) {
                              setStateDialog(() {
                                twoFa = result.$1;
                                secret = result.$2;
                              });
                            } else {
                              setStateDialog(() => twoFa = false);
                            }
                          });
                        }
                      },
                      title: const Text('Activer TOTP (2FA)'),
                      subtitle: secret.isNotEmpty
                          ? Text(
                              'Secret actuel: $secret',
                              style: const TextStyle(fontSize: 12),
                            )
                          : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  onPressed: () {
                    String? newHash = user.passwordHash;
                    if (newPassCtrl.text.isNotEmpty) {
                      newHash = sha256
                          .convert(utf8.encode(newPassCtrl.text))
                          .toString();
                    }
                    if (!_isValidEmail(emailCtrl.text)) {
                      return;
                    }
                    final upd = user.copyWith(
                      name: nameCtrl.text.trim(),
                      email: emailCtrl.text.trim(),
                      role: role,
                      is2faEnabled: twoFa,
                      twoFaSecret: secret,
                      passwordHash: newHash,
                    );
                    Navigator.pop(context, upd);
                  },
                  child: const Text('Enregistrer'),
                ),
              ],
            );
          }, // end StatefulBuilder builder
        ); // end StatefulBuilder
      }, // end showDialog builder
    ); // end showDialog

    if (updated != null) {
      await LocalDatabase.instance.updateUser(updated);
      _loadUsers();
    }
  }

  Future<void> _toggleActive(User user, bool active) async {
    if (!active && user.role == UserRole.admin) {
      final admins = await LocalDatabase.instance.countActiveAdmins();
      if (admins <= 1) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Impossible de désactiver le dernier administrateur.',
            ),
          ),
        );
        return;
      }
      final ok =
          await showDialog<bool>(
            context: context,
            builder: (context) => AlertDialog(
              title: const Text('Désactiver un admin'),
              content: const Text(
                'Voulez-vous vraiment désactiver cet administrateur ?',
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context, false),
                  child: const Text('Annuler'),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.red),
                  onPressed: () => Navigator.pop(context, true),
                  child: const Text('Désactiver'),
                ),
              ],
            ),
          ) ??
          false;
      if (!ok) return;
    }

    final updated = user.copyWith(isActive: active);
    await LocalDatabase.instance.updateUser(updated);
    _loadUsers();
  }

  Future<void> _resetPassword(User user) async {
    final newPass = _generatePassword();
    final hashed = sha256.convert(utf8.encode(newPass)).toString();
    final updated = user.copyWith(passwordHash: hashed);
    await LocalDatabase.instance.updateUser(updated);
    if (!mounted) return;
    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Mot de passe réinitialisé'),
        content: Text('Nouveau mot de passe: $newPass'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
    _loadUsers();
  }

  Future<(bool, String)> _showTotpDialog(
    String email,
    String? existingSecret,
  ) async {
    final baseSecret = (existingSecret?.isNotEmpty ?? false)
        ? existingSecret!
        : OTP.randomSecret();
    String secret = baseSecret.replaceAll(' ', '').toUpperCase();
    final userLabel = email.isNotEmpty ? email : 'utilisateur';
    final uri =
        'otpauth://totp/Roommaster:${Uri.encodeComponent(userLabel)}?secret=$secret&issuer=Roommaster&algorithm=SHA1&digits=6&period=30';
    final codeCtrl = TextEditingController();

    final enabled = await showDialog<bool>(
      context: context,
      barrierDismissible: true,
      barrierColor: Colors.black54,
      builder: (context) {
        return AlertDialog(
          backgroundColor: const Color(0xFF0F172A),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          title: const Text(
            'Configurer TOTP',
            style: TextStyle(color: Colors.white),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text(
                  'Scannez ce QR ou entrez le secret ci-dessous',
                  style: TextStyle(color: Colors.white70),
                ),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: QrImageView(
                    data: uri,
                    size: 180,
                    backgroundColor: Colors.white,
                  ),
                ),
                const SizedBox(height: 12),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Secret',
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
                SelectableText(
                  secret,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: codeCtrl,
                  keyboardType: TextInputType.number,
                  maxLength: 6,
                  textAlign: TextAlign.center,
                  decoration: const InputDecoration(
                    labelText: 'Code TOTP',
                    labelStyle: TextStyle(color: Colors.white70),
                  ),
                  style: const TextStyle(color: Colors.white),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text('Annuler'),
            ),
            TextButton(
              onPressed: () {
                final ok = AuthService.instance.verifyTotp(
                  secret,
                  codeCtrl.text,
                );
                Navigator.pop(context, ok);
              },
              child: const Text('Valider'),
            ),
          ],
        );
      },
    );

    if (enabled == true) {
      return (true, secret);
    }
    return (false, existingSecret ?? '');
  }

  String _generatePassword() {
    const chars =
        'ABCDEFGHJKLMNPQRSTUVWXYZabcdefghijkmnopqrstuvwxyz23456789!@#%&*()-_=+';
    final rng = Random.secure();
    return List.generate(12, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  String _roleToString(UserRole role) {
    switch (role) {
      case UserRole.admin:
        return 'Admin';
      case UserRole.reception:
        return 'Réception';
      case UserRole.maintenance:
        return 'Maintenance';
    }
  }

  // ignore: unused_element
  String _generateSecret() {
    const chars = 'ABCDEFGHIJKLMNOPQRSTUVWXYZ234567';
    final rng = Random.secure();
    return List.generate(16, (_) => chars[rng.nextInt(chars.length)]).join();
  }

  bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
    return regex.hasMatch(email.trim());
  }
}
