import 'package:flutter/material.dart';
import 'package:ffmpeg_kit_flutter_new/ffmpeg_kit.dart';
import 'package:ffmpeg_kit_flutter_new/return_code.dart';

void main() {
  runApp(const FFmpegTestApp());
}

class FFmpegTestApp extends StatefulWidget {
  const FFmpegTestApp({super.key});

  @override
  State<FFmpegTestApp> createState() => _FFmpegTestAppState();
}

class _FFmpegTestAppState extends State<FFmpegTestApp> {
  String _output = '等待测试...';
  bool _testing = false;

  Future<void> _testFFmpegCommand() async {
    setState(() {
      _testing = true;
      _output = '正在测试 FFmpeg 命令...';
    });

    try {
      // 测试基本命令
      final args = [
        '-y',
        '-f', 'lavfi',
        '-i', 'testsrc=duration=1:size=320x240:rate=1',
        '-c:v', 'libx265',
        '-crf', '28',
        '-preset', 'ultrafast',
        '-c:a', 'aac',
        '-b:a', '128k',
        '/storage/emulated/0/Movies/FFmpeg-Mobile/test_output.mp4',
      ];

      debugPrint('Testing command: ffmpeg ${args.join(' ')}');

      final session = await FFmpegKit.executeWithArgumentsAsync(
        args,
        (session) async {
          final returnCode = await session.getReturnCode();
          final output = await session.getOutput();
          final failStackTrace = await session.getFailStackTrace();

          setState(() {
            if (ReturnCode.isSuccess(returnCode)) {
              _output = '✅ 测试成功！\n\n输出:\n$output';
            } else {
              _output = '❌ 测试失败！\n\n'
                  'Return Code: $returnCode\n\n'
                  'Output:\n$output\n\n'
                  'Stack Trace:\n$failStackTrace';
            }
            _testing = false;
          });
        },
        (log) {
          debugPrint('FFmpeg Log: ${log.getMessage()}');
        },
        (statistics) {
          debugPrint('FFmpeg Stats: time=${statistics.getTime()}');
        },
      );
    } catch (e, stackTrace) {
      setState(() {
        _output = '❌ 异常: $e\n\nStack Trace:\n$stackTrace';
        _testing = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('FFmpeg 命令测试'),
          backgroundColor: Colors.deepPurple,
        ),
        body: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ElevatedButton(
                onPressed: _testing ? null : _testFFmpegCommand,
                child: Text(_testing ? '测试中...' : '测试 FFmpeg 命令'),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: SingleChildScrollView(
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: SelectableText(
                      _output,
                      style: const TextStyle(
                        fontFamily: 'monospace',
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
