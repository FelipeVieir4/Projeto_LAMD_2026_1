import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../../core/constants.dart';

class ApiException implements Exception {
  final String message;
  final int? statusCode;

  ApiException(this.message, [this.statusCode]);

  @override
  String toString() => message;
}

class ApiClient {
  final String? token;

  ApiClient({this.token});

  Map<String, String> get _headers => {
    'Content-Type': 'application/json',
    if (token != null) 'Authorization': 'Bearer $token',
  };

  Future<dynamic> get(String path) async {
    try {
      final response = await http
          .get(Uri.parse('${AppConstants.baseUrl}$path'), headers: _headers)
          .timeout(const Duration(seconds: 10));
      return _parse(response);
    } on SocketException {
      throw ApiException('Sem conexão com o servidor.');
    } on TimeoutException {
      throw ApiException('Tempo de resposta esgotado.');
    }
  }

  Future<dynamic> post(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .post(
            Uri.parse('${AppConstants.baseUrl}$path'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      return _parse(response);
    } on SocketException {
      throw ApiException('Sem conexão com o servidor.');
    } on TimeoutException {
      throw ApiException('Tempo de resposta esgotado.');
    }
  }

  Future<dynamic> patch(String path, Map<String, dynamic> body) async {
    try {
      final response = await http
          .patch(
            Uri.parse('${AppConstants.baseUrl}$path'),
            headers: _headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 10));
      return _parse(response);
    } on SocketException {
      throw ApiException('Sem conexão com o servidor.');
    } on TimeoutException {
      throw ApiException('Tempo de resposta esgotado.');
    }
  }

  dynamic _parse(http.Response response) {
    dynamic body;
    try {
      body = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      throw ApiException(
        'Servidor retornou resposta inválida (HTTP ${response.statusCode}). '
        'Verifique se o backend está rodando e a URL está correta.',
        response.statusCode,
      );
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return body;
    }
    final message =
        (body as Map<String, dynamic>)['message'] as String? ?? 'Erro desconhecido.';
    throw ApiException(message, response.statusCode);
  }
}
