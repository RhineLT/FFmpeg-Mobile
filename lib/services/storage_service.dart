import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../models/video_task.dart';

class StorageService {
  static const String _tasksKey = 'video_tasks';
  static const String _outputDirKey = 'output_directory';

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

  Future<void> clearAllData() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
