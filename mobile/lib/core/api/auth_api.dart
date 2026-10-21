import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'api_exception.dart';

class Account {
  const Account({
    required this.id,
    required this.mobileNumber,
    required this.preferredLanguage,
    required this.userKind,
  });

  final String id;
  final String mobileNumber;
  final String preferredLanguage;
  final String userKind;

  Account copyWith({String? preferredLanguage}) {
    return Account(
      id: id,
      mobileNumber: mobileNumber,
      preferredLanguage: preferredLanguage ?? this.preferredLanguage,
      userKind: userKind,
    );
  }

  factory Account.fromJson(Map<String, dynamic> json) {
    return Account(
      id: json['id'] as String,
      mobileNumber: json['mobile_number'] as String,
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      userKind: json['user_kind'] as String? ?? 'patient',
    );
  }
}

class PatientProfile {
  const PatientProfile({
    required this.id,
    required this.patientNumber,
    required this.fullName,
    required this.dateOfBirth,
    required this.sex,
    required this.mobileNumber,
    required this.preferredLanguage,
    this.relationship = 'self',
    this.isDefault = false,
  });

  final String id;
  final String patientNumber;
  final String fullName;
  final String? dateOfBirth;
  final String? sex;
  final String mobileNumber;
  final String preferredLanguage;
  final String relationship;
  final bool isDefault;

  factory PatientProfile.fromJson(Map<String, dynamic> json) {
    return PatientProfile(
      id: json['id'] as String,
      patientNumber: json['patient_number'] as String,
      fullName: json['full_name'] as String,
      dateOfBirth: json['date_of_birth'] as String?,
      sex: json['sex'] as String?,
      mobileNumber: json['mobile_number'] as String,
      preferredLanguage: json['preferred_language'] as String? ?? 'en',
      relationship: json['relationship'] as String? ?? 'self',
      isDefault: json['is_default'] as bool? ?? false,
    );
  }
}

class OtpRequest {
  const OtpRequest({
    required this.mobileNumber,
    required this.expiresIn,
    required this.resendAfter,
  });

  final String mobileNumber;
  final int expiresIn;
  final int resendAfter;
}

class VerifiedSession {
  const VerifiedSession({
    required this.access,
    required this.refresh,
    required this.account,
    required this.profile,
  });

  final String access;
  final String refresh;
  final Account account;
  final PatientProfile? profile;
}

class AuthApi {
  AuthApi({http.Client? client, String? baseUrl})
      : _injected = client,
        baseUrl = _trim(baseUrl ?? AppConfig.apiBaseUrl);

  final http.Client? _injected;
  http.Client? _owned;
  final String baseUrl;

  http.Client get _client => _injected ?? (_owned ??= http.Client());

  Future<OtpRequest> requestOtp(String mobileNumber) async {
    final body = await _send('POST', '/auth/otp/request/', json: {
      'mobile_number': mobileNumber,
    });
    return OtpRequest(
      mobileNumber: body['mobile_number'] as String,
      expiresIn: (body['expires_in'] as num).toInt(),
      resendAfter: (body['resend_after'] as num).toInt(),
    );
  }

  Future<VerifiedSession> verifyOtp({
    required String mobileNumber,
    required String code,
  }) async {
    final body = await _send('POST', '/auth/otp/verify/', json: {
      'mobile_number': mobileNumber,
      'code': code,
    });
    return _session(body);
  }

  Future<VerifiedSession> refresh(String refreshToken) async {
    final body = await _send('POST', '/auth/token/refresh/', json: {
      'refresh': refreshToken,
    });
    return _session(body);
  }

  Future<void> logout(String refreshToken) async {
    await _send('POST', '/auth/logout/', json: {'refresh': refreshToken}, allowEmpty: true);
  }

  Future<PatientProfile> createProfile({
    required String access,
    required String fullName,
    String? dateOfBirth,
    String? sex,
    required String preferredLanguage,
  }) async {
    final payload = <String, dynamic>{
      'full_name': fullName,
      'preferred_language': preferredLanguage,
    };
    if (dateOfBirth != null) {
      payload['date_of_birth'] = dateOfBirth;
    }
    if (sex != null) {
      payload['sex'] = sex;
    }
    final body = await _send('POST', '/me/patient-profiles/', access: access, json: payload);
    return PatientProfile.fromJson(body);
  }

