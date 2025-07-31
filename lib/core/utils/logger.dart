import 'package:logger/logger.dart';
import '../config/app_config.dart';

/// App Logger Utility
/// 
/// Provides centralized logging functionality with different log levels,
/// formatted output, and production-safe configuration.
class AppLogger {
  static final Logger _logger = Logger(
    filter: _LogFilter(),
    printer: _LogPrinter(),
    output: _LogOutput(),
  );

  /// Log debug message
  /// Only shown in debug mode
  static void debug(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.d(message, error, stackTrace);
  }

  /// Log info message
  static void info(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.i(message, error, stackTrace);
  }

  /// Log warning message
  static void warning(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.w(message, error, stackTrace);
  }

  /// Log error message
  static void error(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.e(message, error, stackTrace);
  }

  /// Log fatal/critical error
  static void fatal(String message, [dynamic error, StackTrace? stackTrace]) {
    _logger.f(message, error, stackTrace);
  }

  /// Log API request
  static void apiRequest(String method, String url, [Map<String, dynamic>? data]) {
    if (AppConfig.isDebug) {
      _logger.d('API Request: $method $url', data);
    }
  }

  /// Log API response
  static void apiResponse(String url, int statusCode, [dynamic data]) {
    if (AppConfig.isDebug) {
      _logger.d('API Response: $url - Status: $statusCode', data);
    }
  }

  /// Log navigation event
  static void navigation(String from, String to) {
    if (AppConfig.isDebug) {
      _logger.d('Navigation: $from -> $to');
    }
  }

  /// Log user action
  static void userAction(String action, [Map<String, dynamic>? data]) {
    _logger.i('User Action: $action', data);
  }

  /// Log performance metric
  static void performance(String operation, Duration duration) {
    _logger.i('Performance: $operation took ${duration.inMilliseconds}ms');
  }

  /// Log cache operation
  static void cache(String operation, String key, [bool success = true]) {
    if (AppConfig.isDebug) {
      _logger.d('Cache $operation: $key - ${success ? "Success" : "Failed"}');
    }
  }

  /// Log Firebase operation
  static void firebase(String operation, [dynamic data]) {
    if (AppConfig.isDebug) {
      _logger.d('Firebase $operation', data);
    }
  }
}

/// Custom log filter
/// Controls which logs are displayed based on app configuration
class _LogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    // In release mode, only show warnings and errors
    if (AppConfig.isRelease) {
      return event.level.index >= Level.warning.index;
    }
    // In debug mode, show all logs
    return true;
  }
}

/// Custom log printer
/// Formats log messages with timestamps and context
class _LogPrinter extends LogPrinter {
  static final _levelEmojis = {
    Level.verbose: '📝',
    Level.debug: '🐛',
    Level.info: 'ℹ️',
    Level.warning: '⚠️',
    Level.error: '❌',
    Level.wtf: '💥',
  };

  static final _levelColors = {
    Level.verbose: AnsiColor.fg(8),
    Level.debug: AnsiColor.fg(12),
    Level.info: AnsiColor.fg(10),
    Level.warning: AnsiColor.fg(208),
    Level.error: AnsiColor.fg(196),
    Level.wtf: AnsiColor.fg(199),
  };

  @override
  List<String> log(LogEvent event) {
    final color = _levelColors[event.level] ?? AnsiColor.none();
    final emoji = _levelEmojis[event.level] ?? '';
    final timestamp = DateTime.now().toIso8601String();
    
    final message = event.message;
    final error = event.error;
    final stackTrace = event.stackTrace;
    
    List<String> output = [];
    
    // Main log line
    output.add(color('$emoji [$timestamp] ${event.level.name.toUpperCase()}: $message'));
    
    // Error details
    if (error != null) {
      output.add(color('Error: $error'));
    }
    
    // Stack trace (only in debug mode and for errors)
    if (stackTrace != null && (AppConfig.isDebug || event.level.index >= Level.error.index)) {
      final trace = stackTrace.toString().split('\n');
      // Limit stack trace lines to prevent log spam
      final limitedTrace = trace.take(10);
      for (final line in limitedTrace) {
        output.add(color('  $line'));
      }
      if (trace.length > 10) {
        output.add(color('  ... ${trace.length - 10} more lines'));
      }
    }
    
    return output;
  }
}

/// Custom log output
/// Handles where logs are written (console, file, etc.)
class _LogOutput extends LogOutput {
  @override
  void output(OutputEvent event) {
    // In debug mode, print to console
    if (AppConfig.isDebug) {
      for (final line in event.lines) {
        // ignore: avoid_print
        print(line);
      }
    }
    
    // In production, you might want to send logs to a crash reporting service
    // like Firebase Crashlytics or Sentry
    if (AppConfig.isRelease && event.level.index >= Level.error.index) {
      _sendToErrorReporting(event);
    }
  }
  
  /// Send error logs to error reporting service
  void _sendToErrorReporting(OutputEvent event) {
    // TODO: Implement error reporting service integration
    // Example: FirebaseCrashlytics.instance.log(event.lines.join('\n'));
  }
}

/// ANSI color codes for console output
class AnsiColor {
  final int? fg;
  final int? bg;
  final bool color;

  AnsiColor.none()
      : fg = null,
        bg = null,
        color = false;

  AnsiColor.fg(this.fg)
      : bg = null,
        color = true;

  AnsiColor.bg(this.bg)
      : fg = null,
        color = true;

  @override
  String toString() {
    if (fg != null) {
      return '\x1b[38;5;${fg}m';
    } else if (bg != null) {
      return '\x1b[48;5;${bg}m';
    } else {
      return '';
    }
  }

  String call(String msg) {
    if (color) {
      return '${toString()}$msg\x1b[0m';
    } else {
      return msg;
    }
  }
}