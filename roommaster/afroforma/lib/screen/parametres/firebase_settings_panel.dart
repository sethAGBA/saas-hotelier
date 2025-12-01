import 'package:afroforma/services/firebase_admin_api.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:http/http.dart' as http;
import 'package:afroforma/firebase_options.dart';
import 'dart:convert';
import 'package:afroforma/services/firebase_rest_auth_service.dart';
import 'package:afroforma/services/notification_service.dart';
import 'package:afroforma/services/auth_service.dart';
import 'package:afroforma/services/database_service.dart';

class FirebaseSettingsPanel extends StatefulWidget {
  const FirebaseSettingsPanel({super.key});

  @override
  State<FirebaseSettingsPanel> createState() => _FirebaseSettingsPanelState();
}

class _FirebaseSettingsPanelState extends State<FirebaseSettingsPanel>
    with SingleTickerProviderStateMixin {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _passConfirmCtrl = TextEditingController();
  final _displayNameCtrl = TextEditingController();
  final _newPassCtrl = TextEditingController();
  final _newPassConfirmCtrl = TextEditingController();
  
  bool _loading = false;
  String? _status;
  String _diagnostic = '';
  String _diagnosticRest = '';
  bool _showLoginPass = false;
  bool _showCreatePassConfirm = false;
  bool _showNewPass = false;
  bool _showNewPassConfirm = false;
  
  late TabController _tabController;
  int _currentTabIndex = 0;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _currentTabIndex = _tabController.index;
      });
    });
    _load();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _passConfirmCtrl.dispose();
    _displayNameCtrl.dispose();
    _newPassCtrl.dispose();
    _newPassConfirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() {});
  }

  // [Garder toutes les méthodes existantes - _saveAndSignIn, _updateSelfDisplayName, etc.]
  Future<void> _saveAndSignIn() async {
    setState(() { _loading = true; _status = null; });
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString('firebase_email', _emailCtrl.text.trim());
      await sp.setString('firebase_password', _passCtrl.text);

      if (_emailCtrl.text.isNotEmpty && _passCtrl.text.isNotEmpty) {
        try {
          await fb_auth.FirebaseAuth.instance.signInWithEmailAndPassword(
            email: _emailCtrl.text.trim(),
            password: _passCtrl.text,
          );
          _emailCtrl.clear();
          _passCtrl.clear();
          _passConfirmCtrl.clear();
          setState(() { _status = 'Connecté'; });
        } on fb_auth.FirebaseAuthException catch (e) {
          setState(() { _status = 'Auth error: ${e.code} ${e.message ?? ''}'; });
          return;
        }
      }
      setState(() { _status = fb_auth.FirebaseAuth.instance.currentUser != null ? 'Connecté' : 'OK'; });
    } catch (e) {
      setState(() { _status = 'Erreur: $e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _updateSelfDisplayName() async {
    setState(() { _loading = true; _status = null; });
    try {
      final name = _displayNameCtrl.text.trim();
      if (name.isEmpty) { setState(() { _status = 'Nom vide'; }); return; }
      final api = FirebaseAdminApi();
      await api.updateSelfProfile(displayName: name);
      try {
        await fb_auth.FirebaseAuth.instance.currentUser?.reload();
      } catch (_) {}
      final fb = fb_auth.FirebaseAuth.instance.currentUser;
      final newName = fb?.displayName ?? name;
      final current = AuthService.currentUser;
      if (current != null) {
        final updated = current.copyWith(name: newName);
        await DatabaseService().updateUser(updated);
        AuthService.setCurrentUser(updated);
        NotificationService().showNotification(NotificationItem(id: DateTime.now().millisecondsSinceEpoch.toString(), message: 'Nom mis à jour'));
      }
      setState(() { _status = 'Nom mis à jour avec succès'; });
    } catch (e) {
      setState(() { _status = 'Erreur update nom: $e'; });
    } finally { setState(() { _loading = false; }); }
  }

  Future<void> _changeSelfPassword() async {
    setState(() { _loading = true; _status = null; });
    try {
      final newPass = _newPassCtrl.text;
      if (newPass.length < 6) { setState(() { _status = 'Mot de passe trop court (min. 6 caractères)'; }); return; }
      if (newPass != _newPassConfirmCtrl.text) {
        setState(() { _status = 'Les mots de passe ne correspondent pas'; });
        return;
      }
      final api = FirebaseAdminApi();
      await api.updateSelfPassword(newPass);
      _newPassCtrl.clear();
      _newPassConfirmCtrl.clear();
      setState(() { _status = 'Mot de passe mis à jour avec succès'; });
    } catch (e) {
      setState(() { _status = 'Erreur update mot de passe: $e'; });
    } finally { setState(() { _loading = false; }); }
  }

  Future<void> _signOut() async {
    await fb_auth.FirebaseAuth.instance.signOut();
    setState(() { _status = 'Déconnecté avec succès'; });
  }

  Future<void> _createAccount() async {
    setState(() { _loading = true; _status = null; });
    try {
      final email = _emailCtrl.text.trim();
      final pass = _passCtrl.text;
      final pass2 = _passConfirmCtrl.text;
      
      if (email.isEmpty || pass.isEmpty) {
        setState(() { _status = 'Email et mot de passe requis'; });
        return;
      }
      
      if (pass != pass2) {
        setState(() { _status = 'Les mots de passe ne correspondent pas'; });
        return;
      }
      
      final useRest = !kIsWeb && (Platform.isWindows || Platform.isMacOS);
      if (useRest) {
        await _createAccountRest(email, pass);
        setState(() { _status = 'Compte créé avec succès (REST)'; });
      } else {
        await fb_auth.FirebaseAuth.instance.createUserWithEmailAndPassword(email: email, password: pass);
        setState(() { _status = 'Compte créé avec succès'; });
      }
      _emailCtrl.clear();
      _passCtrl.clear();
      _passConfirmCtrl.clear();
    } on fb_auth.FirebaseAuthException catch (e) {
      setState(() { _status = 'Erreur de création: ${e.code} ${e.message ?? ''}'; });
    } catch (e) {
      setState(() { _status = 'Erreur: $e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _createAccountRest(String email, String password) async {
    final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;
    final uri = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signUp?key=$apiKey');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: '{"email":"$email","password":"$password","returnSecureToken":true}',
    );
    if (resp.statusCode != 200) {
      throw Exception('REST signUp error ${resp.statusCode}: ${resp.body}');
    }
  }

  Future<void> _createAdminDoc() async {
    final useRest = !kIsWeb && Platform.isWindows;
    if (useRest) {
      await _createAdminDocRest();
      return;
    }
    final user = fb_auth.FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() { _status = 'Non connecté'; });
      return;
    }
    try {
      await FirebaseFirestore.instance.collection('administrateurs').doc(user.uid).set({
        'email': user.email ?? '',
        'createdAt': FieldValue.serverTimestamp(),
        'createdBy': user.uid,
        'isActive': true,
      }, SetOptions(merge: true));
      setState(() { _status = 'Rôle administrateur créé avec succès'; });
    } on FirebaseException catch (e) {
      setState(() { _status = 'Erreur Firestore: ${e.code} ${e.message ?? ''}'; });
    } catch (e) {
      setState(() { _status = 'Erreur: $e'; });
    }
  }

  Future<void> _createAdminDocRest() async {
    setState(() { _status = null; _loading = true; });
    try {
      final email = _emailCtrl.text.trim();
      final pass = _passCtrl.text;
      if (email.isEmpty || pass.isEmpty) {
        setState(() { _status = 'Veuillez saisir email et mot de passe'; });
        return;
      }
      final key = DefaultFirebaseOptions.currentPlatform.apiKey;
      final projectId = DefaultFirebaseOptions.currentPlatform.projectId;

      final signInUrl = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$key');
      final signInResp = await http.post(
        signInUrl,
        headers: {'Content-Type': 'application/json'},
        body: '{"email":"$email","password":"$pass","returnSecureToken":true}',
      );
      if (signInResp.statusCode != 200) {
        throw Exception('Auth REST error ${signInResp.statusCode}: ${signInResp.body}');
      }
      final signInData = jsonDecode(signInResp.body) as Map<String, dynamic>;
      final idToken = signInData['idToken'] as String?;
      final uid = signInData['localId'] as String?;
      if (idToken == null || uid == null) {
        throw Exception('Réponse REST invalide (token/uid manquant)');
      }

      final region = 'us-central1';
      final url = Uri.parse('https://$region-$projectId.cloudfunctions.net/bootstrapSelfAdmin');
      final payload = jsonEncode({ 'data': { 'email': email, 'name': email } });
      final resp = await http.post(
        url,
        headers: {
          'Authorization': 'Bearer $idToken',
          'Content-Type': 'application/json',
        },
        body: payload,
      );
      if (resp.statusCode != 200) {
        throw Exception('Callable error ${resp.statusCode}: ${resp.body}');
      }
      setState(() { _status = 'Administrateur créé (REST via Function)'; });
    } catch (e) {
      setState(() { _status = 'Erreur REST: $e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Future<void> _testConnectivity() async {
    setState(() { _diagnostic = 'Test de connectivité en cours...'; });
    Future<String> check(String host, int port, {Duration timeout = const Duration(seconds: 2)}) async {
      try {
        final s = await Socket.connect(host, port, timeout: timeout);
        s.destroy();
        return '✅';
      } catch (e) {
        return '❌';
      }
    }
    final idtk = await check('identitytoolkit.googleapis.com', 443);
    final fs = await check('firestore.googleapis.com', 443);
    final storage = await check('storage.googleapis.com', 443);
    final emuAuth = await check('127.0.0.1', 9099);
    final emuFs = await check('127.0.0.1', 8080);
    final emuSt = await check('127.0.0.1', 9199);
    setState(() {
      _diagnostic = 'Cloud: Auth $idtk | Firestore $fs | Storage $storage\nÉmulateurs: Auth $emuAuth | FS $emuFs | Storage $emuSt';
    });
  }

  Future<void> _testConnectivityRest() async {
    setState(() { _diagnosticRest = 'Test API REST en cours...'; });
    try {
      final key = DefaultFirebaseOptions.currentPlatform.apiKey;
      final projectId = DefaultFirebaseOptions.currentPlatform.projectId;
      final authUrl = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$key');
      final authResp = await http.post(authUrl, headers: {'Content-Type': 'application/json'}, body: '{}');
      final fsUrl = Uri.parse('https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/.well-known/does-not-exist');
      final fsResp = await http.get(fsUrl);
      setState(() {
        _diagnosticRest = 'API REST: Auth (${authResp.statusCode}) | Firestore (${fsResp.statusCode})';
      });
    } catch (e) {
      setState(() { _diagnosticRest = 'Erreur API REST: $e'; });
    }
  }

  Future<void> _testRestSignIn() async {
    setState(() { _loading = true; _status = null; });
    try {
      final email = _emailCtrl.text.trim();
      final pass = _passCtrl.text;
      if (email.isEmpty || pass.isEmpty) {
        setState(() { _status = 'Veuillez saisir email et mot de passe'; });
        return;
      }
      final rest = FirebaseRestAuthService();
      final user = await rest.signInAndFetchAdmin(email, pass);
      await rest.upsertLocalUser(user);
      setState(() { _status = 'Connexion REST réussie (${user.email})'; });
    } catch (e) {
      setState(() { _status = 'Erreur de connexion REST: $e'; });
    } finally {
      setState(() { _loading = false; });
    }
  }

  Widget _buildStatusIndicator() {
    if (_status == null) return const SizedBox.shrink();
    
    final isSuccess = _status!.contains('succès') || 
                     _status!.contains('Connecté') || 
                     _status!.contains('créé') ||
                     _status!.contains('mis à jour');
    
    return Container(
      margin: const EdgeInsets.only(top: 12),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: isSuccess ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
        border: Border.all(
          color: isSuccess ? Colors.green.withOpacity(0.3) : Colors.red.withOpacity(0.3),
        ),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(
            isSuccess ? Icons.check_circle : Icons.error,
            color: isSuccess ? Colors.green : Colors.red,
            size: 16,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              _status!,
              style: TextStyle(
                color: isSuccess ? Colors.green : Colors.red,
                fontSize: 13,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserInfoCard() {
    final current = fb_auth.FirebaseAuth.instance.currentUser;
    if (current == null) return const SizedBox.shrink();

    return Card(
      color: Colors.green.withOpacity(0.1),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.account_circle, color: Colors.green, size: 24),
                const SizedBox(width: 12),
                const Text(
                  'Utilisateur connecté',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Email', current.email ?? 'Non défini'),
            const SizedBox(height: 8),
            _buildInfoRow('Nom d\'affichage', current.displayName ?? 'Non défini'),
            const SizedBox(height: 8),
            _buildInfoRow('UID', current.uid, isMonospace: true),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value, {bool isMonospace = false}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            '$label:',
            style: const TextStyle(
              fontWeight: FontWeight.w500,
              color: Colors.white70,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontFamily: isMonospace ? 'monospace' : null,
              fontSize: isMonospace ? 12 : 14,
              color: Colors.white,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool obscureText = false,
    bool? showPassword,
    VoidCallback? onTogglePassword,
    String? helperText,
    TextInputType? keyboardType,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscureText && (showPassword == null || !showPassword),
      keyboardType: keyboardType,
      decoration: InputDecoration(
        labelText: label,
        helperText: helperText,
        prefixIcon: Icon(icon, size: 20),
        suffixIcon: onTogglePassword != null
            ? IconButton(
                icon: Icon(
                  (showPassword ?? false) ? Icons.visibility : Icons.visibility_off,
                  size: 20,
                ),
                onPressed: onTogglePassword,
              )
            : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Colors.blue),
        ),
        filled: true,
        fillColor: Colors.black.withOpacity(0.1),
      ),
    );
  }

  Widget _buildCustomButton({
    required VoidCallback? onPressed,
    required String label,
    required IconData icon,
    bool isPrimary = false,
    Color? color,
  }) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: _loading ? null : onPressed,
        icon: _loading 
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : Icon(icon, size: 18),
        label: Text(
          _loading ? 'Chargement...' : label,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: isPrimary 
              ? Theme.of(context).primaryColor 
              : color ?? Colors.blue.withOpacity(0.1),
          foregroundColor: isPrimary ? Colors.white : Colors.blue,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
            side: isPrimary ? BorderSide.none : const BorderSide(color: Colors.blue),
          ),
        ),
      ),
    );
  }

  Widget _buildConnectionTab() {
    final current = fb_auth.FirebaseAuth.instance.currentUser;
    
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (current != null) ...[
            _buildUserInfoCard(),
            const SizedBox(height: 20),
            _buildCustomButton(
              onPressed: _signOut,
              label: 'Se déconnecter',
              icon: Icons.logout,
              color: Colors.red.withOpacity(0.1),
            ),
          ] else ...[
            const Text(
              'Connexion Firebase',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            _buildCustomTextField(
              controller: _emailCtrl,
              label: 'Adresse email',
              icon: Icons.email,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            _buildCustomTextField(
              controller: _passCtrl,
              label: 'Mot de passe',
              icon: Icons.lock,
              obscureText: true,
              showPassword: _showLoginPass,
              onTogglePassword: () => setState(() => _showLoginPass = !_showLoginPass),
            ),
            const SizedBox(height: 20),
            _buildCustomButton(
              onPressed: _saveAndSignIn,
              label: 'Se connecter',
              icon: Icons.login,
              isPrimary: true,
            ),
            const SizedBox(height: 12),
            _buildCustomButton(
              onPressed: _testRestSignIn,
              label: 'Se connecter (REST)',
              icon: Icons.api,
            ),
            const SizedBox(height: 20),
            const Divider(),
            const SizedBox(height: 20),
            const Text(
              'Créer un nouveau compte',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 16),
            _buildCustomTextField(
              controller: _passConfirmCtrl,
              label: 'Confirmer le mot de passe',
              icon: Icons.lock_outline,
              obscureText: true,
              showPassword: _showCreatePassConfirm,
              onTogglePassword: () => setState(() => _showCreatePassConfirm = !_showCreatePassConfirm),
              helperText: 'Pour créer un nouveau compte',
            ),
            const SizedBox(height: 16),
            _buildCustomButton(
              onPressed: _createAccount,
              label: 'Créer un compte',
              icon: Icons.person_add,
            ),
          ],
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildProfileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Gestion du profil',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          _buildCustomTextField(
            controller: _displayNameCtrl,
            label: 'Nom d\'affichage',
            icon: Icons.person,
            helperText: 'Votre nom public dans l\'application',
          ),
          const SizedBox(height: 16),
          _buildCustomButton(
            onPressed: _updateSelfDisplayName,
            label: 'Mettre à jour le nom',
            icon: Icons.save,
          ),
          const SizedBox(height: 30),
          const Text(
            'Changer le mot de passe',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 16),
          _buildCustomTextField(
            controller: _newPassCtrl,
            label: 'Nouveau mot de passe',
            icon: Icons.lock_reset,
            obscureText: true,
            showPassword: _showNewPass,
            onTogglePassword: () => setState(() => _showNewPass = !_showNewPass),
            helperText: 'Minimum 6 caractères',
          ),
          const SizedBox(height: 16),
          _buildCustomTextField(
            controller: _newPassConfirmCtrl,
            label: 'Confirmer le nouveau mot de passe',
            icon: Icons.lock_outline,
            obscureText: true,
            showPassword: _showNewPassConfirm,
            onTogglePassword: () => setState(() => _showNewPassConfirm = !_showNewPassConfirm),
          ),
          const SizedBox(height: 16),
          _buildCustomButton(
            onPressed: _changeSelfPassword,
            label: 'Changer le mot de passe',
            icon: Icons.security,
          ),
          const SizedBox(height: 30),
          const Divider(),
          const SizedBox(height: 16),
          _buildCustomButton(
            onPressed: _createAdminDoc,
            label: 'Créer le rôle administrateur',
            icon: Icons.admin_panel_settings,
            color: Colors.orange.withOpacity(0.1),
          ),
          _buildStatusIndicator(),
        ],
      ),
    );
  }

  Widget _buildDiagnosticsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Diagnostics de connexion',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.cloud, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Test de connectivité Cloud',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _testConnectivity,
                      icon: const Icon(Icons.network_check, size: 18),
                      label: const Text('Tester la connexion'),
                    ),
                  ),
                  if (_diagnostic.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        _diagnostic,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.api, size: 20),
                      SizedBox(width: 8),
                      Text(
                        'Test API REST',
                        style: TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _testConnectivityRest,
                      icon: const Icon(Icons.http, size: 18),
                      label: const Text('Tester l\'API REST'),
                    ),
                  ),
                  if (_diagnosticRest.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.black.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white24),
                      ),
                      child: Text(
                        _diagnosticRest,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 12,
                          color: Colors.white70,
                        ),
                        ),
                      ),
                    
                  ],
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          const Text(
            'Informations système',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoRow('Plateforme', kIsWeb ? 'Web' : Platform.operatingSystem),
                  const SizedBox(height: 8),
                  _buildInfoRow('Projet ID', DefaultFirebaseOptions.currentPlatform.projectId),
                  const SizedBox(height: 8),
                  _buildInfoRow('API Key', '${DefaultFirebaseOptions.currentPlatform.apiKey.substring(0, 12)}...'),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          decoration: BoxDecoration(
            color: Colors.black.withOpacity(0.1),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          ),
          child: TabBar(
            controller: _tabController,
            tabs: const [
              Tab(
                icon: Icon(Icons.login, size: 20),
                text: 'Connexion',
              ),
              Tab(
                icon: Icon(Icons.person, size: 20),
                text: 'Profil',
              ),
              Tab(
                icon: Icon(Icons.settings, size: 20),
                text: 'Diagnostics',
              ),
            ],
            labelColor: Colors.blue,
            unselectedLabelColor: Colors.white70,
            indicatorColor: Colors.blue,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
            unselectedLabelStyle: const TextStyle(fontSize: 12),
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              _buildConnectionTab(),
              _buildProfileTab(),
              _buildDiagnosticsTab(),
            ],
          ),
        ),
      ],
    );
  }
}
