import 'package:geocoding/geocoding.dart';

const double kDefaultNearbyRadiusKm = 15;
const String kLocationUnavailableLabel = 'Location unavailable';
const String kCurrentLocationSyncedLabel = 'Current location synced';
const String kSellerLocationSyncedLabel = 'Seller location synced';

final RegExp _coordinateLabelPattern = RegExp(
  r'^\s*[+-]?\d+(?:\.\d+)?(?:°?[NSns])?\s*,\s*[+-]?\d+(?:\.\d+)?(?:°?[EWew])?\s*$',
);

String? readableLocationLabel(String? value) {
  final trimmedValue = value?.trim() ?? '';
  if (trimmedValue.isEmpty || looksLikeCoordinateLabel(trimmedValue)) {
    return null;
  }

  return trimmedValue;
}

bool looksLikeCoordinateLabel(String value) {
  return _coordinateLabelPattern.hasMatch(value.trim());
}

String visibleLocationLabel(String? value, {required String fallback}) {
  return readableLocationLabel(value) ?? fallback;
}

String compactLocationLabel(String? value, {String fallback = 'Location'}) {
  final readableValue = readableLocationLabel(value);
  if (readableValue == null) {
    return fallback;
  }

  final segments = readableValue
      .split(',')
      .map((segment) => segment.trim())
      .where((segment) => segment.isNotEmpty)
      .take(2)
      .toList();
  if (segments.isEmpty) {
    return fallback;
  }

  return segments.join(', ');
}

String? buildFullLocationLabel(List<Placemark> placemarks) {
  if (placemarks.isEmpty) {
    return null;
  }

  final parts = <String>[];

  void addPart(String? value) {
    final trimmedValue = value?.trim() ?? '';
    if (trimmedValue.isEmpty) {
      return;
    }

    final normalizedValue = trimmedValue.toLowerCase();
    if (parts.any((part) => part.toLowerCase() == normalizedValue)) {
      return;
    }

    parts.add(trimmedValue);
  }

  final placemark = placemarks.first;
  addPart(placemark.name);
  addPart(placemark.subLocality);
  addPart(placemark.locality);
  addPart(placemark.subAdministrativeArea);
  addPart(placemark.administrativeArea);
  addPart(placemark.postalCode);
  addPart(placemark.country);

  if (parts.isEmpty) {
    addPart(placemark.street);
    addPart(placemark.thoroughfare);
  }

  if (parts.isEmpty) {
    return null;
  }

  return parts.join(', ');
}
