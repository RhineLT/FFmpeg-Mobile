import 'dart:io';
import 'package:flutter_ffmpeg/flutter_ffmpeg.dart';
import 'package:path/path.dart' as path;
import '../models/video_task.dart';
import '../models/compression_settings.dart';
import 'log_service.dart';

class VideoCompressionService {
  final LogService logService;
  final FlutterFFmpeg _flutterFFmpeg = FlutterFFmpeg();
  final FlutterFFmpegConfig _flutterFFmpegConfig = FlutterFFmpegConfig();
  final FlutterFFprobe _flutterFFprobe = FlutterFFprobe();
  int? _currentExecutionId;
  
  VideoCompressionService({required this.logService});

  Future<void> compressVideo({
    required VideoTask task,
    required CompressionSettings settings,
    required Function(double progress) onProgress,
    required Function(VideoTask updatedTask) onStatusChange,
  }) async {
    try {
      logService.info('Starting compression for ${task.fileName}', taskId: task.id);
      
      // Update status to processing
      final processingTask = task.copyWith(
        status: VideoStatus.processing,
        startedAt: DateTime.now(),
      );
      onStatusChange(processingTask);

      // Ensure output directory exists
      final outputDir = Directory(path.dirname(task.outputPath));
      if (!await outputDir.exists()) {
        await outputDir.create(recursive: true);
        logService.info('Created output directory: ${outputDir.path}', taskId: task.id);
      }

      // Check if output file already exists and adjust name if needed
      String finalOutputPath = task.outputPath;
      if (await File(finalOutputPath).exists()) {
        final dir = path.dirname(finalOutputPath);
        final fileName = path.basename(finalOutputPath);
        final nameWithoutExt = path.basenameWithoutExtension(fileName);
        final ext = path.extension(fileName);
        
        int suffix = 1;
        while (await File(finalOutputPath).exists()) {
          finalOutputPath = path.join(dir, '${nameWithoutExt}_$suffix$ext');
          suffix++;
        }
        
        logService.info('Output file exists, using: ${path.basename(finalOutputPath)}', taskId: task.id);
      }

      // Build FFmpeg command
      List<String> command = [];
      
      // Hardware acceleration
      if (settings.useHardwareAccel) {
        command.addAll(['-hwaccel', 'auto']);
      }
      
      // Input file
      command.addAll(['-i', task.inputPath]);
      
      // Video codec - H.265
      command.addAll(['-c:v', 'libx265']);
      
      // CRF setting
      command.addAll(['-crf', settings.crf.toString()]);
      
      // Preset
      command.addAll(['-preset', settings.preset]);
      
      // Bitrate limit
      if (settings.maxBitrate > 0) {
        command.addAll([
          '-maxrate', '${settings.maxBitrate}k',
          '-bufsize', '${settings.maxBitrate * 2}k',
        ]);
      }
      
      // Resolution
      if (settings.resolution != 'original') {
        command.addAll(['-s', settings.resolution]);
      }
      
      // Frame rate
      if (settings.frameRate > 0) {
        command.addAll(['-r', settings.frameRate.toString()]);
      }
      
      // Audio codec
      command.addAll(['-c:a', 'aac', '-b:a', '128k']);
      
      // Custom parameters
      if (settings.customParams.isNotEmpty) {
        command.addAll(settings.customParams.split(' '));
      }
      
      // Overwrite output file
      command.add('-y');
      
      // Output file
      command.add(finalOutputPath);

      final commandStr = command.join(' ');
      logService.info('FFmpeg command: $commandStr', taskId: task.id);

      // Get video duration for accurate progress tracking
      final videoDuration = await getVideoDuration(task.inputPath);
      logService.info('Video duration: ${videoDuration}ms', taskId: task.id);

      // Enable statistics callback for progress tracking
      _flutterFFmpegConfig.enableStatisticsCallback((statistics) {
        final time = statistics.time;
        if (time > 0 && videoDuration != null && videoDuration > 0) {
          // Calculate progress based on time processed vs total duration
          final progress = (time / videoDuration).clamp(0.0, 0.99);
          onProgress(progress);
          
          if (time % 5000 < 100) { // Log every ~5 seconds
            logService.debug(
              'Progress: ${(progress * 100).toStringAsFixed(1)}% '
              '(${time}ms / ${videoDuration}ms)',
              taskId: task.id,
            );
          }
        }
      });

      // Execute FFmpeg command
      final returnCode = await _flutterFFmpeg.executeWithArguments(command);
      _currentExecutionId = returnCode;

      if (returnCode != 0) {
        throw Exception('FFmpeg execution failed with return code: $returnCode');
      }

      final outputFile = File(finalOutputPath);
      if (!await outputFile.exists()) {
        throw Exception('Output file not created: $finalOutputPath');
      }

      final outputSize = await outputFile.length();
      
      logService.info(
        'Compression completed: ${task.fileName}\n'
        'Original size: ${(task.fileSize / 1024 / 1024).toStringAsFixed(2)} MB\n'
        'Compressed size: ${(outputSize / 1024 / 1024).toStringAsFixed(2)} MB\n'
        'Compression ratio: ${((1 - outputSize / task.fileSize) * 100).toStringAsFixed(1)}%',
        taskId: task.id,
      );

      final completedTask = processingTask.copyWith(
        status: VideoStatus.completed,
        progress: 1.0,
        completedAt: DateTime.now(),
      );
      onStatusChange(completedTask);

    } catch (e) {
      logService.error(
        'Exception during compression for ${task.fileName}', 
        taskId: task.id, 
        error: e,
      );
      
      // Clean up incomplete output file
      final outputFile = File(task.outputPath);
      if (await outputFile.exists()) {
        await outputFile.delete();
        logService.debug('Deleted incomplete output file', taskId: task.id);
      }
      
      final failedTask = task.copyWith(
        status: VideoStatus.failed,
        errorMessage: e.toString(),
      );
      onStatusChange(failedTask);
    } finally {
      // Disable statistics callback
      _flutterFFmpegConfig.enableStatisticsCallback(null);
      _currentExecutionId = null;
    }
  }

