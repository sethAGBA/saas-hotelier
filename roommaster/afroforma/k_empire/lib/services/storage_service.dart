import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String _sanitizeFileName(String name) {
    var n = name.replaceAll(RegExp(r"\s+"), "_");
    n = n.replaceAll(RegExp(r"[\\/]+"), "_");
    n = n.replaceAll(RegExp(r"[^A-Za-z0-9._-]"), "");
    if (n.isEmpty) n = "file";
    return n;
  }

  String _sanitizePath(String path) {
    if (path.isEmpty) return path;
    final parts = path.split('/');
    if (parts.isEmpty) return path;
    final fileName = parts.removeLast();
    final safe = _sanitizeFileName(fileName);
    return [...parts, safe].join('/');
  }

  Future<String> uploadFile(String path, File file) async {
    final safePath = _sanitizePath(path);
    final ref = _storage.ref().child(safePath);
    try {
      final bucketFromOptions = Firebase.app().options.storageBucket;
      // ignore: avoid_print
      print('[Storage] Uploading to bucket: ref.bucket=${ref.bucket}; app.options=$bucketFromOptions; path=${ref.fullPath}');
    } catch (_) {}

    // Attach simple metadata (content type guessed from extension)
    final contentType = _guessContentType(file.path);
    final metadata = SettableMetadata(contentType: contentType);

    // Basic retry loop for transient network errors
    const int maxAttempts = 3;
    for (int attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        // Debug: print app options
        try {
          final opts = Firebase.app().options;
          // ignore: avoid_print
          print('[StorageDebug] projectId=${opts.projectId}; storageBucket=${opts.storageBucket}');
        } catch (_) {
          // ignore: avoid_print
          print('[StorageDebug] Firebase app options not available');
        }

        // Debug: print current auth state and whether user is listed as admin
        try {
          final user = FirebaseAuth.instance.currentUser;
          // ignore: avoid_print
          print('[StorageDebug] currentUser=${user?.uid} (email=${user?.email})');
          if (user != null) {
            final adminDoc = await FirebaseFirestore.instance.doc('admins/${user.uid}').get();
            // ignore: avoid_print
            print('[StorageDebug] admin doc exists=${adminDoc.exists} for uid=${user.uid}');
          }
        } catch (dbgErr) {
          // ignore: avoid_print
          print('[StorageDebug] could not read auth/firestore state: $dbgErr');
        }

        final uploadTask = ref.putFile(file, metadata);
        final snapshot = await uploadTask.whenComplete(() => null);
        final url = await snapshot.ref.getDownloadURL();
        // ignore: avoid_print
        print('[Storage] Upload succeeded: $url');
        return url;
      } on FirebaseException catch (e) {
  // ignore: avoid_print
  print('[Storage] attempt=$attempt FirebaseException code=${e.code} message=${e.message}');
  // Print full exception and stacktrace to help diagnose network/server response
  // ignore: avoid_print
  print('[Storage] full exception: $e');
  // ignore: avoid_print
  print('[Storage] stackTrace: ${e.stackTrace}');
        if (e.code == 'object-not-found' || e.code == 'unauthenticated') {
          // Try fallback non-resumable upload once before giving up
          if (attempt == 1) {
            try {
              final bytes = await file.readAsBytes();
              // ignore: avoid_print
              print('[Storage] trying putData fallback (non-resumable)');
              final snapshot = await ref.putData(bytes, metadata).whenComplete(() => null);
              final url = await snapshot.ref.getDownloadURL();
              // ignore: avoid_print
              print('[Storage] putData fallback succeeded: $url');
              return url;
            } catch (fallbackErr) {
              // ignore: avoid_print
              print('[Storage] putData fallback failed: $fallbackErr');
              // Try REST fallback as last resort
              try {
                // ignore: avoid_print
                print('[Storage] trying REST fallback upload');
                final restUrl = await _uploadFileViaRest(safePath, file, contentType: contentType);
                // ignore: avoid_print
                print('[Storage] REST fallback succeeded: $restUrl');
                return restUrl;
              } catch (restErr) {
                // ignore: avoid_print
                print('[Storage] REST fallback failed: $restErr');
              }
            }
          }
          if (attempt == maxAttempts) rethrow;
        }
        // small delay between retries
        await Future.delayed(Duration(seconds: 1 * attempt));
      } catch (e) {
        // ignore: avoid_print
        print('[Storage] unexpected error on attempt=$attempt: $e');
        if (attempt == maxAttempts) rethrow;
        await Future.delayed(Duration(seconds: 1 * attempt));
      }
    }
    throw Exception('Upload failed after $maxAttempts attempts');
  }

  /// Start an upload and return the [UploadTask] so callers can listen to
  /// progress events and control the upload (cancel, pause, resume).
  UploadTask startUpload(String path, File file) {
    final safePath = _sanitizePath(path);
    final ref = _storage.ref().child(safePath);
    try {
      final bucketFromOptions = Firebase.app().options.storageBucket;
      // ignore: avoid_print
      print('[Storage] Start upload: ref.bucket=${ref.bucket}; app.options=$bucketFromOptions; path=${ref.fullPath}');
    } catch (_) {}
    final metadata = SettableMetadata(contentType: _guessContentType(file.path));
    return ref.putFile(file, metadata);
  }

  /// Upload raw bytes to a path (used for debug/test uploads)
  UploadTask startUploadBytes(String path, Uint8List data, {String? contentType}) {
    final safePath = _sanitizePath(path);
    final ref = _storage.ref().child(safePath);
    try {
      final bucketFromOptions = Firebase.app().options.storageBucket;
      // ignore: avoid_print
      print('[Storage] Start upload (bytes): ref.bucket=${ref.bucket}; app.options=$bucketFromOptions; path=${ref.fullPath}');
    } catch (_) {}
    final meta = contentType != null ? SettableMetadata(contentType: contentType) : null;
    return ref.putData(data, meta);
  }

  String? _guessContentType(String path) {
    final ext = path.split('.').last.toLowerCase();
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'pdf':
        return 'application/pdf';
      case 'doc':
        return 'application/msword';
      case 'docx':
        return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
      default:
        return null;
    }
  }

  /// Fallback: upload file using Firebase Storage REST API (non-resumable)
  /// This requires a valid Firebase ID token for authentication.
  Future<String> _uploadFileViaRest(String path, File file, {String? contentType}) async {
    // Build upload URL for simple upload
    // POST https://firebasestorage.googleapis.com/v0/b/<bucket>/o?uploadType=media&name=<path>
    final opts = Firebase.app().options;
    final bucket = opts.storageBucket ?? (await Firebase.app().options.storageBucket);
    if (bucket == null || bucket.isEmpty) throw Exception('No storage bucket configured');

    final uploadUrl = Uri.parse('https://firebasestorage.googleapis.com/v0/b/$bucket/o?uploadType=media&name=${Uri.encodeComponent(path)}');

    final bytes = await file.readAsBytes();

    // Get ID token for authenticated user
    final user = FirebaseAuth.instance.currentUser;
    String? idToken;
    if (user != null) {
      idToken = await user.getIdToken();
    }

    final headers = <String, String>{
      'Content-Type': contentType ?? 'application/octet-stream',
    };
    if (idToken != null) headers['Authorization'] = 'Bearer ${idToken}';

    var resp = await http.post(uploadUrl, body: bytes, headers: headers);
    // If we get a 401/404, try sending the idToken as an access_token query param
    if ((resp.statusCode == 401 || resp.statusCode == 404) && idToken != null) {
      final uploadUrlWithToken = uploadUrl.replace(query: '${uploadUrl.query}&access_token=${Uri.encodeComponent(idToken)}');
      // ignore: avoid_print
      print('[Storage] REST retry with access_token param');
      resp = await http.post(uploadUrlWithToken, body: bytes, headers: headers);
    }

    if (resp.statusCode != 200) {
      throw Exception('REST upload failed: ${resp.statusCode} ${resp.reasonPhrase} ${resp.body}');
    }

    // Parse response to get download token or media link
    final Map<String, dynamic> parsed = resp.body.isNotEmpty ? jsonDecode(resp.body) as Map<String, dynamic> : {};
    // If name present, construct download URL
    if (parsed.containsKey('name')) {
      // Public URL (requires token param if not public)
      final mediaUrl = 'https://firebasestorage.googleapis.com/v0/b/$bucket/o/${Uri.encodeComponent(parsed['name'])}?alt=media';
      return mediaUrl;
    }
    throw Exception('Unexpected REST upload response: ${resp.body}');
  }
}
