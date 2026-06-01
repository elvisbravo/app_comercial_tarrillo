import 'dart:async';
import 'dart:convert';
import 'dart:io';
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
      final response =
          await http.get(_uri(path), headers: await _headers()).timeout(_timeout);
      return _handle(response);
    } on SocketException {
      throw ApiException(0, 'Sin conexión a internet');
    } on TimeoutException {
      throw ApiException(0, 'Tiempo de espera agotado');
    } on http.ClientException catch (e) {
      throw ApiException(0, 'Sin conexión: ${e.message}');
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
    Map<String, dynamic> body = {};
    if (response.body.isNotEmpty) {
      try {
        body = jsonDecode(response.body) as Map<String, dynamic>;
      } catch (_) {
        body = {};
      }
    }

    if (response.statusCode == 401) {
      throw ApiException(401, 'No autorizado. Inicie sesión nuevamente.');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }

    final message =
        (body['message'] ?? body['mensaje'] ?? 'Error ${response.statusCode}').toString();
    throw ApiException(response.statusCode, message);
  }
}
