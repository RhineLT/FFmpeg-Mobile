import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import '../models/video_task.dart';
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

  List<VideoTask> get tasks => List.unmodifiable(_tasks);
  String? get outputDirectory => _outputDirectory;
  bool get isProcessing => _isProcessing;
  VideoTask? get currentTask => _currentTask;
  
  int get pendingCount => _tasks.where((t) => t.status == VideoStatus.pending).length;
  int get completedCount => _tasks.where((t) => t.status == VideoStatus.completed).length;
  int get failedCount => _tasks.where((t) => t.status == VideoStatus.failed).length;

  TaskManager({
    required this.logService,
    required this.storageService,
  }) {
    compressionService = VideoCompressionService(logService: logService);
    permissionService = PermissionService(logService: logService);
  }

  Future<void> init() async {
    // Load saved tasks
    _tasks.addAll(await storageService.loadTasks());
    
    // Load output directory
    _outputDirectory = await storageService.loadOutputDirectory();
    
    // If no output directory is set, use default
    if (_outputDirectory == null) {
      _outputDirectory = await _getDefaultOutputDirectory();
      if (_outputDirectory != null) {
        await storageService.saveOutputDirectory(_outputDirectory!);
      }
    }
    
    logService.info('Task manager initialized with ${_tasks.length} tasks');
    
    // Reset any tasks that were processing when app was closed
    for (var task in _tasks) {
      if (task.status == VideoStatus.processing) {
        task.status = VideoStatus.pending;
        task.progress = 0.0;
        task.sessionId = null;
        logService.info('Reset task ${task.fileName} to pending', taskId: task.id);
      }
    }
    
    await _saveTasks();
    notifyListeners();
  }

  Future<String?> _getDefaultOutputDirectory() async {
    try {
      if (Platform.isAndroid) {
        // For Android, use public Movies directory that's accessible via file manager
        // This is /storage/emulated/0/Movies/FFmpeg-Mobile/
        const publicPath = '/storage/emulated/0/Movies/FFmpeg-Mobile';
        final outputDir = Directory(publicPath);
        
        try {
          if (!await outputDir.exists()) {
            await outputDir.create(recursive: true);
            logService.info('Created public output directory: $publicPath');
          }
          return outputDir.path;
        } catch (e) {
          // If we can't create in public directory, fall back to external storage
          logService.warning('Cannot create public directory, using fallback: $e');
          final directory = await getExternalStorageDirectory();
          if (directory != null) {
            // Try to use a path closer to root
            final fallbackPath = directory.path.split('Android')[0];
            final outputDir = Directory('${fallbackPath}Movies/FFmpeg-Mobile');
            if (!await outputDir.exists()) {
              await outputDir.create(recursive: true);
            }
            return outputDir.path;
          }
        }
      } else if (Platform.isIOS) {
        // For iOS, use documents directory
        final directory = await getApplicationDocumentsDirectory();
        final outputDir = Directory('${directory.path}/CompressedVideos');
        if (!await outputDir.exists()) {
          await outputDir.create(recursive: true);
        }
        return outputDir.path;
      }
    } catch (e) {
      logService.error('Failed to get default output directory', error: e);
    }
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
            final outputFileName = compressionService.getOutputFileName(fileName);
            final outputPath = path.join(_outputDirectory!, outputFileName);

            // Get file size
            final fileSize = File(file.path!).lengthSync();

            final task = VideoTask(
              id: DateTime.now().millisecondsSinceEpoch.toString() + 
                  _tasks.length.toString(),
              inputPath: file.path!,
              outputPath: outputPath,
              fileName: fileName,
              fileSize: fileSize,
            );

            _tasks.add(task);
            logService.info('Added task: $fileName (${(fileSize / 1024 / 1024).toStringAsFixed(2)} MB)', taskId: task.id);
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
      final nextTask = _tasks.firstWhere(
        (task) => task.status == VideoStatus.pending,
        orElse: () => VideoTask(
          id: '',
          inputPath: '',
          outputPath: '',
          fileName: '',
          fileSize: 0,
        ),
      );

      if (nextTask.id.isEmpty) {
        // No more pending tasks
        break;
      }

      _currentTask = nextTask;
      notifyListeners();

      // Process the task
      await compressionService.compressVideo(
        task: nextTask,
        onProgress: (progress) {
          final index = _tasks.indexWhere((t) => t.id == nextTask.id);
          if (index != -1) {
            _tasks[index] = _tasks[index].copyWith(progress: progress);
            notifyListeners();
          }
        },
        onStatusChange: (updatedTask) {
          final index = _tasks.indexWhere((t) => t.id == updatedTask.id);
          if (index != -1) {
            _tasks[index] = updatedTask;
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
      
      logService.info('Retrying task: ${_tasks[index].fileName}', taskId: taskId);
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
    await storageService.saveTasks(_tasks);
  }
}
