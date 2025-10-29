import 'dart:async';
import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit_config.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';

void main() async {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    developer.log('Testing FFmpeg Kit initialization...', name: 'FFmpeg-Test');
    
    try {
      // Test FFmpeg Kit basic functionality
      final version = await FFmpegKitConfig.getVersion();
      developer.log('FFmpeg Kit version: $version', name: 'FFmpeg-Test');
      
      // Test simple command
      final session = await FFmpegKit.execute('-version');
      final output = await session.getOutput();
      developer.log('FFmpeg version output: $output', name: 'FFmpeg-Test');
      
      runApp(MaterialApp(
        home: Scaffold(
          appBar: AppBar(title: const Text('FFmpeg Kit Test')),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, size: 64, color: Colors.green),
                const SizedBox(height: 16),
                const Text(
                  'FFmpeg Kit 加载成功!',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  'Version: $version',
                  style: const TextStyle(fontSize: 14),
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    developer.log('Output: $output', name: 'FFmpeg-Test');
                  },
                  child: const Text('查看日志'),
                ),
              ],
            ),
          ),
        ),
      ));
    } catch (e, stackTrace) {
      developer.log(
        'FFmpeg Kit initialization failed: $e',
        name: 'FFmpeg-Test',
        error: e,
        stackTrace: stackTrace,
      );
      
      runApp(MaterialApp(
        home: Scaffold(
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                const Text(
                  'FFmpeg Kit 加载失败',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text(
                  '错误: $e',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ));
    }
  }, (error, stackTrace) {
    developer.log(
      'Uncaught error: $error',
      name: 'FFmpeg-Test',
      error: error,
      stackTrace: stackTrace,
    );
  });
}
