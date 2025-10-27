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

  List<LogEntry> get logs => List.unmodifiable(_logs);

  Future<void> init() async {
    await _loadLogs();
  }

  void info(String message, {String? taskId}) {
    _logger.i(message);
    _addLog('INFO', message, taskId: taskId);
  }

  void warning(String message, {String? taskId}) {
    _logger.w(message);
    _addLog('WARNING', message, taskId: taskId);
  }

  void error(String message, {String? taskId, Object? error}) {
    _logger.e(message, error: error);
    _addLog('ERROR', message, taskId: taskId);
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
      final prefs = await SharedPreferences.getInstance();
      final logsJson = _logs.map((log) => log.toJson()).toList();
      await prefs.setString(_logsKey, jsonEncode(logsJson));
    } catch (e) {
      _logger.e('Failed to save logs', error: e);
    }
  }

  Future<void> _loadLogs() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final logsString = prefs.getString(_logsKey);
      if (logsString != null) {
        final logsJson = jsonDecode(logsString) as List;
        _logs.clear();
        _logs.addAll(logsJson.map((json) => LogEntry.fromJson(json)));
        notifyListeners();
      }
    } catch (e) {
      _logger.e('Failed to load logs', error: e);
    }
  }

  Future<void> clearLogs() async {
    _logs.clear();
    notifyListeners();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_logsKey);
    info('Logs cleared');
  }

  List<LogEntry> getLogsForTask(String taskId) {
    return _logs.where((log) => log.taskId == taskId).toList();
  }
}
