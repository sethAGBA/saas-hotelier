const functions = require('firebase-functions');
const admin = require('firebase-admin');
const {Storage} = require('@google-cloud/storage');

admin.initializeApp();
const storage = new Storage();
const BUCKET = process.env.FUNCTIONS_BUCKET || 'k-empire-68e8c.appspot.com';

exports.getSignedUploadUrl = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be signed in');
  }

  // Optional: check admin status in Firestore
  // const adminDoc = await admin.firestore().doc(`administrateurs/${context.auth.uid}`).get();
  // if (!adminDoc.exists) throw new functions.https.HttpsError('permission-denied', 'Admin only');

  const destPath = data.path;
  const contentType = data.contentType || 'application/octet-stream';
  if (!destPath || destPath.trim().isEmpty) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing path');
  }

  const options = {
    version: 'v4',
    action: 'write',
    expires: Date.now() + 15 * 60 * 1000, // 15 minutes
    contentType,
  };

  const [url] = await storage.bucket(BUCKET).file(destPath).getSignedUrl(options);
  return {url};
});
