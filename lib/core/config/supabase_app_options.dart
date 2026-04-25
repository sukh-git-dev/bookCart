class SupabaseAppOptions {
  static const String _defaultProjectRef = 'ppwczzetahzskjfqemby';
  static const String defaultProjectRef = _defaultProjectRef;
  static const String _defaultUrl = 'https://$_defaultProjectRef.supabase.co';
  static const String _defaultPublishableKey =
      'sb_publishable_1kJzcN89izTFEjeTIgPpsA_tEbDk_aY';

  static const String _url = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: _defaultUrl,
  );
  static const String _publishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
    defaultValue: _defaultPublishableKey,
  );

  static String? get validationError {
    final missingKeys = <String>[
      if (_url.trim().isEmpty) 'SUPABASE_URL',
      if (_publishableKey.trim().isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
    ];
    if (missingKeys.isEmpty) {
      return null;
    }

    return 'Supabase is not configured yet. Add Dart defines for '
        '${missingKeys.join(', ')} and restart the app.';
  }

  static String get url {
    final error = validationError;
    if (error != null) {
      throw StateError(error);
    }

    return _url.trim();
  }

  static String get publishableKey {
    final error = validationError;
    if (error != null) {
      throw StateError(error);
    }

    return _publishableKey.trim();
  }
}
