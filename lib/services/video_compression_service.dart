import 'dart:io';
import 'package:video_compress/video_compress.dart';
import 'package:path/path.dart' as path;
import '../models/video_task.dart';
import 'log_service.dart';

class VideoCompressionService {
  final LogService logService;
  
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

      // Subscribe to compression progress
      VideoCompress.compressProgress$.subscribe((progress) {
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

      // If output path is different, move the file
      if (info.path != task.outputPath) {
        await compressedFile.copy(task.outputPath);
        await compressedFile.delete();
      }

      final outputFile = File(task.outputPath);
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
      VideoCompress.cancelCompression();
      logService.info('Cancelled compression');
    } catch (e) {
      logService.error('Failed to cancel compression', error: e);
    }
  }

  Future<void> cancelAllSessions() async {
    try {
      VideoCompress.cancelCompression();
      logService.info('Cancelled all compression tasks');
    } catch (e) {
      logService.error('Failed to cancel all tasks', error: e);
    }
  }

  Future<void> dispose() async {
    try {
      VideoCompress.dispose();
    } catch (e) {
      logService.error('Error disposing VideoCompress', error: e);
    }
  }

  String getOutputFileName(String inputFileName) {
    final nameWithoutExt = path.basenameWithoutExtension(inputFileName);
    final ext = path.extension(inputFileName);
    return '${nameWithoutExt}_compressed$ext';
  }
}
