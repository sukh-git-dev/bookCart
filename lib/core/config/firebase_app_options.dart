import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';

class FirebaseAppOptions {
  static const String _apiKey = String.fromEnvironment('FIREBASE_API_KEY');
  static const String _projectId = String.fromEnvironment(
    'FIREBASE_PROJECT_ID',
  );
  static const String _messagingSenderId = String.fromEnvironment(
    'FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String _genericAppId = String.fromEnvironment('FIREBASE_APP_ID');
  static const String _androidAppId = String.fromEnvironment(
    'FIREBASE_ANDROID_APP_ID',
  );
  static const String _iosAppId = String.fromEnvironment('FIREBASE_IOS_APP_ID');
  static const String _webAppId = String.fromEnvironment('FIREBASE_WEB_APP_ID');
  static const String _macosAppId = String.fromEnvironment(
    'FIREBASE_MACOS_APP_ID',
  );
  static const String _windowsAppId = String.fromEnvironment(
    'FIREBASE_WINDOWS_APP_ID',
  );
  static const String _linuxAppId = String.fromEnvironment(
    'FIREBASE_LINUX_APP_ID',
  );
  static const String _authDomain = String.fromEnvironment(
    'FIREBASE_AUTH_DOMAIN',
  );
  static const String _storageBucket = String.fromEnvironment(
    'FIREBASE_STORAGE_BUCKET',
  );
  static const String _measurementId = String.fromEnvironment(
    'FIREBASE_MEASUREMENT_ID',
  );
  static const String _iosBundleId = String.fromEnvironment(
    'FIREBASE_IOS_BUNDLE_ID',
  );

  static bool get hasRuntimeOverrides => <String>[
    _apiKey,
    _projectId,
    _messagingSenderId,
    _genericAppId,
    _androidAppId,
    _iosAppId,
    _webAppId,
    _macosAppId,
    _windowsAppId,
    _linuxAppId,
    _authDomain,
    _storageBucket,
    _measurementId,
    _iosBundleId,
  ].any((value) => value.isNotEmpty);

  static String? get validationError {
    final missingKeys = <String>[
      if (_apiKey.isEmpty) 'FIREBASE_API_KEY',
      if (_projectId.isEmpty) 'FIREBASE_PROJECT_ID',
      if (_messagingSenderId.isEmpty) 'FIREBASE_MESSAGING_SENDER_ID',
      if (_appIdForCurrentPlatform().isEmpty) _appIdEnvForCurrentPlatform(),
    ];

    if (missingKeys.isEmpty) {
      return null;
    }

    return 'Firebase is not configured yet. Add Dart defines for '
        '${missingKeys.join(', ')} and restart the app.';
  }

  static FirebaseOptions get currentPlatform {
    final error = validationError;
    if (error != null) {
      throw StateError(error);
    }

    return FirebaseOptions(
      apiKey: _apiKey,
      appId: _appIdForCurrentPlatform(),
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      authDomain: _authDomain.isEmpty ? null : _authDomain,
      storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
      measurementId: _measurementId.isEmpty ? null : _measurementId,
      iosBundleId: _iosBundleId.isEmpty ? null : _iosBundleId,
    );
  }

  static String _appIdForCurrentPlatform() {
    if (kIsWeb) {
      return _webAppId.isNotEmpty ? _webAppId : _genericAppId;
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return _androidAppId.isNotEmpty ? _androidAppId : _genericAppId;
      case TargetPlatform.iOS:
        return _iosAppId.isNotEmpty ? _iosAppId : _genericAppId;
      case TargetPlatform.macOS:
        if (_macosAppId.isNotEmpty) {
          return _macosAppId;
        }
        return _iosAppId.isNotEmpty ? _iosAppId : _genericAppId;
      case TargetPlatform.windows:
        return _windowsAppId.isNotEmpty ? _windowsAppId : _genericAppId;
      case TargetPlatform.linux:
        return _linuxAppId.isNotEmpty ? _linuxAppId : _genericAppId;
      case TargetPlatform.fuchsia:
        return _genericAppId;
    }
  }

  static String _appIdEnvForCurrentPlatform() {
    if (kIsWeb) {
      return 'FIREBASE_WEB_APP_ID';
    }

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return 'FIREBASE_ANDROID_APP_ID';
      case TargetPlatform.iOS:
        return 'FIREBASE_IOS_APP_ID';
      case TargetPlatform.macOS:
        return 'FIREBASE_MACOS_APP_ID';
      case TargetPlatform.windows:
        return 'FIREBASE_WINDOWS_APP_ID';
      case TargetPlatform.linux:
        return 'FIREBASE_LINUX_APP_ID';
      case TargetPlatform.fuchsia:
        return 'FIREBASE_APP_ID';
    }
  }
}
