import 'dart:io';
import 'package:video_compress/video_compress.dart';
import 'package:path/path.dart' as path;
import '../models/video_task.dart';
import '../models/compression_settings.dart';
import 'log_service.dart';

class VideoCompressionService {
  final LogService logService;
  dynamic _progressSubscription;
  
  VideoCompressionService({required this.logService});

  Future<void> compressVideo({
    required VideoTask task,
    required CompressionSettings settings,
    required Function(double progress) onProgress,
    required Function(VideoTask updatedTask) onStatusChange,
  }) async {
    try {
      logService.info('Starting compression for ${task.fileName}', taskId: task.id);
      
      // 读取原始视频信息
      final mediaInfo = await VideoCompress.getMediaInfo(task.inputPath);
      logService.info(
        'Video info - Resolution: ${mediaInfo.width}x${mediaInfo.height}, '
        'Duration: ${mediaInfo.duration?.toStringAsFixed(1)}s, '
        'Bitrate: ${(mediaInfo.filesize! / (mediaInfo.duration ?? 1) / 1024).toStringAsFixed(0)} KB/s',
        taskId: task.id,
      );
      
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

      // 根据设置确定输出分辨率
      // 注意: video_compress 库不支持直接设置分辨率,分辨率由 VideoQuality 控制
      // 这里仅记录用户设置,实际输出分辨率可能与设置不完全一致
      if (settings.resolution != 'original') {
        final parts = settings.resolution.split('x');
        if (parts.length == 2) {
          final targetWidth = int.tryParse(parts[0]);
          final targetHeight = int.tryParse(parts[1]);
          logService.warning(
            'Target resolution: ${targetWidth}x$targetHeight\n'
            'Note: video_compress library does not support custom resolution.\n'
            'Output resolution is controlled by VideoQuality setting.',
            taskId: task.id
          );
        }
      } else {
        logService.info('Using original resolution: ${mediaInfo.width?.toInt()}x${mediaInfo.height?.toInt()}', taskId: task.id);
      }

      // 根据设置确定输出帧率
      int outputFrameRate = 30; // 默认 30fps
      if (settings.frameRate > 0) {
        outputFrameRate = settings.frameRate;
        logService.info('Target frame rate: $outputFrameRate fps', taskId: task.id);
      } else {
        // 使用原始帧率,但需要从视频信息中获取
        // video_compress 要求帧率参数,如果原始信息中没有,使用30fps
        logService.info('Using original frame rate: ~30 fps (video_compress default)', taskId: task.id);
      }

      logService.info('Starting video compression with settings: CRF=${settings.crf}, Preset=${settings.preset}, FrameRate=${outputFrameRate}fps', taskId: task.id);

      // Compress video
      // video_compress uses MediaCodec on Android and AVAssetExportSession on iOS
      final info = await VideoCompress.compressVideo(
        task.inputPath,
        quality: VideoQuality.DefaultQuality,
        deleteOrigin: false,
        includeAudio: true,
        frameRate: outputFrameRate,
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
