import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiException implements Exception {
  final int statusCode;
  final String message;

  ApiException(this.statusCode, this.message);

  bool get isNetworkError => statusCode == 0;
  bool get isUnauthorized => statusCode == 401;

  @override
  String toString() => 'ApiException($statusCode): $message';
}

class ApiClient {
  static const String _tokenKey = 'auth_token';
  static const Duration _timeout = Duration(seconds: 8);

  static String get baseUrl =>
      dotenv.env['API_URL'] ?? 'http://10.0.2.2:8000/api';

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  static Future<void> setToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_tokenKey, token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_tokenKey);
  }

  static Future<Map<String, String>> _headers({bool withAuth = true}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (withAuth) {
      final token = await getToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }
    return headers;
  }

  static Uri _uri(String path) => Uri.parse('$baseUrl$path');

  static Future<Map<String, dynamic>> get(String path) async {
    try {
      final headers = await _headers();
      final uri = _uri(path);
      debugPrint('[ApiClient] GET $path');
      debugPrint('[ApiClient] URL: $uri');
      debugPrint('[ApiClient] Token: ${headers['Authorization']}');
      final response =
          await http.get(uri, headers: headers).timeout(const Duration(seconds: 30));
      debugPrint('[ApiClient] Response status: ${response.statusCode}');
      debugPrint('[ApiClient] Response body length: ${response.body.length}');

      return _handle(response);
    } on SocketException catch (e) {
      debugPrint('[ApiClient] SocketException: $e');
      throw ApiException(0, 'No puede conectar al servidor. Verifique su red.');
    } on TimeoutException {
      debugPrint('[ApiClient] TimeoutException');
      throw ApiException(0, 'El servidor no responde. Intente más tarde.');
    } on http.ClientException catch (e) {
      debugPrint('[ApiClient] ClientException: $e');
      throw ApiException(0, 'Error de conexión: ${e.message}');
    } catch (e, st) {
      debugPrint('[ApiClient] Unexpected error in GET: $e');
      debugPrint('[ApiClient] StackTrace: $st');
      throw ApiException(0, 'Error: $e');
    }
  }

  static Future<Map<String, dynamic>> post(
    String path,
    Map<String, dynamic> body,
  ) async {
    try {
      final response = await http
          .post(
            _uri(path),
            headers: await _headers(),
            body: jsonEncode(body),
          )
          .timeout(_timeout);
      return _handle(response);
    } on SocketException {
      throw ApiException(0, 'Sin conexión a internet');
    } on TimeoutException {
      throw ApiException(0, 'Tiempo de espera agotado');
    } on http.ClientException catch (e) {
      throw ApiException(0, 'Sin conexión: ${e.message}');
    }
  }

  static Map<String, dynamic> _handle(http.Response response) {
    debugPrint('[ApiClient] _handle called with status: ${response.statusCode}');

    Map<String, dynamic> body = {};
    bool isJson = false;

    try {
      if (response.body.isNotEmpty) {
        final decoded = jsonDecode(response.body);
        if (decoded is Map<String, dynamic>) {
          body = decoded;
          isJson = true;
          debugPrint('[ApiClient] Successfully parsed JSON response with ${body.keys.length} keys');
        } else {
          debugPrint('[ApiClient] Response is JSON but not a Map (type: ${decoded.runtimeType})');
        }
      }
    } catch (e, st) {
      debugPrint('[ApiClient] JSON parse error: $e');
      debugPrint('[ApiClient] StackTrace: $st');
      debugPrint('[ApiClient] Raw response (first 300 chars): ${response.body.length > 300 ? response.body.substring(0, 300) : response.body}');
      isJson = false;
    }

    // Si la respuesta no es JSON (ej: página de login HTML de Laravel),
    // tratar como error de autenticación
    if (!isJson && response.statusCode == 200) {
      debugPrint('[ApiClient] Non-JSON response with 200 status - treating as auth error');
      throw ApiException(401, 'Sesión expirada. Inicie sesión nuevamente.');
    }

    if (response.statusCode == 401) {
      throw ApiException(401, 'No autorizado. Inicie sesión nuevamente.');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message =
        (body['message'] ?? body['mensaje'] ?? 'Error ${response.statusCode}').toString();
    debugPrint('[ApiClient] Error response: $message');
    throw ApiException(response.statusCode, message);
  }
}
