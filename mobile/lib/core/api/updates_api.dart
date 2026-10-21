import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'api_exception.dart';

class HospitalUpdate {
  const HospitalUpdate({
    required this.id,
    required this.title,
    required this.body,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String body;
  final String createdAt;

  factory HospitalUpdate.fromJson(Map<String, dynamic> json) {
    return HospitalUpdate(
      id: json['id'] as String,
      title: json['title'] as String? ?? 'Mallika Hospitals',
      body: json['body'] as String? ?? '',
      createdAt: json['created_at'] as String? ?? '',
    );
  }
}

class HospitalBanner {
  const HospitalBanner({required this.id, required this.title, this.imageUrl});

  final String id;
  final String title;
  final String? imageUrl;

  factory HospitalBanner.fromJson(Map<String, dynamic> json) {
    return HospitalBanner(
      id: json['id'] as String,
      title: json['title'] as String,
      imageUrl: json['image_url'] as String?,
    );
  }
}

class UpdatesApi {
  UpdatesApi({http.Client? client, String? baseUrl})
      : _injected = client,
        baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client? _injected;
  http.Client? _owned;
  final String baseUrl;

  http.Client get _client => _injected ?? (_owned ??= http.Client());

  Future<List<HospitalUpdate>> notifications(String access) async {
    final body = await _get('/notifications/', access);
    return [for (final item in _results(body)) HospitalUpdate.fromJson(item)];
  }

  Future<List<HospitalBanner>> banners(String access) async {
    final body = await _get('/banners/', access);
    return [for (final item in _results(body)) HospitalBanner.fromJson(item)];
  }

  Future<Map<String, dynamic>> _get(String path, String access) async {
    try {
      final response = await _client
          .get(
            Uri.parse('$baseUrl$path'),
            headers: {'Accept': 'application/json', 'Authorization': 'Bearer $access'},
          )
          .timeout(const Duration(seconds: 20));
      return _decode(response.statusCode, response.body);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw const ApiException(
        statusCode: 0,
        code: 'NETWORK',
        message: 'The hospital service did not respond. Check your connection and try again.',
      );
    } on http.ClientException {
      throw const ApiException(
        statusCode: 0,
        code: 'NETWORK',
        message: 'The hospital service could not be reached. Check your connection and try again.',
      );
    }
  }

  Map<String, dynamic> _decode(int statusCode, String text) {
    Object? decoded;
    try {
      decoded = text.isEmpty ? <String, dynamic>{} : jsonDecode(text);
    } on FormatException {
      throw const ApiException(
        statusCode: 0,
        code: 'NETWORK',
        message: 'The hospital service sent an unexpected response.',
      );
    }
    final body = decoded is Map ? Map<String, dynamic>.from(decoded) : <String, dynamic>{};
    if (statusCode >= 400) {
      final error = body['error'];
      final map = error is Map ? Map<String, dynamic>.from(error) : <String, dynamic>{};
      throw ApiException(
        statusCode: statusCode,
        code: map['code']?.toString() ?? 'REQUEST_ERROR',
        message: map['message']?.toString() ?? 'The request could not be completed.',
      );
    }
    return body;
  }

  List<Map<String, dynamic>> _results(Map<String, dynamic> body) {
    final results = body['results'];
    if (results is! List) {
      return const [];
    }
    return [
      for (final item in results)
        if (item is Map) Map<String, dynamic>.from(item),
    ];
  }
}
