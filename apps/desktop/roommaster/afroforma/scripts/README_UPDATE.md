Populate Firestore `app_settings/update_info` document

1) Create / obtain a Firebase service account JSON for a project that has the same Firestore you want to update.
2) Save it somewhere on your machine, e.g. `~/keys/my-firebase-sa.json`.
3) Edit `scripts/set_firestore_update_info.js` if you want to change the macOS link.

Run (zsh):

```zsh
# export env var and run
export SERVICE_ACCOUNT_PATH=~/keys/my-firebase-sa.json
node scripts/set_firestore_update_info.js

# or pass path as arg
node scripts/set_firestore_update_info.js ~/keys/my-firebase-sa.json
```

The script will upsert `app_settings/update_info` with fields:
- latest_version: string
- download_urls: { android: string, macos: string }
- publishedAt: serverTimestamp()

After running, the Flutter app's update-checker will be able to read the Android / macOS URLs.
