import 'dart:io';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:http/http.dart' as http;

class SignedUploadService {
  final HttpsCallable _callable = FirebaseFunctions.instance.httpsCallable('getSignedUploadUrl');

  /// Returns the public media URL on success (alt=media)
  Future<String> uploadFile(String destPath, File file, {String? contentType}) async {
    final res = await _callable.call({'path': destPath, 'contentType': contentType});
    final signedUrl = (res.data as Map)['url'] as String;

    final bytes = await file.readAsBytes();
    final putResp = await http.put(Uri.parse(signedUrl), headers: {'Content-Type': contentType ?? 'application/octet-stream'}, body: bytes);
    if (putResp.statusCode == 200 || putResp.statusCode == 201) {
      final publicMediaUrl = 'https://firebasestorage.googleapis.com/v0/b/k-empire-68e8c.appspot.com/o/${Uri.encodeComponent(destPath)}?alt=media';
      return publicMediaUrl;
    }
    throw Exception('Upload to signed URL failed: ${putResp.statusCode} ${putResp.body}');
  }
}
