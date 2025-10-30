import 'dart:io';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/ffprobe_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';
import 'package:path/path.dart' as path;
import '../models/video_task.dart';
import '../models/compression_settings.dart';
import 'log_service.dart';

class VideoCompressionService {
  final LogService logService;
  int? _currentSessionId;

  VideoCompressionService({required this.logService});

  Future<void> compressVideo({
    required VideoTask task,
    required CompressionSettings settings,
    required Function(double progress) onProgress,
    required Function(VideoTask updatedTask) onStatusChange,
  }) async {
    try {
      logService.info(
        'Starting compression for ${task.fileName}',
        taskId: task.id,
      );

      // 读取原始视频信息
      final mediaInfoSession = await FFprobeKit.getMediaInformation(
        task.inputPath,
      );
      final mediaInfo = mediaInfoSession.getMediaInformation();

      if (mediaInfo != null) {
        final properties = mediaInfo.getAllProperties();
        final format = properties?['format'] as Map?;

        String videoInfo = 'Video info:';
        if (format != null) {
          final duration = format['duration'];
          final bitrate = format['bit_rate'];
          final size = format['size'];
          videoInfo += '\n  Duration: ${duration}s';
          if (bitrate != null) {
            videoInfo +=
                '\n  Bitrate: ${(int.tryParse(bitrate.toString()) ?? 0) / 1000} kbps';
          }
          if (size != null) {
            videoInfo +=
                '\n  Size: ${(int.tryParse(size.toString()) ?? 0) / 1024 / 1024} MB';
          }
        }

        logService.info(videoInfo, taskId: task.id);
      }

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
        logService.info(
          'Created output directory: ${outputDir.path}',
          taskId: task.id,
        );
      }

      // 构建 FFmpeg 参数
      final commandArgs = _buildFFmpegArguments(
        inputPath: task.inputPath,
        outputPath: task.outputPath,
        settings: settings,
      );

      final commandString = _formatCommandForLog(commandArgs);
      logService.info(
        'FFmpeg command: ffmpeg $commandString',
        taskId: task.id,
      );

      // 验证输入文件存在
      final inputFile = File(task.inputPath);
      if (!await inputFile.exists()) {
        throw Exception('Input file does not exist: ${task.inputPath}');
      }
      logService.info(
        'Input file verified: ${task.inputPath} (${await inputFile.length()} bytes)',
        taskId: task.id,
      );

      // 验证输出目录存在
      final outputDir = Directory(path.dirname(task.outputPath));
      if (!await outputDir.exists()) {
        logService.warning(
          'Output directory does not exist, creating: ${outputDir.path}',
          taskId: task.id,
        );
        await outputDir.create(recursive: true);
      }
      logService.info(
        'Output path ready: ${task.outputPath}',
        taskId: task.id,
      );

      // 执行 FFmpeg 压缩
      final session = await FFmpegKit.executeWithArgumentsAsync(
        commandArgs,
        (session) async {
          final returnCode = await session.getReturnCode();
          if (ReturnCode.isSuccess(returnCode)) {
            logService.info(
              'FFmpeg execution completed successfully',
              taskId: task.id,
            );
          } else if (ReturnCode.isCancel(returnCode)) {
            logService.warning('FFmpeg execution cancelled', taskId: task.id);
          } else {
            final output = await session.getOutput();
            final failStackTrace = await session.getFailStackTrace();
            logService.error(
              'FFmpeg execution failed\nOutput: $output\nStackTrace: $failStackTrace',
              taskId: task.id,
              error: 'Return code: $returnCode',
            );
          }
        },
        (log) {
          final message = log.getMessage();
          // 记录所有包含 error、fail、warning 的消息
          if (message.contains('error') || 
              message.contains('Error') ||
              message.contains('fail') ||
              message.contains('warning')) {
            logService.error('FFmpeg: $message', taskId: task.id);
          } else if (message.contains('frame=') || message.contains('size=')) {
            // 跳过进度信息（由 statistics 回调处理）
            logService.debug('FFmpeg: $message', taskId: task.id);
          } else {
            logService.debug('FFmpeg: $message', taskId: task.id);
          }
        },
        (statistics) {
          final timeInMilliseconds = statistics.getTime();
          if (timeInMilliseconds > 0 && mediaInfo != null) {
            final properties = mediaInfo.getAllProperties();
            final format = properties?['format'] as Map?;
            final durationStr = format?['duration'];

            if (durationStr != null) {
              final totalDuration =
                  (double.tryParse(durationStr.toString()) ?? 0) * 1000;
              if (totalDuration > 0) {
                final prog = (timeInMilliseconds / totalDuration).clamp(
                  0.0,
                  1.0,
                );
                onProgress(prog);
              }
            }
          }
        },
      );

      _currentSessionId = session.getSessionId();
      onStatusChange(processingTask.copyWith(sessionId: _currentSessionId));

      // 等待执行完成
      final returnCode = await session.getReturnCode();

      if (ReturnCode.isSuccess(returnCode)) {
        final outputFile = File(task.outputPath);
        if (await outputFile.exists()) {
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
            sessionId: null,
          );
          onStatusChange(completedTask);
        } else {
          throw Exception('Output file not found after compression');
        }
      } else if (ReturnCode.isCancel(returnCode)) {
        // 清理未完成的输出文件
        final outputFile = File(task.outputPath);
        if (await outputFile.exists()) {
          await outputFile.delete();
          logService.debug(
            'Deleted incomplete output file after cancellation',
            taskId: task.id,
          );
        }

        final cancelledTask = processingTask.copyWith(
          status: VideoStatus.pending,
          progress: 0.0,
          sessionId: null,
        );
        onStatusChange(cancelledTask);
      } else {
        final output = await session.getOutput();
        throw Exception('FFmpeg failed: $output');
      }
    } catch (e) {
      final outputFile = File(task.outputPath);
      if (await outputFile.exists()) {
        await outputFile.delete();
        logService.debug('Deleted incomplete output file', taskId: task.id);
      }

      logService.error(
        'Exception during compression for ${task.fileName}',
        taskId: task.id,
        error: e,
      );

      final failedTask = task.copyWith(
        status: VideoStatus.failed,
        errorMessage: e.toString(),
        sessionId: null,
      );
      onStatusChange(failedTask);
    } finally {
      _currentSessionId = null;
    }
  }

  List<String> _buildFFmpegArguments({
    required String inputPath,
    required String outputPath,
    required CompressionSettings settings,
  }) {
    final args = <String>[];

    // 全局选项
    args.add('-y'); // 覆盖输出文件

    // 输入文件
    args.add('-i');
    args.add(inputPath);

    // 视频编码 - 始终使用软件编码 libx265 + CRF 模式
    args.add('-c:v');
    args.add('libx265');
    
    args.add('-crf');
    args.add(settings.crf.toString());
    
    args.add('-preset');
    args.add(settings.preset);

    // 分辨率设置
    if (settings.resolution != 'original') {
      args.add('-vf');
      args.add('scale=${settings.resolution.replaceAll('x', ':')}');
    }

    // 帧率设置
    if (settings.frameRate > 0) {
      args.add('-r');
      args.add(settings.frameRate.toString());
    }

    // 比特率限制（可选）
    if (settings.maxBitrate > 0) {
      args.add('-maxrate');
      args.add('${settings.maxBitrate}k');
      args.add('-bufsize');
      args.add('${settings.maxBitrate * 2}k');
    }

    // 音频编码
    args.add('-c:a');
    args.add('aac');
    args.add('-b:a');
    args.add('128k');

    // 自定义参数
    if (settings.customParams.isNotEmpty) {
      args.addAll(_splitCustomParams(settings.customParams));
    }

    // 输出文件
    args.add(outputPath);

    return args;
  }

  String _formatCommandForLog(List<String> args) {
    return args.map((arg) => arg.contains(' ') ? '"$arg"' : arg).join(' ');
  }

  List<String> _splitCustomParams(String params) {
    final regex = RegExp(r'''("[^"]*"|'[^']*'|\S+)''');
    return regex
        .allMatches(params)
        .map((match) {
          final value = match.group(0) ?? '';
          if (value.startsWith('"') && value.endsWith('"')) {
            return value.substring(1, value.length - 1);
          }
          if (value.startsWith("'") && value.endsWith("'")) {
            return value.substring(1, value.length - 1);
          }
          return value;
        })
        .where((arg) => arg.isNotEmpty)
        .toList();
  }

  Future<void> cancelCompression(int sessionId) async {
    try {
      await FFmpegKit.cancel(sessionId);
      logService.info('Cancelled compression session: $sessionId');

      if (_currentSessionId == sessionId) {
        _currentSessionId = null;
      }
    } catch (e) {
      logService.error('Failed to cancel compression', error: e);
    }
  }

  Future<void> cancelAllSessions() async {
    try {
      await FFmpegKit.cancel();
      logService.info('Cancelled all compression tasks');
      _currentSessionId = null;
    } catch (e) {
      logService.error('Failed to cancel all tasks', error: e);
    }
  }

  Future<void> dispose() async {
    // FFmpeg Kit does not require disposal
  }

  String getOutputFileName(String inputFileName, int crf, String outputDir) {
    final nameWithoutExt = path.basenameWithoutExtension(inputFileName);
    final ext = path.extension(inputFileName);

    String baseFileName = '${nameWithoutExt}_batch$crf$ext';
    String outputPath = path.join(outputDir, baseFileName);

    int suffix = 1;
    while (File(outputPath).existsSync()) {
      baseFileName = '${nameWithoutExt}_batch${crf}_$suffix$ext';
      outputPath = path.join(outputDir, baseFileName);
      suffix++;
    }

    return baseFileName;
  }
}