  Future<void> cancelCompression(int sessionId) async {
    try {
      if (_currentExecutionId != null) {
        await _flutterFFmpeg.cancel();
        _currentExecutionId = null;
        logService.info('Cancelled compression session $sessionId');
      }
    } catch (e) {
      logService.error('Failed to cancel compression', error: e);
    }
  }

  Future<void> cancelAllSessions() async {
    try {
      await _flutterFFmpeg.cancel();
      _currentExecutionId = null;
      logService.info('Cancelled all compression tasks');
    } catch (e) {
      logService.error('Failed to cancel all tasks', error: e);
    }
  }

  Future<void> dispose() async {
    try {
      await _flutterFFmpeg.cancel();
      _flutterFFmpegConfig.enableStatisticsCallback(null);
      _currentExecutionId = null;
      logService.info('VideoCompressionService disposed');
    } catch (e) {
      logService.error('Error disposing VideoCompressionService', error: e);
    }
  }

  /// Get video duration in milliseconds using FFprobe
  Future<int?> getVideoDuration(String videoPath) async {
    try {
      final info = await _flutterFFprobe.getMediaInformation(videoPath);
      final duration = info.getMediaProperties()?['duration'];
      if (duration != null) {
        return (double.parse(duration.toString()) * 1000).toInt();
      }
    } catch (e) {
      logService.error('Failed to get video duration', error: e);
    }
    return null;
  }

  String getOutputFileName(String inputFileName, int crf, String outputDir) {
    final nameWithoutExt = path.basenameWithoutExtension(inputFileName);
    final ext = path.extension(inputFileName);
    
    // 生成基础文件名: 原名_batch{crf}.扩展名
    String baseFileName = '${nameWithoutExt}_batch$crf$ext';
    String outputPath = path.join(outputDir, baseFileName);
    
    // 检查文件是否已存在，如果存在则添加编号后缀
    int suffix = 1;
    while (File(outputPath).existsSync()) {
      baseFileName = '${nameWithoutExt}_batch${crf}_$suffix$ext';
      outputPath = path.join(outputDir, baseFileName);
      suffix++;
    }
    
    return baseFileName;
  }
}
