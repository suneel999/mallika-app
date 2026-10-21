import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'api_exception.dart';

class CatalogueDepartment {
  const CatalogueDepartment({
    required this.id,
    required this.name,
    required this.slug,
    this.description,
  });

  final String id;
  final String name;
  final String slug;
  final String? description;

  factory CatalogueDepartment.fromJson(Map<String, dynamic> json) {
    return CatalogueDepartment(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      description: json['description'] as String?,
    );
  }
}

class CatalogueDoctor {
  const CatalogueDoctor({
    required this.id,
    required this.fullName,
    this.qualification,
    this.specialtySummary,
    this.bio,
    this.photoUrl,
    this.departments = const [],
  });

  final String id;
  final String fullName;
  final String? qualification;
  final String? specialtySummary;
  final String? bio;
  final String? photoUrl;
  final List<CatalogueDepartmentLink> departments;

  factory CatalogueDoctor.fromJson(Map<String, dynamic> json) {
    final links = json['departments'];
    return CatalogueDoctor(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      qualification: json['qualification'] as String?,
      specialtySummary: json['specialty_summary'] as String?,
      bio: json['bio'] as String?,
      photoUrl: json['photo_url'] as String?,
      departments: [
        if (links is List)
          for (final item in links)
            if (item is Map) CatalogueDepartmentLink.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }
}

class CatalogueDepartmentLink {
  const CatalogueDepartmentLink({
    required this.id,
    required this.name,
    required this.slug,
    required this.isPrimary,
  });

  final String id;
  final String name;
  final String slug;
  final bool isPrimary;

  factory CatalogueDepartmentLink.fromJson(Map<String, dynamic> json) {
    return CatalogueDepartmentLink(
      id: json['id'] as String,
      name: json['name'] as String,
      slug: json['slug'] as String,
      isPrimary: json['is_primary'] == true,
    );
  }
}

class CatalogueService {
  const CatalogueService({
    required this.id,
    required this.name,
    required this.serviceType,
    this.description,
    this.preparationInstructions,
  });

  final String id;
  final String name;
  final String serviceType;
  final String? description;
  final String? preparationInstructions;

  factory CatalogueService.fromJson(Map<String, dynamic> json) {
    return CatalogueService(
      id: json['id'] as String,
      name: json['name'] as String,
      serviceType: json['service_type'] as String,
      description: json['description'] as String?,
      preparationInstructions: json['preparation_instructions'] as String?,
    );
  }
}

class CatalogueApi {
  CatalogueApi({http.Client? client, String? baseUrl})
      : _injected = client,
        baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client? _injected;
  http.Client? _owned;
  final String baseUrl;

  http.Client get _client => _injected ?? (_owned ??= http.Client());

  Future<List<CatalogueDepartment>> departments(String access, {String search = ''}) async {
    final body = await _get('/departments/', access, {'search': search});
    return [for (final item in _results(body)) CatalogueDepartment.fromJson(item)];
  }

  Future<CatalogueDepartment> department(String access, String id) async {
    return CatalogueDepartment.fromJson(await _get('/departments/$id/', access, const {}));
  }

  Future<List<CatalogueDoctor>> doctors(
    String access, {
    String search = '',
    String department = '',
  }) async {
    final body = await _get('/doctors/', access, {'search': search, 'department': department});
    return [for (final item in _results(body)) CatalogueDoctor.fromJson(item)];
  }

  Future<CatalogueDoctor> doctor(String access, String id) async {
    return CatalogueDoctor.fromJson(await _get('/doctors/$id/', access, const {}));
  }

  Future<List<CatalogueService>> services(
    String access, {
    String search = '',
    String serviceType = '',
  }) async {
    final body = await _get('/services/', access, {'search': search, 'service_type': serviceType});
    return [for (final item in _results(body)) CatalogueService.fromJson(item)];
  }

  Future<CatalogueService> service(String access, String id) async {
    return CatalogueService.fromJson(await _get('/services/$id/', access, const {}));
  }

  Future<Map<String, dynamic>> _get(String path, String access, Map<String, String> query) async {
    final params = {
      for (final entry in query.entries)
        if (entry.value.trim().isNotEmpty) entry.key: entry.value.trim(),
    };
    final uri = Uri.parse('$baseUrl$path').replace(queryParameters: params.isEmpty ? null : params);
    try {
      final response = await _client
          .get(uri, headers: {'Accept': 'application/json', 'Authorization': 'Bearer $access'})
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
