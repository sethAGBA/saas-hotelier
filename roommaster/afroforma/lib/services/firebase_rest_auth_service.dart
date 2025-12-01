import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:afroforma/firebase_options.dart';
import 'package:afroforma/models/user.dart' as local_models;
import 'package:afroforma/services/database_service.dart';

class FirebaseRestAuthService {
  final String apiKey;
  final String projectId;

  FirebaseRestAuthService({String? apiKey, String? projectId})
      : apiKey = apiKey ?? DefaultFirebaseOptions.currentPlatform.apiKey,
        projectId = projectId ?? DefaultFirebaseOptions.currentPlatform.projectId;

  /// Effectue un sign-in email/mot de passe via l'API REST Identity Toolkit
  /// et retourne un `local_models.User` si l'utilisateur est administrateur (doc présent dans `administrateurs/{uid}`).
  Future<local_models.User> signInAndFetchAdmin(String email, String password) async {
    final signIn = await _signInWithPassword(email, password);
    final idToken = signIn['idToken'] as String?;
    final uid = signIn['localId'] as String?;
    final fbEmail = signIn['email'] as String? ?? email;
    if (idToken == null || uid == null) {
      throw Exception('Réponse d\'authentification invalide.');
    }

    final admin = await _getAdminDocViaFunction(uid, idToken, email: fbEmail);
    if (admin == null) {
      // Pas admin: retourner un utilisateur local générique (rôle par défaut)
      return _toDefaultLocalUser(uid: uid, email: fbEmail);
    }

    return _toLocalUser(uid, admin);
  }

