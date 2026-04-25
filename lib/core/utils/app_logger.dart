import 'package:flutter_colored_print/flutter_colored_print.dart' as colored;

class AppLogger {
  static void info(
    String scope,
    String message, {
    Map<String, Object?>? details,
  }) {
    colored.log(
      _buildMessage(scope, message, details: details),
      type: colored.LogType.info,
      color: colored.LogColor.cyan,
    );
  }

  static void success(
    String scope,
    String message, {
    Map<String, Object?>? details,
  }) {
    colored.log(
      _buildMessage(scope, message, details: details),
      type: colored.LogType.success,
      color: colored.LogColor.green,
    );
  }

  static void warning(
    String scope,
    String message, {
    Map<String, Object?>? details,
  }) {
    colored.log(
      _buildMessage(scope, message, details: details),
      type: colored.LogType.warning,
      color: colored.LogColor.yellow,
    );
  }

  static void error(
    String scope,
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? details,
  }) {
    final buffer = StringBuffer(
      _buildMessage(scope, message, details: details),
    );
    if (error != null) {
      buffer.write('\nerror: $error');
    }
    if (stackTrace != null) {
      buffer.write('\nstack: $stackTrace');
    }

    colored.log(
      buffer.toString(),
      type: colored.LogType.error,
      color: colored.LogColor.red,
    );
  }

  static AppLogTimer startTimer(
    String scope,
    String action, {
    Map<String, Object?>? details,
  }) {
    info(scope, '$action started', details: details);
    return AppLogTimer._(scope: scope, action: action, details: details);
  }

  static String _buildMessage(
    String scope,
    String message, {
    Map<String, Object?>? details,
  }) {
    final timestamp = DateTime.now().toLocal().toIso8601String();
    final detailText = _formatDetails(details);
    if (detailText == null) {
      return '[$timestamp] [$scope] $message';
    }

    return '[$timestamp] [$scope] $message | $detailText';
  }

  static String? _formatDetails(Map<String, Object?>? details) {
    if (details == null || details.isEmpty) {
      return null;
    }

    final values = <String>[];
    details.forEach((key, value) {
      if (value == null) {
        return;
      }
      values.add('$key=$value');
    });

    return values.isEmpty ? null : values.join(', ');
  }
}

class AppLogTimer {
  AppLogTimer._({required this.scope, required this.action, this.details})
    : _stopwatch = Stopwatch()..start();

  final String scope;
  final String action;
  final Map<String, Object?>? details;
  final Stopwatch _stopwatch;

  void success(String message, {Map<String, Object?>? details}) {
    _stopwatch.stop();
    AppLogger.success(
      scope,
      '$action success: $message',
      details: _mergeDetails(details),
    );
  }

  void warning(String message, {Map<String, Object?>? details}) {
    _stopwatch.stop();
    AppLogger.warning(
      scope,
      '$action warning: $message',
      details: _mergeDetails(details),
    );
  }

  void fail(
    String message, {
    Object? error,
    StackTrace? stackTrace,
    Map<String, Object?>? details,
  }) {
    _stopwatch.stop();
    AppLogger.error(
      scope,
      '$action failed: $message',
      error: error,
      stackTrace: stackTrace,
      details: _mergeDetails(details),
    );
  }

  Map<String, Object?> _mergeDetails(Map<String, Object?>? details) {
    return <String, Object?>{
      ...?this.details,
      ...?details,
      'elapsedMs': _stopwatch.elapsedMilliseconds,
    };
  }
}
