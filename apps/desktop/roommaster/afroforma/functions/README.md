This folder contains a Cloud Function `getSignedUploadUrl` that returns a V4 signed URL
for uploading a file directly to Cloud Storage. Deploy with:

```bash
cd functions
npm install
firebase deploy --only functions:getSignedUploadUrl --project k-empire-68e8c
```

The function is a callable function and expects `path` and optional `contentType`.
Firebase Functions for Afroforma

Files:
- `src/index.ts` - callable functions: `promoteToAdmin`, `demoteAdmin`.

Setup:
1. Install dependencies: `npm install` inside `functions/`.
2. Build: `npm run build` (generates `lib/`).
3. Use the Firebase Emulator for safe testing: `npm run serve`.
4. Deploy: `npm run deploy` (requires `firebase` CLI auth and project selection).

Usage (from client):
- Call callable function from Flutter using `HttpsCallable`:
  - `promoteToAdmin` with `{ uid, name?, email? }`
  - `demoteAdmin` with `{ uid }`

Security:
- These functions check that the caller is already an admin (presence in `/administrateurs/{callerUid}`).
- Keep service account and Firebase CLI credentials secure.
