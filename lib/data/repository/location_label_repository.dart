import 'package:bookcart/core/utils/location_label_utils.dart';
import 'package:bookcart/data/models/book_model.dart';
import 'package:bookcart/data/models/user_model.dart';
import 'package:flutter/foundation.dart';
import 'package:geocoding/geocoding.dart';

class LocationLabelRepository {
  static final Map<String, String> _cache = <String, String>{};

  static Future<String> resolveLocationLabel({
    required double? latitude,
    required double? longitude,
    required String? currentLabel,
    required String fallbackLabel,
  }) async {
    final readableLabel = readableLocationLabel(currentLabel);
    if (readableLabel != null) {
      return readableLabel;
    }

    if (latitude == null || longitude == null) {
      return fallbackLabel;
    }

    final cacheKey = _buildCacheKey(latitude, longitude);
    final cachedLabel = _cache[cacheKey];
    if (cachedLabel != null) {
      return cachedLabel;
    }

    try {
      final placemarks = await placemarkFromCoordinates(latitude, longitude);
      final resolvedLabel = buildFullLocationLabel(placemarks);
      if (resolvedLabel != null) {
        _cache[cacheKey] = resolvedLabel;
        return resolvedLabel;
      }
    } on NoResultFoundException catch (error) {
      debugPrint('BookCart geocoding -> no result for $cacheKey: $error');
    } catch (error) {
      debugPrint('BookCart geocoding -> failed for $cacheKey: $error');
    }

    return fallbackLabel;
  }

  static Future<UserModel> enrichUser(UserModel user) async {
    final fallbackLabel =
        readableLocationLabel(user.location) ??
        (user.latitude != null && user.longitude != null
            ? kCurrentLocationSyncedLabel
            : UserModel.defaultLocation);
    final resolvedLabel = await resolveLocationLabel(
      latitude: user.latitude,
      longitude: user.longitude,
      currentLabel: user.location,
      fallbackLabel: fallbackLabel,
    );
    if (resolvedLabel == user.location.trim()) {
      return user;
    }

    return user.copyWith(location: resolvedLabel);
  }

  static Future<BookModel> enrichBook(BookModel book) async {
    final fallbackLabel =
        readableLocationLabel(book.sellerLocation) ??
        (book.sellerLatitude != null && book.sellerLongitude != null
            ? kSellerLocationSyncedLabel
            : kLocationUnavailableLabel);
    final resolvedLabel = await resolveLocationLabel(
      latitude: book.sellerLatitude,
      longitude: book.sellerLongitude,
      currentLabel: book.sellerLocation,
      fallbackLabel: fallbackLabel,
    );
    if (resolvedLabel == book.sellerLocation.trim()) {
      return book;
    }

    return book.copyWith(sellerLocation: resolvedLabel);
  }

  static String _buildCacheKey(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}';
  }
}
