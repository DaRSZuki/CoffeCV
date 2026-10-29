import 'dart:convert';
import 'dart:typed_data';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/prediction.dart';

class ApiException implements Exception {
  final String message;
  ApiException(this.message);
  @override
  String toString() => message;
}

/// Cliente del servidor de inferencia (server/app.py).
class ApiService {
  ApiService._();
  static final instance = ApiService._();

  static const _prefKey = 'server_url';

  /// 10.0.2.2 es la dirección de la PC vista desde el emulador de Android.
  /// En un teléfono real use la IP local de la PC, p. ej. http://192.168.1.50:8000
  static const defaultUrl = 'http://10.0.2.2:8000';

  String _baseUrl = defaultUrl;
  String get baseUrl => _baseUrl;

  Future<void> load() async {
    final prefs = await SharedPreferences.getInstance();
    _baseUrl = prefs.getString(_prefKey) ?? defaultUrl;
  }

  Future<void> setBaseUrl(String url) async {
    _baseUrl = url.trim().replaceAll(RegExp(r'/+$'), '');
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_prefKey, _baseUrl);
  }

  Future<bool> ping({String? url}) async {
    try {
      final res = await http.get(Uri.parse('${url ?? _baseUrl}/health')).timeout(const Duration(seconds: 4));
      return res.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<Prediction> predict(Uint8List imageBytes, {Duration timeout = const Duration(seconds: 20)}) async {
    final req = http.MultipartRequest('POST', Uri.parse('$_baseUrl/predict'))
      ..files.add(http.MultipartFile.fromBytes('file', imageBytes, filename: 'muestra.jpg'));
    try {
      final streamed = await req.send().timeout(timeout);
      final res = await http.Response.fromStream(streamed);
      if (res.statusCode != 200) {
        throw ApiException('El servidor respondió con error ${res.statusCode}.');
      }
      return Prediction.fromJson(jsonDecode(utf8.decode(res.bodyBytes)));
    } on ApiException {
      rethrow;
    } catch (_) {
      throw ApiException(
        'No se pudo conectar con el servidor en $_baseUrl.\n'
        'Verifique que esté encendido y que la dirección sea correcta en Ajustes.',
      );
    }
  }
}
