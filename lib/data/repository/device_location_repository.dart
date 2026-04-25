import 'dart:async';

import 'package:bookcart/core/utils/app_logger.dart';
import 'package:bookcart/core/utils/location_time_utils.dart';
import 'package:bookcart/data/repository/location_label_repository.dart';
import 'package:geolocator/geolocator.dart';

class DeviceLocationRepository {
  static final LocationSettings _locationSettings = LocationSettings(
    accuracy: LocationAccuracy.high,
    timeLimit: const Duration(seconds: 12),
  );

  Future<DeviceLocationSnapshot> getCurrentLocation() async {
    final timer = AppLogger.startTimer(
      'DeviceLocationRepository',
      'getCurrentLocation',
    );
    try {
      await _ensureLocationPermission();
      final position = await _getBestAvailablePosition();
      final locationLabel = await LocationLabelRepository.resolveLocationLabel(
        latitude: position.latitude,
        longitude: position.longitude,
        currentLabel: null,
        fallbackLabel: 'Current location synced',
      );
      final snapshot = DeviceLocationSnapshot(
        latitude: position.latitude,
        longitude: position.longitude,
        label: locationLabel,
        capturedAt: position.timestamp,
      );
      timer.success(
        'Location synced',
        details: {
          'lat': snapshot.latitude,
          'lng': snapshot.longitude,
          'label': snapshot.label,
          'capturedAt': formatLocationRefreshTime(snapshot.capturedAt),
        },
      );
      return snapshot;
    } on DeviceLocationException {
      timer.warning('Location sync blocked by user-facing exception');
      rethrow;
    } catch (error, stackTrace) {
      timer.fail(
        'Location sync exception',
        error: error,
        stackTrace: stackTrace,
      );
      throw DeviceLocationException(_mapError(error));
    }
  }

  Future<void> _ensureLocationPermission() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw const DeviceLocationException(
        'Turn on location services and try again.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }

    if (permission == LocationPermission.denied) {
      throw const DeviceLocationException(
        'Location permission was denied. Allow it to sync your place.',
      );
    }

    if (permission == LocationPermission.deniedForever) {
      throw const DeviceLocationException(
        'Location permission is permanently denied. Enable it from app settings to sync your place.',
      );
    }
  }

  Future<Position> _getBestAvailablePosition() async {
    Object? lastError;

    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: _locationSettings,
      );
    } catch (error) {
      if (_shouldRethrowImmediately(error)) {
        rethrow;
      }
      lastError = error;
      AppLogger.warning(
        'DeviceLocationRepository',
        'Current position failed, checking last known position',
        details: {'error': error},
      );
    }

    final cachedPosition = await Geolocator.getLastKnownPosition();
    if (cachedPosition != null) {
      return cachedPosition;
    }

    throw lastError;
  }

  bool _shouldRethrowImmediately(Object error) {
    return error is DeviceLocationException ||
        error is LocationServiceDisabledException ||
        error is PermissionDeniedException ||
        error is PermissionRequestInProgressException ||
        error is PermissionDefinitionsNotFoundException;
  }

  String _mapError(Object error) {
    if (error is DeviceLocationException) {
      return error.message;
    }

    if (error is LocationServiceDisabledException) {
      return 'Turn on location services and try again.';
    }

    if (error is PermissionDeniedException) {
      return 'Location permission was denied. Allow it to sync your place.';
    }

    if (error is PermissionRequestInProgressException) {
      return 'A location update is already in progress.';
    }

    if (error is PermissionDefinitionsNotFoundException) {
      return 'Location permissions are missing from the app configuration.';
    }

    if (error is TimeoutException) {
      return 'Current location is unavailable right now. Open Maps once or wait a moment, then try again.';
    }

    if (error is UnsupportedError) {
      return 'Location is not supported on this device.';
    }

    return 'Could not read your current location.';
  }
}

class DeviceLocationSnapshot {
  const DeviceLocationSnapshot({
    required this.latitude,
    required this.longitude,
    required this.label,
    required this.capturedAt,
  });

  final double latitude;
  final double longitude;
  final String label;
  final DateTime capturedAt;
}

class DeviceLocationException implements Exception {
  const DeviceLocationException(this.message);

  final String message;

  @override
  String toString() => message;
}
