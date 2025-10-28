import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/video_task.dart';
import '../models/compression_settings.dart';

class StorageService {
  static const String _tasksKey = 'video_tasks';
  static const String _outputDirKey = 'output_directory';
  static const String _compressionSettingsKey = 'compression_settings';

  Future<void> saveTasks(List<VideoTask> tasks) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksJson = tasks.map((task) => task.toJson()).toList();
      await prefs.setString(_tasksKey, jsonEncode(tasksJson));
    } catch (e) {
      debugPrint('Failed to save tasks: $e');
    }
  }

  Future<List<VideoTask>> loadTasks() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final tasksString = prefs.getString(_tasksKey);
      if (tasksString != null) {
        final tasksJson = jsonDecode(tasksString) as List;
        return tasksJson.map((json) => VideoTask.fromJson(json)).toList();
      }
    } catch (e) {
      debugPrint('Failed to load tasks: $e');
    }
    return [];
  }

  Future<void> saveOutputDirectory(String path) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_outputDirKey, path);
  }

  Future<String?> loadOutputDirectory() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_outputDirKey);
  }

  Future<void> saveCompressionSettings(CompressionSettings settings) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_compressionSettingsKey, jsonEncode(settings.toJson()));
    } catch (e) {
      debugPrint('Failed to save compression settings: $e');
    }
  }

  Future<CompressionSettings> loadCompressionSettings() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final settingsString = prefs.getString(_compressionSettingsKey);
      if (settingsString != null) {
        final json = jsonDecode(settingsString);
        return CompressionSettings.fromJson(json);
      }
    } catch (e) {
      debugPrint('Failed to load compression settings: $e');
    }
    return CompressionSettings();
  }

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
