import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:logger/logger.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/log_entry.dart';

class LogService extends ChangeNotifier {
  final Logger _logger = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 80,
      colors: true,
      printEmojis: true,
    ),
  );

  final List<LogEntry> _logs = [];
  static const int _maxLogs = 1000;
  static const String _logsKey = 'app_logs';

  SharedPreferences? _prefs;
  bool _initialized = false;

  List<LogEntry> get logs => List.unmodifiable(_logs);

  Future<void> init() async {
    if (_initialized) return;

    try {
      debugPrint('LogService: Initializing SharedPreferences...');
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      debugPrint('LogService: SharedPreferences initialized');

      await _loadLogs();
      debugPrint('LogService: Loaded ${_logs.length} log entries');
    } catch (e, stackTrace) {
      debugPrint('LogService: Failed to initialize: $e');
      debugPrint('LogService: StackTrace: $stackTrace');
      // Don't rethrow - logging is not critical, app can work without it
      _initialized = true; // Mark as initialized to allow app to continue
    }
  }

  SharedPreferences? get _prefsInstance => _prefs;

  void info(String message, {String? taskId}) {
    _logger.i(message);
    _addLog('INFO', message, taskId: taskId);
  }

  void warning(String message, {String? taskId}) {
    _logger.w(message);
    _addLog('WARNING', message, taskId: taskId);
  }

  void error(
    String message, {
    String? taskId,
    Object? error,
    StackTrace? stackTrace,
  }) {
    _logger.e(message, error: error, stackTrace: stackTrace);

    var details = message;
    if (error != null) {
      details += '\nError: $error';
    }
    if (stackTrace != null) {
      details += '\nStackTrace: $stackTrace';
    }

    _addLog('ERROR', details, taskId: taskId);
  }

  void debug(String message, {String? taskId}) {
    _logger.d(message);
    _addLog('DEBUG', message, taskId: taskId);
  }

  void _addLog(String level, String message, {String? taskId}) {
    final entry = LogEntry(
      timestamp: DateTime.now(),
      level: level,
      message: message,
      taskId: taskId,
    );

    _logs.insert(0, entry);

    // Keep only the latest logs
    if (_logs.length > _maxLogs) {
      _logs.removeRange(_maxLogs, _logs.length);
    }

    notifyListeners();
    _saveLogs();
  }

  Future<void> _saveLogs() async {
    try {
      if (_prefsInstance == null) {
        debugPrint(
          'LogService: Cannot save logs - SharedPreferences not initialized',
        );
        return;
      }

      final logsJson = _logs.map((log) => log.toJson()).toList();
      await _prefsInstance!.setString(_logsKey, jsonEncode(logsJson));
    } catch (e) {
      _logger.e('Failed to save logs', error: e);
      debugPrint('LogService: Failed to save logs: $e');
    }
  }

  Future<void> _loadLogs() async {
    try {
      if (_prefsInstance == null) {
        debugPrint(
          'LogService: Cannot load logs - SharedPreferences not initialized',
        );
        return;
      }

      final logsString = _prefsInstance!.getString(_logsKey);
      if (logsString != null) {
        final logsJson = jsonDecode(logsString) as List;
        _logs.clear();
        _logs.addAll(logsJson.map((json) => LogEntry.fromJson(json)));
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Failed to load logs', error: e);
      debugPrint('LogService: Failed to load logs: $e');
    }
  }

  Future<void> clearLogs() async {
    _logs.clear();
    notifyListeners();

    try {
      if (_prefsInstance != null) {
        await _prefsInstance!.remove(_logsKey);
      }
      info('Logs cleared');
    } catch (e) {
      _logger.e('Failed to clear logs', error: e);
      debugPrint('LogService: Failed to clear logs: $e');
    }
  }

  List<LogEntry> getLogsForTask(String taskId) {
    return _logs.where((log) => log.taskId == taskId).toList();
  }
}
