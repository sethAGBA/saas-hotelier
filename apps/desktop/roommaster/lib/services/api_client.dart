import 'dart:convert';
import 'package:http/http.dart' as http;

import '../services/auth_service.dart';
import '../data/api_config.dart';

class ApiClient {
  ApiClient({
    http.Client? client,
    String? baseUrl,
  })  : baseUrl = baseUrl ?? ApiConfig.baseUrl,
        _client = client ?? http.Client();

  final http.Client _client;
  final String baseUrl;

  String _normalizeBase(String value) {
    if (value.endsWith('/')) return value.substring(0, value.length - 1);
    return value;
  }

  /// Retrieves a JWT and tenantId from AuthService (stub: use current user).
  Future<Map<String, String>> _authHeaders() async {
    final auth = AuthService.instance;
    final token = auth.authToken;
    final tenantId = auth.tenantId;
    if (token == null || tenantId == null) {
      throw Exception('Utilisateur non authentifié ou tenant manquant');
    }
    return {
      'Authorization': 'Bearer $token',
      'X-Tenant-Id': tenantId,
      'Content-Type': 'application/json',
    };
  }

  Future<List<Map<String, dynamic>>> fetchRooms() async {
    final headers = await _authHeaders();
    final resp = await _client.get(
      Uri.parse('${_normalizeBase(baseUrl)}/api/rooms'),
      headers: headers,
    );
    if (resp.statusCode != 200) {
      throw Exception('Erreur chargement chambres (${resp.statusCode})');
    }
    final data = jsonDecode(resp.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }

  Future<List<Map<String, dynamic>>> fetchReservations() async {
    final headers = await _authHeaders();
    final resp = await _client.get(
      Uri.parse('${_normalizeBase(baseUrl)}/api/reservations'),
      headers: headers,
    );
    if (resp.statusCode != 200) {
      throw Exception('Erreur chargement réservations (${resp.statusCode})');
    }
    final data = jsonDecode(resp.body) as List<dynamic>;
    return data.cast<Map<String, dynamic>>();
  }
}
