import 'dart:math' as math;

import 'package:bookcart/core/utils/location_label_utils.dart';

double? calculateDistanceKm({
  required double? fromLatitude,
  required double? fromLongitude,
  required double? toLatitude,
  required double? toLongitude,
}) {
  if (fromLatitude == null ||
      fromLongitude == null ||
      toLatitude == null ||
      toLongitude == null) {
    return null;
  }

  const earthRadiusKm = 6371.0;
  final latitudeDelta = _toRadians(toLatitude - fromLatitude);
  final longitudeDelta = _toRadians(toLongitude - fromLongitude);
  final startLatitude = _toRadians(fromLatitude);
  final endLatitude = _toRadians(toLatitude);

  final haversine =
      math.pow(math.sin(latitudeDelta / 2), 2) +
      math.cos(startLatitude) *
          math.cos(endLatitude) *
          math.pow(math.sin(longitudeDelta / 2), 2);
  final arc = 2 * math.atan2(math.sqrt(haversine), math.sqrt(1 - haversine));
  return earthRadiusKm * arc;
}

String formatDistanceKm(double? distanceKm) {
  if (distanceKm == null) {
    return 'Location';
  }

  if (distanceKm == 0) {
    return '0 KM';
  }

  final normalizedDistance = distanceKm < 1 ? 1 : distanceKm.round();
  return '$normalizedDistance KM';
}

bool isWithinNearbyRadius(
  double? distanceKm, {
  double nearbyRadiusKm = kDefaultNearbyRadiusKm,
}) {
  return distanceKm != null && distanceKm <= nearbyRadiusKm;
}

double _toRadians(double degrees) => degrees * math.pi / 180;
