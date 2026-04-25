import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

class BiometricCredentials {
  const BiometricCredentials({required this.email, required this.password});

  final String email;
  final String password;
}

class BiometricAuthRepository {
  BiometricAuthRepository({
    LocalAuthentication? localAuthentication,
    FlutterSecureStorage? secureStorage,
  }) : _localAuthentication = localAuthentication ?? LocalAuthentication(),
       _secureStorage = secureStorage ?? const FlutterSecureStorage();

  static const _enabledKey = 'bookcart_biometric_enabled';
  static const _emailKey = 'bookcart_biometric_email';
  static const _passwordKey = 'bookcart_biometric_password';

  final LocalAuthentication _localAuthentication;
  final FlutterSecureStorage _secureStorage;

  Future<bool> canUseBiometrics() async {
    try {
      final canCheckBiometrics = await _localAuthentication.canCheckBiometrics;
      if (!canCheckBiometrics) {
        return false;
      }

      final biometrics = await _localAuthentication.getAvailableBiometrics();
      return biometrics.isNotEmpty;
    } on PlatformException {
      return false;
    } on LocalAuthException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Future<bool> hasSavedCredentials() async {
    try {
      final enabled = await _secureStorage.read(key: _enabledKey);
      final email = await _secureStorage.read(key: _emailKey);
      final password = await _secureStorage.read(key: _passwordKey);

      return enabled == 'true' &&
          email != null &&
          email.trim().isNotEmpty &&
          password != null &&
          password.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<String> preferredBiometricLabel() async {
    try {
      final biometrics = await _localAuthentication.getAvailableBiometrics();
      if (biometrics.contains(BiometricType.face)) {
        return 'Face ID';
      }
      if (biometrics.contains(BiometricType.fingerprint) ||
          biometrics.contains(BiometricType.strong) ||
          biometrics.contains(BiometricType.weak)) {
        return 'Fingerprint';
      }
    } catch (_) {
      return 'Biometric';
    }

    return 'Biometric';
  }

  Future<void> saveCredentials({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim();
    if (normalizedEmail.isEmpty || password.isEmpty) {
      throw const BiometricAuthException(
        'Enter your email and password before enabling face login.',
      );
    }

    final available = await canUseBiometrics();
    if (!available) {
      throw const BiometricAuthException(
        'Face or fingerprint login is not available on this device.',
      );
    }

    await _secureStorage.write(key: _emailKey, value: normalizedEmail);
    await _secureStorage.write(key: _passwordKey, value: password);
    await _secureStorage.write(key: _enabledKey, value: 'true');
  }

  Future<BiometricCredentials> readCredentialsWithAuthentication() async {
    final hasCredentials = await hasSavedCredentials();
    if (!hasCredentials) {
      throw const BiometricAuthException(
        'Set up face login after signing in once with your password.',
      );
    }

    final available = await canUseBiometrics();
    if (!available) {
      throw const BiometricAuthException(
        'Face or fingerprint login is not available on this device.',
      );
    }

    final authenticated = await _authenticate();
    if (!authenticated) {
      throw const BiometricAuthException('Face login was cancelled.');
    }

    final email = await _secureStorage.read(key: _emailKey);
    final password = await _secureStorage.read(key: _passwordKey);
    if (email == null ||
        email.trim().isEmpty ||
        password == null ||
        password.isEmpty) {
      await clearCredentials();
      throw const BiometricAuthException(
        'Saved face login details were not found. Please log in again.',
      );
    }

    return BiometricCredentials(email: email.trim(), password: password);
  }

  Future<void> clearCredentials() async {
    await _secureStorage.delete(key: _enabledKey);
    await _secureStorage.delete(key: _emailKey);
    await _secureStorage.delete(key: _passwordKey);
  }

  Future<bool> _authenticate() async {
    try {
      return _localAuthentication.authenticate(
        localizedReason: 'Use your face or fingerprint to log in to BookCart.',
        biometricOnly: true,
        sensitiveTransaction: false,
        persistAcrossBackgrounding: true,
      );
    } on LocalAuthException catch (error) {
      throw BiometricAuthException(_mapLocalAuthError(error));
    } on PlatformException {
      throw const BiometricAuthException(
        'Could not start face login on this device.',
      );
    }
  }

  String _mapLocalAuthError(LocalAuthException error) {
    switch (error.code) {
      case LocalAuthExceptionCode.noBiometricHardware:
      case LocalAuthExceptionCode.biometricHardwareTemporarilyUnavailable:
        return 'Face or fingerprint login is not available on this device.';
      case LocalAuthExceptionCode.noBiometricsEnrolled:
      case LocalAuthExceptionCode.noCredentialsSet:
        return 'Add Face ID, fingerprint, or biometrics in device settings first.';
      case LocalAuthExceptionCode.temporaryLockout:
      case LocalAuthExceptionCode.biometricLockout:
        return 'Face login is locked for now. Try again later or use your password.';
      case LocalAuthExceptionCode.userCanceled:
      case LocalAuthExceptionCode.userRequestedFallback:
      case LocalAuthExceptionCode.systemCanceled:
      case LocalAuthExceptionCode.timeout:
        return 'Face login was cancelled.';
      case LocalAuthExceptionCode.authInProgress:
        return 'Face login is already in progress.';
      case LocalAuthExceptionCode.uiUnavailable:
        return 'Could not show the face login prompt right now.';
      case LocalAuthExceptionCode.deviceError:
      case LocalAuthExceptionCode.unknownError:
        return error.description ?? 'Face login failed. Please try again.';
    }
  }
}

class BiometricAuthException implements Exception {
  const BiometricAuthException(this.message);

  final String message;

  @override
  String toString() => message;
}
