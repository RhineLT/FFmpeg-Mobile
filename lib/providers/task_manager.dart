import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/video_task.dart';
import '../models/compression_settings.dart';
import '../services/log_service.dart';
import '../services/storage_service.dart';
import '../services/video_compression_service.dart';
import '../services/permission_service.dart';

class TaskManager extends ChangeNotifier {
  final LogService logService;
  final StorageService storageService;
  late final VideoCompressionService compressionService;
  late final PermissionService permissionService;

  final List<VideoTask> _tasks = [];
  String? _outputDirectory;
  bool _isProcessing = false;
  VideoTask? _currentTask;
  CompressionSettings _compressionSettings = CompressionSettings();
  bool _initialized = false;

  List<VideoTask> get tasks => List.unmodifiable(_tasks);
  String? get outputDirectory => _outputDirectory;
  bool get isProcessing => _isProcessing;
  VideoTask? get currentTask => _currentTask;
  CompressionSettings get compressionSettings => _compressionSettings;
  bool get initialized => _initialized;

  int get pendingCount =>
      _tasks.where((t) => t.status == VideoStatus.pending).length;
  int get completedCount =>
      _tasks.where((t) => t.status == VideoStatus.completed).length;
  int get failedCount =>
      _tasks.where((t) => t.status == VideoStatus.failed).length;

  void updateCompressionSettings(CompressionSettings settings) {
    _compressionSettings = settings;
    storageService.saveCompressionSettings(settings);
    logService.info('Compression settings updated: ${settings.commandPreview}');
    notifyListeners();
  }

  TaskManager({required this.logService, required this.storageService}) {
    compressionService = VideoCompressionService(logService: logService);
    permissionService = PermissionService(logService: logService);
  }

  Future<void> init() async {
    if (_initialized) {
      logService.info('TaskManager already initialized');
      return;
    }

    try {
      // Load saved tasks
      logService.info('Loading saved tasks...');
      final savedTasks = await storageService.loadTasks();
      _tasks.addAll(savedTasks);
      logService.info('Loaded ${savedTasks.length} saved tasks');

      // Load compression settings
      logService.info('Loading compression settings...');
      _compressionSettings = await storageService.loadCompressionSettings();
      logService.info('Compression settings loaded: ${_compressionSettings.commandPreview}');

      // Load output directory
      logService.info('Loading output directory...');
      _outputDirectory = await storageService.loadOutputDirectory();
      if (_outputDirectory != null) {
        logService.info('Loaded output directory: $_outputDirectory');
      }

      // If no output directory is set, use default
      if (_outputDirectory == null) {
        logService.info('No saved output directory, getting default...');
        _outputDirectory = await _getDefaultOutputDirectory();
        if (_outputDirectory != null) {
          logService.info('Default output directory set: $_outputDirectory');
          await storageService.saveOutputDirectory(_outputDirectory!);
        } else {
          logService.warning('Failed to resolve default output directory - will need to set manually');
        }
      }

      // Reset any tasks that were processing when app was closed
      int resetCount = 0;
      for (var task in _tasks) {
        if (task.status == VideoStatus.processing) {
          task.status = VideoStatus.pending;
          task.progress = 0.0;
          task.sessionId = null;
          resetCount++;
          logService.info(
            'Reset task ${task.fileName} to pending',
            taskId: task.id,
          );
        }
      }
      if (resetCount > 0) {
        logService.info('Reset $resetCount processing tasks to pending');
      }

      _initialized = true;
      await _saveTasks();
      
      logService.info('Task manager initialized successfully with ${_tasks.length} tasks');
      
      notifyListeners();
    } catch (e, stackTrace) {
      logService.error('Failed to initialize TaskManager: $e\nStackTrace: $stackTrace', error: e);
      _initialized = true; // Mark as initialized anyway to allow app to continue
      notifyListeners();
      rethrow;
    }
  }

  Future<String?> _getDefaultOutputDirectory() async {
    try {
      logService.info('Getting default output directory...');
      
      if (Platform.isAndroid) {
        // Try app-specific external storage directory first
        try {
          final externalDir = await getExternalStorageDirectory();
          if (externalDir != null) {
            logService.info('External storage directory: ${externalDir.path}');
            final outputDir = Directory(
              path.join(externalDir.path, 'Movies', 'FFmpeg-Mobile'),
            );
            if (!await outputDir.exists()) {
              await outputDir.create(recursive: true);
              logService.info('Created output directory: ${outputDir.path}');
            }
            logService.info('Using external storage output directory: ${outputDir.path}');
            return outputDir.path;
          }
        } catch (e) {
          logService.warning('Failed to access external storage: $e');
        }

        // Fallback to documents directory
        try {
          final docsDir = await getApplicationDocumentsDirectory();
          logService.info('Documents directory: ${docsDir.path}');
          final internalDir = Directory(
            path.join(docsDir.path, 'Movies', 'FFmpeg-Mobile'),
          );
          if (!await internalDir.exists()) {
            await internalDir.create(recursive: true);
            logService.info('Created internal output directory: ${internalDir.path}');
          }
          logService.info('Using internal storage output directory: ${internalDir.path}');
          return internalDir.path;
        } catch (e) {
          logService.error('Failed to access documents directory: $e', error: e);
        }
      } else if (Platform.isIOS) {
        // For iOS, use documents directory
        try {
          final directory = await getApplicationDocumentsDirectory();
          final outputDir = Directory('${directory.path}/CompressedVideos');
          if (!await outputDir.exists()) {
            await outputDir.create(recursive: true);
          }
          logService.info('Using iOS output directory: ${outputDir.path}');
          return outputDir.path;
        } catch (e) {
          logService.error('Failed to get iOS output directory: $e', error: e);
        }
      }
    } catch (e, stackTrace) {
      logService.error('Failed to get default output directory: $e\nStackTrace: $stackTrace', error: e);
    }
    
    logService.error('Could not resolve any output directory');
    return null;
  }

