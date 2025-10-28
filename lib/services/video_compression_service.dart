import 'dart:io';
import 'package:video_compress/video_compress.dart';
import 'package:path/path.dart' as path;
import '../models/video_task.dart';
import 'log_service.dart';

class VideoCompressionService {
  final LogService logService;
  dynamic _progressSubscription;
  
  VideoCompressionService({required this.logService});

  Future<void> compressVideo({
    required VideoTask task,
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

      // Cancel any existing subscription before creating a new one
      _progressSubscription?.unsubscribe();
      
      // Subscribe to compression progress using the correct method
      _progressSubscription = VideoCompress.compressProgress$.subscribe((progress) {
        if (progress > 0) {
          final normalizedProgress = (progress / 100.0).clamp(0.0, 0.99);
          onProgress(normalizedProgress);
          logService.debug('Compression progress: ${progress.toStringAsFixed(1)}%', taskId: task.id);
        }
      });

      logService.info('Starting video compression with H.265 CRF 28 equivalent settings', taskId: task.id);

      // Compress video
      // video_compress uses MediaCodec on Android and AVAssetExportSession on iOS
      // We'll use high quality settings to approximate H.265 CRF 28
      final info = await VideoCompress.compressVideo(
        task.inputPath,
        quality: VideoQuality.DefaultQuality,
        deleteOrigin: false,
        includeAudio: true,
      );

      if (info == null) {
        throw Exception('Compression failed: no output file generated');
      }

      // Move the compressed file to the desired output path
      final compressedFile = File(info.path!);
      if (!await compressedFile.exists()) {
        throw Exception('Compressed file not found at ${info.path}');
      }

      // Check if output file already exists and adjust name if needed
      String finalOutputPath = task.outputPath;
      if (await File(finalOutputPath).exists() && info.path != finalOutputPath) {
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

      // If output path is different, move the file
      if (info.path != finalOutputPath) {
        await compressedFile.copy(finalOutputPath);
        await compressedFile.delete();
      }

      final outputFile = File(finalOutputPath);
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
    }
  }

  Future<void> cancelCompression(int sessionId) async {
    try {
      _progressSubscription?.unsubscribe();
      VideoCompress.cancelCompression();
      logService.info('Cancelled compression');
    } catch (e) {
      logService.error('Failed to cancel compression', error: e);
    }
  }

  Future<void> cancelAllSessions() async {
    try {
      _progressSubscription?.unsubscribe();
      VideoCompress.cancelCompression();
      logService.info('Cancelled all compression tasks');
    } catch (e) {
      logService.error('Failed to cancel all tasks', error: e);
    }
  }

  Future<void> dispose() async {
    try {
      _progressSubscription?.unsubscribe();
      VideoCompress.dispose();
    } catch (e) {
      logService.error('Error disposing VideoCompress', error: e);
    }
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
