import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:afroforma/firebase_options.dart';

class FirebaseAdminApi {
  final String projectId;
  final String apiKey;
  final String region;

  FirebaseAdminApi({String region = 'us-central1'})
      : projectId = DefaultFirebaseOptions.currentPlatform.projectId,
        apiKey = DefaultFirebaseOptions.currentPlatform.apiKey,
        region = region;

  Future<String?> _getIdToken() async {
    try {
      final user = fb_auth.FirebaseAuth.instance.currentUser;
      if (user != null) {
        return await user.getIdToken(true);
      }
    } catch (_) {}

    // Fallback: sign-in via REST using saved credentials
    try {
      final sp = await SharedPreferences.getInstance();
      final email = sp.getString('firebase_email') ?? '';
      final pass = sp.getString('firebase_password') ?? '';
      if (email.isEmpty || pass.isEmpty) return null;
      final uri = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey');
      final resp = await http.post(
        uri,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email, 'password': pass, 'returnSecureToken': true}),
      );
      if (resp.statusCode != 200) return null;
      final body = jsonDecode(resp.body) as Map<String, dynamic>;
      return body['idToken'] as String?;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> _call(String name, Map<String, dynamic> data) async {
    final token = await _getIdToken();
    if (token == null) {
      throw Exception('Token introuvable. Connectez-vous à Firebase dans Paramètres.');
    }
    final url = Uri.parse('https://$region-$projectId.cloudfunctions.net/$name');
    final resp = await http.post(
      url,
      headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      },
      body: jsonEncode({'data': data}),
    );
    if (resp.statusCode != 200) {
      throw Exception('Callable $name: ${resp.statusCode} ${resp.body}');
    }
    final body = jsonDecode(resp.body) as Map<String, dynamic>;
    return (body['result'] as Map<String, dynamic>?) ?? body;
  }

  Future<String?> getUidByEmail(String email) async {
    final res = await _call('getUserByEmail', {'email': email});
    return res?['uid'] as String?;
  }

  Future<void> setUserPassword(String uid, String newPassword) async {
    await _call('setUserPassword', {'uid': uid, 'password': newPassword});
  }

  Future<void> setUserActive(String uid, bool active) async {
    await _call('setUserActive', {'uid': uid, 'active': active});
  }

  Future<void> setUserRole(String uid, String role, List<Map<String, dynamic>> permissions) async {
    await _call('setUserRole', {'uid': uid, 'role': role, 'permissions': permissions});
  }

  Future<void> setUserProfile(String uid, {String? displayName, String? email}) async {
    final data = <String, dynamic>{'uid': uid};
    if (displayName != null) data['displayName'] = displayName;
    if (email != null) data['email'] = email;
    await _call('setUserProfile', data);
  }

  // Self updates via REST (no admin needed)
  Future<void> updateSelfProfile({String? displayName}) async {
    final token = await _getIdToken();
    if (token == null) throw Exception('Non connecté à Firebase');
    final uri = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:update?key=$apiKey');
    final payload = <String, dynamic>{'idToken': token, 'returnSecureToken': true};
    if (displayName != null) payload['displayName'] = displayName;
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(payload),
    );
    if (resp.statusCode != 200) {
      throw Exception('updateSelfProfile error ${resp.statusCode}: ${resp.body}');
    }
  }

  Future<void> updateSelfPassword(String newPassword) async {
    final token = await _getIdToken();
    if (token == null) throw Exception('Non connecté à Firebase');
    final uri = Uri.parse('https://identitytoolkit.googleapis.com/v1/accounts:update?key=$apiKey');
    final resp = await http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'idToken': token, 'password': newPassword, 'returnSecureToken': true}),
    );
    if (resp.statusCode != 200) {
      throw Exception('updateSelfPassword error ${resp.statusCode}: ${resp.body}');
    }
  }

  Future<String?> createUser({
    required String email,
    required String password,
    String? displayName,
    bool active = true,
    String role = 'secretaire',
    List<Map<String, dynamic>> permissions = const [],
  }) async {
    final res = await _call('createUser', {
      'email': email,
      'password': password,
      'displayName': displayName,
      'active': active,
      'role': role,
      'permissions': permissions,
    });
    return res?['uid'] as String?;
  }
}