  Future<void> selectOutputDirectory() async {
    try {
      final result = await FilePicker.platform.getDirectoryPath();
      if (result != null) {
        _outputDirectory = result;
        await storageService.saveOutputDirectory(result);
        logService.info('Output directory set to: $result');
        notifyListeners();
      }
    } catch (e) {
      logService.error('Failed to select output directory', error: e);
    }
  }

  Future<void> pickVideos() async {
    try {
      // Check and request permissions first
      final hasPermission = await permissionService.hasStoragePermissions();
      if (!hasPermission) {
        final granted = await permissionService.requestStoragePermissions();
        if (!granted) {
          logService.error('Storage permission denied');
          return;
        }
      }

      final result = await FilePicker.platform.pickFiles(
        type: FileType.video,
        allowMultiple: true,
      );

      if (result != null && result.files.isNotEmpty) {
        if (_outputDirectory == null) {
          logService.error('No output directory set');
          return;
        }

        for (final file in result.files) {
          if (file.path != null) {
            final fileName = path.basename(file.path!);
            final outputFileName = compressionService.getOutputFileName(
              fileName,
              _compressionSettings.crf,
              _outputDirectory!,
            );
            final outputPath = path.join(_outputDirectory!, outputFileName);

            // Get file size
            final fileSize = File(file.path!).lengthSync();

            final task = VideoTask(
              id:
                  DateTime.now().millisecondsSinceEpoch.toString() +
                  _tasks.length.toString(),
              inputPath: file.path!,
              outputPath: outputPath,
              fileName: fileName,
              fileSize: fileSize,
            );

            _tasks.add(task);
            logService.info(
              'Added task: $fileName (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)',
              taskId: task.id,
            );
          }
        }

        await _saveTasks();
        notifyListeners();

        logService.info('Added ${result.files.length} video(s) to queue');
      }
    } catch (e) {
      logService.error('Failed to pick videos', error: e);
    }
  }

  Future<void> startProcessing() async {
    if (_isProcessing) {
      logService.warning('Already processing');
      return;
    }

    if (_outputDirectory == null) {
      logService.error('No output directory set');
      return;
    }

    _isProcessing = true;
    notifyListeners();

    logService.info('Started processing queue');

    while (true) {
      // Find next pending task
      final nextIndex = _tasks.indexWhere(
        (task) => task.status == VideoStatus.pending,
      );
      if (nextIndex == -1) {
        // No more pending tasks
        break;
      }

      final nextTask = _tasks[nextIndex];

      _currentTask = nextTask;
      notifyListeners();

      // Process the task
      await compressionService.compressVideo(
        task: nextTask,
        settings: _compressionSettings,
        onProgress: (progress) {
          final index = _tasks.indexWhere((t) => t.id == nextTask.id);
          if (index != -1) {
            _tasks[index] = _tasks[index].copyWith(progress: progress);
            if (_currentTask?.id == nextTask.id) {
              _currentTask = _tasks[index];
            }
            notifyListeners();
          }
        },
        onStatusChange: (updatedTask) {
          final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
          if (index != -1) {
            _tasks[index] = updatedTask;
            if (_currentTask?.id == updatedTask.id) {
              _currentTask = updatedTask;
            }
            _saveTasks();
            notifyListeners();
          }
        },
      );

      // Wait a bit before next task
      await Future.delayed(const Duration(milliseconds: 500));
    }

    _isProcessing = false;
    _currentTask = null;
    notifyListeners();

    logService.info('Processing queue completed');
  }

  Future<void> pauseProcessing() async {
    if (!_isProcessing) return;

    if (_currentTask?.sessionId != null) {
      await compressionService.cancelCompression(_currentTask!.sessionId!);

      final index = _tasks.indexWhere((t) => t.id == _currentTask!.id);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(
          status: VideoStatus.pending,
          progress: 0.0,
          sessionId: null,
        );
      }
    }

    _isProcessing = false;
    _currentTask = null;
    await _saveTasks();
    notifyListeners();

    logService.info('Processing paused');
  }

  Future<void> removeTask(String taskId) async {
    final task = _tasks.firstWhere((t) => t.id == taskId);

    if (task.status == VideoStatus.processing && task.sessionId != null) {
      await compressionService.cancelCompression(task.sessionId!);
    }

    _tasks.removeWhere((t) => t.id == taskId);
    await _saveTasks();
    notifyListeners();

    logService.info('Removed task: ${task.fileName}', taskId: taskId);
  }

  Future<void> retryTask(String taskId) async {
    final index = _tasks.indexWhere((t) => t.id == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(
        status: VideoStatus.pending,
        progress: 0.0,
        errorMessage: null,
        sessionId: null,
      );
      await _saveTasks();
      notifyListeners();

      logService.info(
        'Retrying task: ${_tasks[index].fileName}',
        taskId: taskId,
      );
    }
  }

  Future<void> clearCompleted() async {
    _tasks.removeWhere((t) => t.status == VideoStatus.completed);
    await _saveTasks();
    notifyListeners();

    logService.info('Cleared completed tasks');
  }

  Future<void> clearAll() async {
    // Cancel all processing tasks
    await compressionService.cancelAllSessions();

    _tasks.clear();
    _isProcessing = false;
    _currentTask = null;
    await _saveTasks();
    notifyListeners();

    logService.info('Cleared all tasks');
  }

  Future<void> _saveTasks() async {
    if (!_initialized) {
      return;
    }
    await storageService.saveTasks(_tasks);
  }
}
