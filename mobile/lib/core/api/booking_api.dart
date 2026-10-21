import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

import '../config.dart';
import 'api_exception.dart';
import 'catalogue_api.dart';

class BookingSummary {
  const BookingSummary({
    required this.id,
    required this.reference,
    required this.patientName,
    required this.status,
    required this.requestedDate,
    this.doctorName,
    this.serviceName,
    this.patientNote,
    this.preferredTimeSlot,
    this.confirmedFor,
  });

  final String id;
  final String reference;
  final String patientName;
  final String status;
  final String requestedDate;
  final String? doctorName;
  final String? serviceName;
  final String? patientNote;
  final String? preferredTimeSlot;
  final String? confirmedFor;

  String get targetName => serviceName ?? doctorName ?? 'Consultation';

  factory BookingSummary.fromJson(Map<String, dynamic> json) {
    return BookingSummary(
      id: json['id'] as String,
      reference: json['reference'] as String,
      patientName: json['patient_name'] as String? ?? '',
      status: json['status'] as String? ?? 'requested',
      requestedDate: json['requested_date'] as String? ?? '',
      doctorName: json['doctor_name'] as String?,
      serviceName: json['service_name'] as String?,
      patientNote: json['patient_note'] as String?,
      preferredTimeSlot: json['preferred_time_slot'] as String?,
      confirmedFor: json['confirmed_for'] as String?,
    );
  }
}

class ConsultationDoctor {
  const ConsultationDoctor({
    required this.id,
    required this.fullName,
    this.qualification,
    this.specialtySummary,
    this.photoUrl,
  });

  final String id;
  final String fullName;
  final String? qualification;
  final String? specialtySummary;
  final String? photoUrl;

  factory ConsultationDoctor.fromJson(Map<String, dynamic> json) {
    return ConsultationDoctor(
      id: json['id'] as String,
      fullName: json['full_name'] as String,
      qualification: json['qualification'] as String?,
      specialtySummary: json['specialty_summary'] as String?,
      photoUrl: json['photo_url'] as String?,
    );
  }
}

class BookingOptions {
  const BookingOptions({
    this.doctor,
    this.timeSlots = const [],
    this.services = const [],
  });

  final ConsultationDoctor? doctor;
  final List<String> timeSlots;
  final List<CatalogueService> services;

  factory BookingOptions.fromJson(Map<String, dynamic> json) {
    final doctor = json['consultation_doctor'];
    final slots = json['time_slots'];
    final services = json['services'];
    return BookingOptions(
      doctor: doctor is Map ? ConsultationDoctor.fromJson(Map<String, dynamic>.from(doctor)) : null,
      timeSlots: [
        if (slots is List)
          for (final slot in slots) slot.toString(),
      ],
      services: [
        if (services is List)
          for (final item in services)
            if (item is Map) CatalogueService.fromJson(Map<String, dynamic>.from(item)),
      ],
    );
  }
}

class BookingApi {
  BookingApi({http.Client? client, String? baseUrl})
      : _injected = client,
        baseUrl = baseUrl ?? AppConfig.apiBaseUrl;

  final http.Client? _injected;
  http.Client? _owned;
  final String baseUrl;

  http.Client get _client => _injected ?? (_owned ??= http.Client());

  Future<BookingOptions> options(String access) async {
    return BookingOptions.fromJson(await _send('GET', '/booking-options/', access: access));
  }

  Future<List<BookingSummary>> list(String access) async {
    final body = await _send('GET', '/bookings/', access: access);
    final results = body['results'];
    if (results is! List) {
      return const [];
    }
    return [
      for (final item in results)
        if (item is Map) BookingSummary.fromJson(Map<String, dynamic>.from(item)),
    ];
  }

  Future<BookingSummary> create({
    required String access,
    required String idempotencyKey,
    required String patientProfileId,
    String? serviceId,
    required String requestedDate,
    required String timeSlot,
    String? note,
  }) async {
    final body = await _send(
      'POST',
      '/bookings/',
      access: access,
      idempotencyKey: idempotencyKey,
      json: {
        'patient_profile_id': patientProfileId,
        if (serviceId != null) 'service_id': serviceId,
        'requested_date': requestedDate,
        'preferred_time_slot': timeSlot,
        if (note != null && note.isNotEmpty) 'patient_note': note,
      },
    );
    return BookingSummary.fromJson(body);
  }

  Future<BookingSummary> requestCancellation(String access, String bookingId, {String? reason}) async {
    final body = await _send(
      'POST',
      '/bookings/$bookingId/cancellation-requests/',
      access: access,
      json: {if (reason != null && reason.isNotEmpty) 'reason': reason},
    );
    return BookingSummary.fromJson(body);
  }

  Future<Map<String, dynamic>> _send(
    String method,
    String path, {
    required String access,
    Map<String, dynamic>? json,
    String? idempotencyKey,
  }) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Authorization': 'Bearer $access',
    };
    if (json != null) {
      headers['Content-Type'] = 'application/json';
    }
    if (idempotencyKey != null) {
      headers['Idempotency-Key'] = idempotencyKey;
    }
    final request = http.Request(method, Uri.parse('$baseUrl$path'));
    request.headers.addAll(headers);
    if (json != null) {
      request.body = jsonEncode(json);
    }
    try {
      final response = await _client.send(request).timeout(const Duration(seconds: 20));
      final text = await response.stream.bytesToString();
      return _decode(response.statusCode, text);
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
        fields: _fields(map['fields']),
      );
    }
    return body;
  }

  Map<String, String> _fields(Object? raw) {
    if (raw is! Map) {
      return const {};
    }
    final fields = <String, String>{};
    raw.forEach((key, value) {
      final text = value is List && value.isNotEmpty ? value.first.toString() : value?.toString() ?? '';
      if (text.isNotEmpty) {
        fields[key.toString()] = text;
      }
    });
    return fields;
  }
}

String bookingStatusLabel(String status) {
  switch (status) {
    case 'requested':
      return 'Pending';
    case 'under_review':
      return 'Under review';
    case 'confirmed':
      return 'Confirmed';
    case 'rejected':
      return 'Rejected';
    case 'cancellation_requested':
      return 'Cancellation requested';
    case 'cancelled':
      return 'Cancelled';
    case 'completed':
      return 'Completed';
    case 'no_show':
      return 'No show';
    default:
      return status;
  }
}
