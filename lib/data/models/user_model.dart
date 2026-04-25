import 'dart:convert';
import 'dart:typed_data';

class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    this.location = defaultLocation,
    this.latitude,
    this.longitude,
    this.locationUpdatedAt,
    this.profileImageBase64,
    this.profileImageUrl,
  });

  static const String defaultLocation = 'Kolkata, West Bengal';

  final String id;
  final String name;
  final String phone;
  final String email;
  final String location;
  final double? latitude;
  final double? longitude;
  final DateTime? locationUpdatedAt;
  final String? profileImageBase64;
  final String? profileImageUrl;

  Uint8List? get profileImageBytes => _decodeImage(profileImageBase64);

  UserModel copyWith({
    String? id,
    String? name,
    String? phone,
    String? email,
    String? location,
    double? latitude,
    double? longitude,
    DateTime? locationUpdatedAt,
    String? profileImageBase64,
    String? profileImageUrl,
    bool clearCoordinates = false,
    bool clearLocationUpdatedAt = false,
    bool clearProfileImageBase64 = false,
    bool clearProfileImageUrl = false,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      location: location ?? this.location,
      latitude: clearCoordinates ? null : latitude ?? this.latitude,
      longitude: clearCoordinates ? null : longitude ?? this.longitude,
      locationUpdatedAt: clearLocationUpdatedAt
          ? null
          : locationUpdatedAt ?? this.locationUpdatedAt,
      profileImageBase64: clearProfileImageBase64
          ? null
          : profileImageBase64 ?? this.profileImageBase64,
      profileImageUrl: clearProfileImageUrl
          ? null
          : profileImageUrl ?? this.profileImageUrl,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'location': location,
      'latitude': latitude,
      'longitude': longitude,
      'locationUpdatedAt': locationUpdatedAt?.toIso8601String(),
      'profileImageBase64': _normalizedBase64(profileImageBase64),
      'profileImageUrl': _normalizedString(profileImageUrl),
    };
  }

  factory UserModel.fromJson(
    Map<String, dynamic> json, {
    String? fallbackId,
    String? fallbackEmail,
  }) {
    final resolvedId =
        json['id'] as String? ?? json['user_id'] as String? ?? fallbackId ?? '';
    final resolvedEmail =
        json['email'] as String? ??
        json['seller_email'] as String? ??
        fallbackEmail ??
        '';
    final rawProfileImageBase64 = _normalizedString(
      json['profileImageBase64'] as String? ??
          json['profile_image_base64'] as String?,
    );
    final explicitProfileImageUrl = _normalizedString(
      json['profileImageUrl'] as String? ??
          json['profile_image_url'] as String?,
    );

    return UserModel(
      id: resolvedId,
      name:
          json['name'] as String? ??
          json['full_name'] as String? ??
          json['seller_name'] as String? ??
          '',
      phone: json['phone'] as String? ?? '',
      email: resolvedEmail,
      location: json['location'] as String? ?? defaultLocation,
      latitude: _doubleFromJson(json['latitude']),
      longitude: _doubleFromJson(json['longitude']),
      locationUpdatedAt: _dateTimeFromJson(
        json['locationUpdatedAt'] ?? json['location_updated_at'],
      ),
      profileImageBase64: _looksLikeHttpUrl(rawProfileImageBase64)
          ? null
          : _normalizedBase64(rawProfileImageBase64),
      profileImageUrl:
          explicitProfileImageUrl ??
          (_looksLikeHttpUrl(rawProfileImageBase64)
              ? rawProfileImageBase64
              : null),
    );
  }

  static String? _normalizedString(String? value) {
    final trimmed = value?.trim();
    if (trimmed == null || trimmed.isEmpty) {
      return null;
    }

    return trimmed;
  }

  static String? _normalizedBase64(String? value) {
    final normalized = _normalizedString(value);
    if (normalized == null) {
      return null;
    }

    final dataUriIndex = normalized.indexOf(',');
    if (normalized.startsWith('data:') && dataUriIndex >= 0) {
      return normalized.substring(dataUriIndex + 1).trim();
    }

    return normalized;
  }

  static bool _looksLikeHttpUrl(String? value) {
    final normalized = _normalizedString(value);
    if (normalized == null) {
      return false;
    }

    final uri = Uri.tryParse(normalized);
    return uri != null &&
        (uri.scheme == 'http' || uri.scheme == 'https') &&
        uri.host.isNotEmpty;
  }

  static Uint8List? _decodeImage(String? value) {
    final normalized = _normalizedBase64(value);
    if (normalized == null) {
      return null;
    }

    try {
      return base64Decode(normalized);
    } catch (_) {
      return null;
    }
  }

  static double? _doubleFromJson(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is num) {
      return value.toDouble();
    }
    if (value is String) {
      return double.tryParse(value);
    }

    return null;
  }

  static DateTime? _dateTimeFromJson(Object? value) {
    if (value == null) {
      return null;
    }
    if (value is DateTime) {
      return value;
    }
    if (value is String) {
      return DateTime.tryParse(value);
    }

    try {
      final dynamic timestamp = value;
      final Object? dateTime = timestamp.toDate();
      return dateTime is DateTime ? dateTime : null;
    } catch (_) {
      return null;
    }
  }
}