  Future<Map<String, dynamic>> _signInWithPassword(String email, String password) async {
    final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'email': email,
        'password': password,
        'returnSecureToken': true,
      }),
    );
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    if (resp.statusCode != 200) {
      final msg = data['error']?['message'] ?? 'Auth error';
      throw Exception('Firebase REST auth failed: $msg');
    }
    return data;
  }

  /// Récupère le document administrateur via l'API REST Firestore.
  /// Retourne un `Map` simplifié ou null si non trouvé/inactif.
  Future<Map<String, dynamic>?> _getAdminDocViaFunction(String uid, String idToken, {required String email}) async {
    final region = 'us-central1';
    final url = Uri.parse('https://$region-$projectId.cloudfunctions.net/getSelfAdmin');
    final resp = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $idToken',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'data': {}}),
    );
    if (resp.statusCode != 200) {
      // If function not deployed, try direct Firestore REST as fallback
      final fs = await _tryGetAdminDocFromFirestore(uid, idToken, email: email);
      if (fs != null) return fs;
      // Last resort: check custom claims on the account (requires that claims are set server-side)
      final isAdmin = await _hasAdminCustomClaim(idToken);
      if (isAdmin) {
        return {
          'name': email.split('@').first,
          'email': email,
          'isActive': true,
          'permissions': const [],
        };
      }
      return null;
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final result = body['result'] ?? body; // callable may wrap result
    final exists = (result['exists'] as bool?) ?? false;
    if (!exists) return null;
    final data = (result['data'] as Map<String, dynamic>?) ?? const {};
    final isActive = (data['isActive'] as bool?) ?? true;
    if (!isActive) return null;
    return {
      'name': (data['name'] as String?) ?? (data['displayName'] as String?) ?? 'Admin',
      'email': (data['email'] as String?) ?? email,
      'isActive': isActive,
      'permissions': (data['permissions'] as List?) ?? const [],
    };
  }

  Future<Map<String, dynamic>?> _tryGetAdminDocFromFirestore(String uid, String idToken, {required String email}) async {
    final url = Uri.parse('https://firestore.googleapis.com/v1/projects/$projectId/databases/(default)/documents/administrateurs/$uid');
    final resp = await http.get(url, headers: {
      'Authorization': 'Bearer $idToken',
    });
    if (resp.statusCode != 200) return null;
    final data = jsonDecode(resp.body) as Map<String, dynamic>;
    final fields = (data['fields'] as Map<String, dynamic>?);
    if (fields == null) return null;
    final isActive = _boolField(fields['isActive'], defaultValue: true);
    if (!isActive) return null;
    final name = _stringField(fields['name']) ?? _stringField(fields['displayName']) ?? (email.split('@').first);
    final permissions = _permissionsField(fields['permissions']);
    return {
      'name': name,
      'email': _stringField(fields['email']) ?? email,
      'isActive': isActive,
      'permissions': permissions,
    };
  }

  Future<bool> _hasAdminCustomClaim(String idToken) async {
    final url = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:lookup?key=$apiKey');
    final resp = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': idToken}),
    );
    if (resp.statusCode != 200) return false;
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    final users = (body['users'] as List?) ?? const [];
    if (users.isEmpty) return false;
    final user = users.first as Map<String, dynamic>;
    final customAttrs = user['customAttributes'] as String?;
    if (customAttrs == null || customAttrs.isEmpty) return false;
    try {
      final claims = jsonDecode(customAttrs) as Map<String, dynamic>;
      return (claims['admin'] == true);
    } catch (_) {
      return false;
    }
  }

  String? _stringField(dynamic field) {
    if (field is Map && field['stringValue'] is String) return field['stringValue'] as String;
    return null;
  }

  bool _boolField(dynamic field, {bool defaultValue = false}) {
    if (field is Map) {
      if (field['booleanValue'] is bool) return field['booleanValue'] as bool;
      if (field['stringValue'] is String) return (field['stringValue'] as String).toLowerCase() == 'true';
      if (field['integerValue'] is String) return (field['integerValue'] as String) != '0';
    }
    return defaultValue;
  }

  List<Map<String, dynamic>> _permissionsField(dynamic field) {
    final List<Map<String, dynamic>> result = [];
    if (field is Map && field['arrayValue'] is Map) {
      final values = (field['arrayValue']['values'] as List?) ?? const [];
      for (final v in values) {
        if (v is Map && v['mapValue'] is Map) {
          final mf = v['mapValue']['fields'] as Map<String, dynamic>?;
          if (mf == null) continue;
          final module = _stringField(mf['module']) ?? '';
          final actions = <String>[];
          final actField = mf['actions'];
          if (actField is Map && actField['arrayValue'] is Map) {
            final av = (actField['arrayValue']['values'] as List?) ?? const [];
            for (final a in av) {
              if (a is Map && a['stringValue'] is String) actions.add(a['stringValue'] as String);
            }
          }
          result.add({'module': module, 'actions': actions});
        }
      }
    }
    return result;
  }

  local_models.User _toLocalUser(String uid, Map<String, dynamic> data) {
    final name = (data['name'] as String?) ?? 'Admin';
    final email = (data['email'] as String?) ?? '';
    final permsRaw = (data['permissions'] as List?) ?? const [];
    final perms = permsRaw
        .whereType<Map<String, dynamic>>()
        .map((m) => local_models.Permission(
              module: (m['module'] as String?) ?? '',
              actions: ((m['actions'] as List?) ?? const <String>[]).whereType<String>().toList(),
            ))
        .toList();

    return local_models.User(
      id: uid,
      name: name,
      email: email,
      role: local_models.UserRole.admin,
      passwordHash: null,
      permissions: perms,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      isActive: true,
      mustChangePassword: false,
      is2faEnabled: false,
      twoFaSecret: null,
    );
  }

  local_models.User _toDefaultLocalUser({required String uid, required String email}) {
    final name = email.contains('@') ? email.split('@').first : email;
    return local_models.User(
      id: uid,
      name: name.isEmpty ? 'Utilisateur' : name,
      email: email,
      role: local_models.UserRole.secretaire,
      passwordHash: null,
      permissions: const [],
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      isActive: true,
      mustChangePassword: false,
      is2faEnabled: false,
      twoFaSecret: null,
    );
  }

  Future<void> upsertLocalUser(local_models.User user) async {
    await DatabaseService().insertUser(user);
  }
}
