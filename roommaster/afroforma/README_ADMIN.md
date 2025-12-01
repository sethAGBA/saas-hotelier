Initialiser un administrateur (méthodes)

- La collection utilisée par l'app est `administrateurs` (cf. `firestore.rules`).
- Un utilisateur Firebase est considéré comme admin si un document existe à `administrateurs/{uid}` avec `isActive=true`.

Options pour créer le premier admin:

1) Depuis l'app (Paramètres → Firebase):
   - Se connecter avec un compte Firebase.
   - Cliquer « Créer mon rôle administrateur » pour créer `administrateurs/{uid}`.

2) Via service account (script Node):
   - Obtenir un JSON service account depuis la console Firebase.
   - Sauvegarder `serviceAccountKey.json` ou définir `GOOGLE_APPLICATION_CREDENTIALS`.
   - Exécuter:

```bash
node scripts/create_admin.js <TARGET_UID> "Admin Name" admin@example.com
```

Le script écrit désormais dans `/administrateurs/<TARGET_UID>` en cohérence avec l'application et les règles.

Une fois au moins un admin créé, vous pouvez gérer les admins côté Firestore en éditant les documents (name, email, permissions, isActive).
