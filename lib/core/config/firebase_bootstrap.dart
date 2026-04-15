import 'package:bookcart/core/config/firebase_app_options.dart';
import 'package:bookcart/firebase_options.dart';
import 'package:firebase_core/firebase_core.dart';

class FirebaseBootstrapResult {
  const FirebaseBootstrapResult._({required this.isReady, this.errorMessage});

  const FirebaseBootstrapResult.ready() : this._(isReady: true);

  const FirebaseBootstrapResult.notReady(String message)
    : this._(isReady: false, errorMessage: message);

  final bool isReady;
  final String? errorMessage;
}

class FirebaseBootstrap {
  static Future<FirebaseBootstrapResult> initialize() async {
    try {
      if (Firebase.apps.isEmpty) {
        await Firebase.initializeApp(options: _resolveOptions());
      }

      return const FirebaseBootstrapResult.ready();
    } catch (error) {
      return FirebaseBootstrapResult.notReady(_buildErrorMessage(error));
    }
  }

  static FirebaseOptions _resolveOptions() {
    final validationError = FirebaseAppOptions.validationError;
    if (validationError == null) {
      return FirebaseAppOptions.currentPlatform;
    }

    if (FirebaseAppOptions.hasRuntimeOverrides) {
      throw StateError(validationError);
    }

    return DefaultFirebaseOptions.currentPlatform;
  }

  static String _buildErrorMessage(Object error) {
    if (error is StateError) {
      return '${error.message}\n\n'
          'Tip: if you want to use custom Firebase values, pass every required '
          '`--dart-define`. Otherwise, use the generated FlutterFire config '
          'already included in this project.';
    }

    if (error is UnsupportedError) {
      return '${error.message}\n\n'
          'Run `flutterfire configure` for this platform, or start the app '
          'with the matching Firebase `--dart-define` values.';
    }

    return 'Firebase initialization failed. Check your Firebase project '
        'settings and try again.\n$error';
  }
}