  Future<List<PatientProfile>> listProfiles(String access) async {
    final body = await _send('GET', '/me/patient-profiles/', access: access);
    final results = body['results'];
    if (results is! List) {
      return const [];
    }
    return [
      for (final item in results)
        if (item is Map) PatientProfile.fromJson(_map(item)),
    ];
  }

  Future<PatientProfile> createFamilyProfile({
    required String access,
    required String fullName,
    required String relationship,
    String? mobileNumber,
    required String preferredLanguage,
  }) async {
    final payload = <String, dynamic>{
      'full_name': fullName,
      'relationship': relationship,
      'preferred_language': preferredLanguage,
    };
    if (mobileNumber != null && mobileNumber.isNotEmpty) {
      payload['mobile_number'] = mobileNumber;
    }
    final body = await _send('POST', '/me/patient-profiles/', access: access, json: payload);
    return PatientProfile.fromJson(body);
  }

  Future<PatientProfile> updateFamilyProfile({
    required String access,
    required String profileId,
    required String fullName,
    required String relationship,
    String? mobileNumber,
  }) async {
    final body = await _send(
      'PATCH',
      '/me/patient-profiles/$profileId/',
      access: access,
      json: {
        'full_name': fullName,
        'relationship': relationship,
        'mobile_number': mobileNumber ?? '',
      },
    );
    return PatientProfile.fromJson(body);
  }

  Future<void> deleteFamilyProfile(String access, String profileId) async {
    await _send('DELETE', '/me/patient-profiles/$profileId/', access: access, allowEmpty: true);
  }

  VerifiedSession _session(Map<String, dynamic> body) {
    final user = _map(body['user']);
    final profile = user['profile'];
    return VerifiedSession(
      access: body['access'] as String,
      refresh: body['refresh'] as String,
      account: Account.fromJson(user),
      profile: profile is Map ? PatientProfile.fromJson(_map(profile)) : null,
    );
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    Map<String, dynamic>? json,
    String? access,
    bool allowEmpty = false,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
    if (access != null && access.isNotEmpty) {
      headers['Authorization'] = 'Bearer $access';
    }
    final uri = Uri.parse('$baseUrl$path');
    try {
      final response = await _client
          .send(_request(method, uri, headers, json))
          .timeout(const Duration(seconds: 20));
      final text = await response.stream.bytesToString();
      return _decode(response.statusCode, text, allowEmpty: allowEmpty);
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

  http.Request _request(String method, Uri uri, Map<String, String> headers, Map<String, dynamic>? json) {
    final request = http.Request(method, uri);
    request.headers.addAll(headers);
    if (json != null) {
      request.body = jsonEncode(json);
    }
    return request;
  }

  Map<String, dynamic> _decode(int statusCode, String text, {required bool allowEmpty}) {
    if (statusCode == 204 || (allowEmpty && text.isEmpty && statusCode < 400)) {
      return {};
    }
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
    final body = decoded is Map ? _map(decoded) : <String, dynamic>{};
    if (statusCode >= 400) {
      final error = body['error'];
      final map = error is Map ? _map(error) : <String, dynamic>{};
      final retry = map['retry_after'];
      throw ApiException(
        statusCode: statusCode,
        code: map['code']?.toString() ?? 'REQUEST_ERROR',
        message: map['message']?.toString() ?? 'The request could not be completed.',
        fields: _fields(map['fields']),
        retryAfter: retry is num ? retry.toInt() : null,
      );
    }
    return body;
  }

  static Map<String, String> _fields(Object? value) {
    if (value is! Map) {
      return const {};
    }
    final fields = <String, String>{};
    value.forEach((key, item) {
      final text = item is List && item.isNotEmpty ? item.first.toString() : item?.toString() ?? '';
      if (text.isNotEmpty) {
        fields[key.toString()] = text;
      }
    });
    return fields;
  }

  static Map<String, dynamic> _map(Object? value) {
    return Map<String, dynamic>.from(value as Map);
  }

  static String _trim(String value) {
    return value.endsWith('/') ? value.substring(0, value.length - 1) : value;
  }
}
