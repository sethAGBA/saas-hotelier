/*
Small helper to set Firestore document `app_settings/update_info`.
Usage:
  - Set env var SERVICE_ACCOUNT_PATH to the path of your Firebase service account JSON, then run:
      node scripts/set_firestore_update_info.js
  - Or pass the service account path as the first arg:
      node scripts/set_firestore_update_info.js /path/to/serviceAccountKey.json

This script will upsert the document and merge fields.
Replace the macOS URL below before running.
*/

const admin = require('firebase-admin');

const keyPath = process.env.SERVICE_ACCOUNT_PATH || process.argv[2];
if (!keyPath) {
  console.error('Missing service account key path. Set SERVICE_ACCOUNT_PATH env or pass path as arg.');
  process.exit(1);
}

let serviceAccount;
try {
  serviceAccount = require(keyPath);
} catch (err) {
  console.error('Failed to load service account JSON:', err.message);
  process.exit(1);
}

admin.initializeApp({ credential: admin.credential.cert(serviceAccount) });
const db = admin.firestore();

const docRef = db.collection('app_settings').doc('update_info');

const payload = {
  latest_version: '1.0.4',
  download_urls: {
    android: 'https://drive.google.com/file/d/1TZXE3q9JcJZ4L3DXrpFw3Zyw9BpGKoNz/view?usp=sharing',
    macos: 'VOTRE_LIEN_GOOGLE_DRIVE_MACOS' // <-- replace with actual macOS link
  },
  publishedAt: admin.firestore.FieldValue.serverTimestamp()
};

(async () => {
  try {
    await docRef.set(payload, { merge: true });
    console.log('Successfully wrote update_info to Firestore (app_settings/update_info)');
    process.exit(0);
  } catch (err) {
    console.error('Error writing update_info:', err);
    process.exit(1);
  }
})();
