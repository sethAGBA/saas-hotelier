// Usage: node create_admin.js <TARGET_UID> [NAME] [EMAIL]
// Requires a Firebase service account JSON file available as
// - ./serviceAccountKey.json or
// - set GOOGLE_APPLICATION_CREDENTIALS to the path

const admin = require('firebase-admin');
const path = require('path');

const targetUid = process.argv[2];
const name = process.argv[3] || null;
const email = process.argv[4] || null;

if (!targetUid) {
  console.error('Usage: node create_admin.js <TARGET_UID> [NAME] [EMAIL]');
  process.exit(1);
}

const keyPath = process.env.GOOGLE_APPLICATION_CREDENTIALS || path.join(__dirname, 'serviceAccountKey.json');

try {
  const serviceAccount = require(keyPath);
  admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
} catch (e) {
  console.error('Failed to load service account key from', keyPath, e);
  process.exit(2);
}

const db = admin.firestore();

(async () => {
  try {
    await db.collection('administrateurs').doc(targetUid).set({
      name: name,
      email: email,
      isActive: true,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
    });
    console.log('Administrateur créé pour uid:', targetUid);
  } catch (err) {
    console.error('Error creating administrateur:', err);
    process.exit(3);
  }
})();
