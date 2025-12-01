import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth;
import 'package:afroforma/models/user.dart' as local_models;
import 'package:afroforma/services/database_service.dart';

/// Service d'intégration Firebase pour les administrateurs.
///
/// Cette couche lit la collection Firestore `administrateurs` pour vérifier
/// qu'un utilisateur authentifié est bien un administrateur actif, puis
/// synchronise/convertit ces informations vers le modèle local `User` utilisé
/// par l'application (SQLite + AuthService).
class FirebaseAdminService {
  FirebaseAdminService();

  CollectionReference<Map<String, dynamic>> get _adminsCol =>
      FirebaseFirestore.instance.collection('administrateurs');

  /// Récupère l'utilisateur Firebase courant, vérifie sa présence dans
  /// `administrateurs/{uid}` et renvoie un `local_models.User` prêt à être
  /// utilisé par l'app (ou null si non autorisé/inactif).
  Future<local_models.User?> fetchCurrentAdminAsLocalUser() async {
    final fbUser = fb_auth.FirebaseAuth.instance.currentUser;
    if (fbUser == null) return null;

    // Lecture du document administrateur basé sur le UID
    final doc = await _adminsCol.doc(fbUser.uid).get();
    if (!doc.exists) {
      // Par sécurité, tenter une recherche par email si nécessaire
      final email = fbUser.email;
      if (email == null || email.isEmpty) return null;
      final byEmail = await _adminsCol.where('email', isEqualTo: email).limit(1).get();
      if (byEmail.docs.isEmpty) return null;
      return _toLocalUser(fbUser.uid, byEmail.docs.first.data());
    }
    return _toLocalUser(fbUser.uid, doc.data()!);
  }

  /// Convertit les données Firestore vers notre modèle local User.
  local_models.User? _toLocalUser(String uid, Map<String, dynamic> data) {
    final isActive = (data['isActive'] as bool?) ?? true;
    if (!isActive) return null;

    final name = (data['name'] as String?) ?? (data['displayName'] as String?) ?? 'Admin';
    final email = (data['email'] as String?) ?? '';

    // Permissions optionnelles: liste d'objets {module: string, actions: [string]}
    final List<local_models.Permission> perms;
    final rawPerms = data['permissions'];
    if (rawPerms is List) {
      perms = rawPerms
          .whereType<Map<String, dynamic>>()
          .map((m) => local_models.Permission(
                module: (m['module'] as String?) ?? '',
                actions: (m['actions'] is List)
                    ? (m['actions'] as List).whereType<String>().toList()
                    : const <String>[],
              ))
          .toList();
    } else {
      perms = const <local_models.Permission>[];
    }

    return local_models.User(
      id: uid,
      name: name,
      email: email,
      role: local_models.UserRole.admin,
      passwordHash: null, // Géré par Firebase Auth, pas localement
      permissions: perms,
      createdAt: DateTime.now(),
      lastLogin: DateTime.now(),
      isActive: true,
      mustChangePassword: false,
      is2faEnabled: false,
      twoFaSecret: null,
    );
  }

  /// Assure une présence du compte admin dans la base locale pour l'audit, etc.
  Future<void> upsertLocalUser(local_models.User user) async {
    final db = DatabaseService();
    // Simple upsert via insert avec REPLACE (voir DatabaseService.insertUser)
    await db.insertUser(user);
  }
}

