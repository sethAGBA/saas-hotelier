"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.setUserProfile = exports.setUserRole = exports.setUserActive = exports.setUserPassword = exports.getSelfAdmin = exports.bootstrapSelfAdmin = exports.demoteAdmin = exports.promoteToAdmin = exports.getUserByEmail = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();
// Existing helper function to check if a user is an admin
async function callerIsAdmin(uid) {
    if (!uid)
        return false;
    const doc = await db.collection('administrateurs').doc(uid).get();
    return doc.exists;
}
// New callable function to get user UID by email
exports.getUserByEmail = functions.https.onCall(async (data, context) => {
    // Check authentication
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Seuls les utilisateurs authentifiés peuvent appeler cette fonction.');
    }
    // Check if caller is admin
    if (!(await callerIsAdmin(context.auth.uid))) { // Use existing callerIsAdmin
        throw new functions.https.HttpsError('permission-denied', 'Seuls les administrateurs peuvent rechercher des utilisateurs par email.');
    }
    // Validate input
    const email = data.email;
    if (!email || typeof email !== 'string') {
        throw new functions.https.HttpsError('invalid-argument', 'L\'email est requis et doit être une chaîne de caractères.');
    }
    try {
        const userRecord = await admin.auth().getUserByEmail(email);
        return {
            uid: userRecord.uid,
            name: userRecord.displayName || userRecord.email, // Return display name or email as name
            email: userRecord.email,
        };
    }
    catch (error) {
        if (error.code === 'auth/user-not-found') {
            throw new functions.https.HttpsError('not-found', 'Aucun utilisateur trouvé pour cet email.');
        }
        else {
            throw new functions.https.HttpsError('internal', 'Erreur lors de la récupération de l\'utilisateur: ' + error.message);
        }
    }
});
// Existing promoteToAdmin function, updated to set custom claims
exports.promoteToAdmin = functions.https.onCall(async (data, context) => {
    const callerUid = context.auth?.uid;
    if (!callerUid || !(await callerIsAdmin(callerUid))) {
        throw new functions.https.HttpsError('permission-denied', 'Only admins can promote new admins');
    }
    const targetUid = data?.uid;
    if (!targetUid) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing target uid');
    }
    try {
        // Set custom claim for admin role
        await admin.auth().setCustomUserClaims(targetUid, { admin: true });
        const payload = {
            name: data?.name || null,
            email: data?.email || null,
            createdBy: callerUid,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
        };
        await db.collection('administrateurs').doc(targetUid).set(payload);
        return { ok: true, message: `User ${targetUid} promoted to admin.` };
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', 'Erreur lors de la promotion de l\'utilisateur: ' + error.message);
    }
});
// Existing demoteAdmin function, updated to remove custom claims
exports.demoteAdmin = functions.https.onCall(async (data, context) => {
    const callerUid = context.auth?.uid;
    if (!callerUid || !(await callerIsAdmin(callerUid))) {
        throw new functions.https.HttpsError('permission-denied', 'Only admins can demote admins');
    }
    const targetUid = data?.uid;
    if (!targetUid) {
        throw new functions.https.HttpsError('invalid-argument', 'Missing target uid');
    }
    // Prevent an admin from demoting themselves
    if (targetUid === callerUid) {
        throw new functions.https.HttpsError('permission-denied', 'Un administrateur ne peut pas se rétrograder lui-même.');
    }
    try {
        // Remove custom claim for admin role
        await admin.auth().setCustomUserClaims(targetUid, { admin: false });
        await db.collection('administrateurs').doc(targetUid).delete();
        return { ok: true, message: `User ${targetUid} demoted from admin.` };
    }
    catch (error) {
        throw new functions.https.HttpsError('internal', 'Erreur lors de la rétrogradation de l\'utilisateur: ' + error.message);
    }
});
// Bootstrap self-admin: allow an authenticated user to create their own admin doc
// if it does not exist yet. Useful for first admin creation on desktop clients.
exports.bootstrapSelfAdmin = functions.https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    }
    const email = data?.email || context.auth?.token?.email || '';
    const name = data?.name || email || 'Admin';
    const ref = db.collection('administrateurs').doc(uid);
    const snap = await ref.get();
    if (snap.exists) {
        return { ok: true, already: true };
    }
    await ref.set({
        email,
        name,
        isActive: true,
        createdBy: uid,
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        permissions: [],
    });
    return { ok: true, created: true };
});
// Return the caller's admin document if it exists.
exports.getSelfAdmin = functions.https.onCall(async (data, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
        throw new functions.https.HttpsError('unauthenticated', 'Authentication required');
    }
    const snap = await db.collection('administrateurs').doc(uid).get();
    if (!snap.exists) {
        return { exists: false };
    }
    return { exists: true, data: snap.data() };
});
// Admin-only: set another user's password
exports.setUserPassword = functions.https.onCall(async (data, context) => {
    const callerUid = context.auth?.uid;
    if (!callerUid || !(await callerIsAdmin(callerUid))) {
        throw new functions.https.HttpsError('permission-denied', 'Admin only');
    }
    const targetUid = data?.uid;
    const password = data?.password;
    if (!targetUid || !password) {
        throw new functions.https.HttpsError('invalid-argument', 'uid and password required');
    }
    await admin.auth().updateUser(targetUid, { password });
    return { ok: true };
});
// Admin-only: activate/deactivate a user (Firebase Auth disabled flag). Also mirror to Firestore.
exports.setUserActive = functions.https.onCall(async (data, context) => {
    const callerUid = context.auth?.uid;
    if (!callerUid || !(await callerIsAdmin(callerUid))) {
        throw new functions.https.HttpsError('permission-denied', 'Admin only');
    }
    const targetUid = data?.uid;
    const active = data?.active;
    if (!targetUid || active === undefined) {
        throw new functions.https.HttpsError('invalid-argument', 'uid and active required');
    }
    await admin.auth().updateUser(targetUid, { disabled: !active });
    // Mirror to administrateurs if exists
    const adminRef = db.collection('administrateurs').doc(targetUid);
    const snap = await adminRef.get();
    if (snap.exists) {
        await adminRef.set({ isActive: active }, { merge: true });
    }
    // Mirror to users collection
    await db.collection('users').doc(targetUid).set({ isActive: active }, { merge: true });
    return { ok: true };
});
// Admin-only: set role and permissions. If role == 'admin', ensure administrateurs doc exists; otherwise remove it.
exports.setUserRole = functions.https.onCall(async (data, context) => {
    const callerUid = context.auth?.uid;
    if (!callerUid || !(await callerIsAdmin(callerUid))) {
        throw new functions.https.HttpsError('permission-denied', 'Admin only');
    }
    const targetUid = data?.uid;
    const role = data?.role?.toLowerCase();
    const permissions = data?.permissions ?? [];
    if (!targetUid || !role) {
        throw new functions.https.HttpsError('invalid-argument', 'uid and role required');
    }
    if (role === 'admin') {
        await db.collection('administrateurs').doc(targetUid).set({
            isActive: true,
            updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        }, { merge: true });
        await admin.auth().setCustomUserClaims(targetUid, { admin: true });
    }
    else {
        // Remove admin doc and claim
        await db.collection('administrateurs').doc(targetUid).delete().catch(() => { });
        await admin.auth().setCustomUserClaims(targetUid, { admin: false });
    }
    // Mirror role/permissions to users collection
    await db.collection('users').doc(targetUid).set({
        role,
        permissions,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });
    return { ok: true };
});
// Admin-only: set user profile fields (displayName, email)
exports.setUserProfile = functions.https.onCall(async (data, context) => {
    const callerUid = context.auth?.uid;
    if (!callerUid || !(await callerIsAdmin(callerUid))) {
        throw new functions.https.HttpsError('permission-denied', 'Admin only');
    }
    const targetUid = data?.uid;
    const displayName = data?.displayName;
    const email = data?.email;
    if (!targetUid) {
        throw new functions.https.HttpsError('invalid-argument', 'uid required');
    }
    const updates = {};
    if (displayName !== undefined)
        updates.displayName = displayName;
    if (email !== undefined && email.length > 0)
        updates.email = email;
    await admin.auth().updateUser(targetUid, updates);
    // Mirror minimal info to users collection
    const patch = {};
    if (displayName !== undefined)
        patch.name = displayName;
    if (email !== undefined)
        patch.email = email;
    if (Object.keys(patch).length > 0) {
        await db.collection('users').doc(targetUid).set(patch, { merge: true });
    }
    return { ok: true };
});
//# sourceMappingURL=index.js.map