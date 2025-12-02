Temporary Storage rules for testing

1) This `storage.rules` file is intentionally permissive (allow read, write: if true) and should only be used for local development/testing.
2) To deploy these rules to your Firebase project `k-empire-68e8c`, run:

```bash
firebase deploy --only storage --project k-empire-68e8c
```

3) After testing, revert to proper production rules (require authentication and App Check when applicable).

Example production snippet (replace with your auth logic):

service firebase.storage {
  match /b/{bucket}/o {
    match /{allPaths=**} {
      allow read, write: if request.auth != null;
    }
  }
}


# unauthenticated test (should return 401 if bucket protected, but must not be 404 if bucket exists)
curl -i -X POST \
  -H "Content-Type: application/octet-stream" \
  --data-binary @/path/to/small-file.pdf \
  "https://firebasestorage.googleapis.com/v0/b/k-empire-68e8c.appspot.com/o?uploadType=media&name=test-file.pdf"

# authenticated test (replace <ID_TOKEN> with Firebase user idToken)
curl -i -X POST \
  -H "Authorization: Bearer <ID_TOKEN>" \
  -H "Content-Type: application/octet-stream" \
  --data-binary @/path/to/small-file.pdf \
  "https://firebasestorage.googleapis.com/v0/b/k-empire-68e8c.appspot.com/o?uploadType=media&name=test-file.pdf"