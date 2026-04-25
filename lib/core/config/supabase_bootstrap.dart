import 'package:bookcart/core/config/supabase_app_options.dart';
import 'package:bookcart/core/utils/app_logger.dart';
import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseBootstrapResult {
  const SupabaseBootstrapResult._({required this.isReady, this.errorMessage});

  const SupabaseBootstrapResult.ready() : this._(isReady: true);

  const SupabaseBootstrapResult.notReady(String message)
    : this._(isReady: false, errorMessage: message);

  final bool isReady;
  final String? errorMessage;
}

class SupabaseBootstrap {
  static bool _isInitialized = false;

  static Future<SupabaseBootstrapResult> initialize() async {
    if (_isInitialized) {
      AppLogger.info('SupabaseBootstrap', 'Supabase already initialized');
      return const SupabaseBootstrapResult.ready();
    }

    final timer = AppLogger.startTimer('SupabaseBootstrap', 'initialize');
    try {
      await Supabase.initialize(
        url: SupabaseAppOptions.url,
        anonKey: SupabaseAppOptions.publishableKey,
        debug: kDebugMode,
      );
      _isInitialized = true;
      timer.success('Supabase ready', details: {'url': SupabaseAppOptions.url});
      return const SupabaseBootstrapResult.ready();
    } catch (error, stackTrace) {
      timer.fail('Supabase setup error', error: error, stackTrace: stackTrace);
      return SupabaseBootstrapResult.notReady(_buildErrorMessage(error));
    }
  }

  static String _buildErrorMessage(Object error) {
    if (error is StateError) {
      return error.message.toString();
    }

    return 'Supabase initialization failed. Check your project URL and '
        'publishable key, then try again.';
  }
}
