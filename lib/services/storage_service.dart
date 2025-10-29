import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/video_task.dart';
import '../models/compression_settings.dart';

class StorageService {
  static const String _tasksKey = 'video_tasks';
  static const String _outputDirKey = 'output_directory';
  static const String _compressionSettingsKey = 'compression_settings';

  SharedPreferences? _prefs;
  bool _initialized = false;
  bool _useInMemoryStore = false;
  final Map<String, String> _memoryStore = {};

  /// Initialize the storage service
  Future<void> init() async {
    if (_initialized) return;

    try {
      debugPrint('StorageService: Initializing SharedPreferences...');
      _prefs = await SharedPreferences.getInstance();
      _initialized = true;
      debugPrint('StorageService: SharedPreferences initialized successfully');
    } catch (e, stackTrace) {
      debugPrint('StorageService: Failed to initialize SharedPreferences: $e');
      debugPrint('StorageService: StackTrace: $stackTrace');
      debugPrint('StorageService: Falling back to in-memory store');
      _useInMemoryStore = true;
      _initialized = true;
    }
  }

  SharedPreferences get _prefsInstance {
    if (_useInMemoryStore) {
      throw StateError('StorageService is using in-memory fallback storage.');
    }
    if (!_initialized || _prefs == null) {
      throw StateError('StorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  Future<void> saveTasks(List<VideoTask> tasks) async {
    try {
      final tasksJson = tasks.map((task) => task.toJson()).toList();
      final encoded = jsonEncode(tasksJson);
      if (_useInMemoryStore) {
        _memoryStore[_tasksKey] = encoded;
      } else {
        await _prefsInstance.setString(_tasksKey, encoded);
      }
      debugPrint('StorageService: Saved ${tasks.length} tasks');
    } catch (e) {
      debugPrint('StorageService: Failed to save tasks: $e');
      rethrow;
    }
  }

  Future<List<VideoTask>> loadTasks() async {
    try {
      final tasksString = _useInMemoryStore
          ? _memoryStore[_tasksKey]
          : _prefsInstance.getString(_tasksKey);
      if (tasksString != null) {
        final tasksJson = jsonDecode(tasksString) as List;
        final tasks = tasksJson
            .map((json) => VideoTask.fromJson(json))
            .toList();
        debugPrint('StorageService: Loaded ${tasks.length} tasks');
        return tasks;
      }
      debugPrint('StorageService: No saved tasks found');
    } catch (e) {
      debugPrint('StorageService: Failed to load tasks: $e');
    }
    return [];
  }

  Future<void> saveOutputDirectory(String path) async {
    try {
      if (_useInMemoryStore) {
        _memoryStore[_outputDirKey] = path;
      } else {
        await _prefsInstance.setString(_outputDirKey, path);
      }
      debugPrint('StorageService: Saved output directory: $path');
    } catch (e) {
      debugPrint('StorageService: Failed to save output directory: $e');
      rethrow;
    }
  }

  Future<String?> loadOutputDirectory() async {
    try {
      final path = _useInMemoryStore
          ? _memoryStore[_outputDirKey]
          : _prefsInstance.getString(_outputDirKey);
      debugPrint('StorageService: Loaded output directory: $path');
      return path;
    } catch (e) {
      debugPrint('StorageService: Failed to load output directory: $e');
      return null;
    }
  }

  Future<void> saveCompressionSettings(CompressionSettings settings) async {
    try {
      final encoded = jsonEncode(settings.toJson());
      if (_useInMemoryStore) {
        _memoryStore[_compressionSettingsKey] = encoded;
      } else {
        await _prefsInstance.setString(_compressionSettingsKey, encoded);
      }
      debugPrint('StorageService: Saved compression settings');
    } catch (e) {
      debugPrint('StorageService: Failed to save compression settings: $e');
    }
  }

  Future<CompressionSettings> loadCompressionSettings() async {
    try {
      final settingsString = _useInMemoryStore
          ? _memoryStore[_compressionSettingsKey]
          : _prefsInstance.getString(_compressionSettingsKey);
      if (settingsString != null) {
        final json = jsonDecode(settingsString);
        final settings = CompressionSettings.fromJson(json);
        debugPrint('StorageService: Loaded compression settings');
        return settings;
      }
      debugPrint(
        'StorageService: No saved compression settings found, using defaults',
      );
    } catch (e) {
      debugPrint('StorageService: Failed to load compression settings: $e');
    }
    return CompressionSettings();
  }

  Future<void> clearAllData() async {
    try {
      if (_useInMemoryStore) {
        _memoryStore.clear();
      } else {
        await _prefsInstance.clear();
      }
      debugPrint('StorageService: Cleared all data');
    } catch (e) {
      debugPrint('StorageService: Failed to clear data: $e');
      rethrow;
    }
  }
}
