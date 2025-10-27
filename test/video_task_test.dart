import 'package:flutter_test/flutter_test.dart';
import 'package:video_compressor/models/video_task.dart';

void main() {
  group('VideoTask Model Tests', () {
    test('VideoTask should be created with correct properties', () {
      final task = VideoTask(
        id: '1',
        inputPath: '/path/to/input.mp4',
        outputPath: '/path/to/output.mp4',
        fileName: 'input.mp4',
        fileSize: 10485760, // 10 MB
      );

      expect(task.id, '1');
      expect(task.inputPath, '/path/to/input.mp4');
      expect(task.outputPath, '/path/to/output.mp4');
      expect(task.fileName, 'input.mp4');
      expect(task.fileSize, 10485760);
      expect(task.status, VideoStatus.pending);
      expect(task.progress, 0.0);
      expect(task.errorMessage, isNull);
    });

    test('VideoTask copyWith should update properties correctly', () {
      final task = VideoTask(
        id: '1',
        inputPath: '/path/to/input.mp4',
        outputPath: '/path/to/output.mp4',
        fileName: 'input.mp4',
        fileSize: 10485760,
      );

      final updatedTask = task.copyWith(
        status: VideoStatus.processing,
        progress: 0.5,
      );

      expect(updatedTask.id, task.id);
      expect(updatedTask.status, VideoStatus.processing);
      expect(updatedTask.progress, 0.5);
      expect(updatedTask.fileName, task.fileName);
    });

    test('VideoTask should convert to and from JSON correctly', () {
      final task = VideoTask(
        id: '1',
        inputPath: '/path/to/input.mp4',
        outputPath: '/path/to/output.mp4',
        fileName: 'input.mp4',
        fileSize: 10485760,
        status: VideoStatus.processing,
        progress: 0.75,
      );

      final json = task.toJson();
      final fromJson = VideoTask.fromJson(json);

      expect(fromJson.id, task.id);
      expect(fromJson.inputPath, task.inputPath);
      expect(fromJson.outputPath, task.outputPath);
      expect(fromJson.fileName, task.fileName);
      expect(fromJson.fileSize, task.fileSize);
      expect(fromJson.status, task.status);
      expect(fromJson.progress, task.progress);
    });

    test('VideoTask status transitions should work correctly', () {
      final task = VideoTask(
        id: '1',
        inputPath: '/path/to/input.mp4',
        outputPath: '/path/to/output.mp4',
        fileName: 'input.mp4',
        fileSize: 10485760,
      );

      expect(task.status, VideoStatus.pending);

      final processing = task.copyWith(status: VideoStatus.processing);
      expect(processing.status, VideoStatus.processing);

      final completed = processing.copyWith(
        status: VideoStatus.completed,
        progress: 1.0,
      );
      expect(completed.status, VideoStatus.completed);
      expect(completed.progress, 1.0);
    });

    test('VideoTask should handle error state correctly', () {
      final task = VideoTask(
        id: '1',
        inputPath: '/path/to/input.mp4',
        outputPath: '/path/to/output.mp4',
        fileName: 'input.mp4',
        fileSize: 10485760,
      );

      final failed = task.copyWith(
        status: VideoStatus.failed,
        errorMessage: 'Compression failed',
      );

      expect(failed.status, VideoStatus.failed);
      expect(failed.errorMessage, 'Compression failed');
    });
  });

  group('VideoStatus Tests', () {
    test('VideoStatus should have correct string values', () {
      expect(VideoStatus.pending.toString(), 'VideoStatus.pending');
      expect(VideoStatus.processing.toString(), 'VideoStatus.processing');
      expect(VideoStatus.completed.toString(), 'VideoStatus.completed');
      expect(VideoStatus.failed.toString(), 'VideoStatus.failed');
    });
  });
}
