import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/compression_settings.dart';
import '../providers/task_manager.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  late TextEditingController _customParamsController;

  @override
  void initState() {
    super.initState();
    final taskManager = context.read<TaskManager>();
    _customParamsController = TextEditingController(
      text: taskManager.compressionSettings.customParams,
    );
  }

  @override
  void dispose() {
    _customParamsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('压缩参数设置'),
        actions: [
          IconButton(
            icon: const Icon(Icons.restore),
            tooltip: '恢复默认',
            onPressed: () {
              final taskManager = context.read<TaskManager>();
              setState(() {
                taskManager.updateCompressionSettings(CompressionSettings());
                _customParamsController.text = '';
              });
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('已恢复默认设置')),
              );
            },
          ),
        ],
      ),
      body: Consumer<TaskManager>(
        builder: (context, taskManager, child) {
          final settings = taskManager.compressionSettings;
          
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // CRF Setting
                _buildSectionTitle('质量控制 (CRF)'),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            const Text(
                              'CRF 值',
                              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                            ),
                            Text(
                              settings.crf.toString(),
                              style: TextStyle(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: Theme.of(context).primaryColor,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _getCrfDescription(settings.crf),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            const Text('高质量\n大文件', style: TextStyle(fontSize: 10)),
                            Expanded(
                              child: Slider(
                                value: settings.crf.toDouble(),
                                min: CompressionSettings.minCrf.toDouble(),
                                max: CompressionSettings.maxCrf.toDouble(),
                                divisions: CompressionSettings.maxCrf - CompressionSettings.minCrf,
                                label: settings.crf.toString(),
                                onChanged: (value) {
                                  taskManager.updateCompressionSettings(
                                    settings.copyWith(crf: value.toInt()),
                                  );
                                },
                              ),
                            ),
                            const Text('低质量\n小文件', style: TextStyle(fontSize: 10)),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Preset Setting
                _buildSectionTitle('编码速度预设'),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: settings.preset,
                          decoration: const InputDecoration(
                            labelText: '预设',
                            border: OutlineInputBorder(),
                          ),
                          items: CompressionSettings.availablePresets.map((preset) {
                            return DropdownMenuItem(
                              value: preset,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(preset),
                                  Text(
                                    CompressionSettings.presetDescriptions[preset] ?? '',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              taskManager.updateCompressionSettings(
                                settings.copyWith(preset: value),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '预设控制编码速度和压缩效率的平衡\n'
                          '• 快速预设：编码快但压缩率低\n'
                          '• 慢速预设：编码慢但压缩率高',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Resolution Setting
                _buildSectionTitle('分辨率设置'),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: settings.resolution,
                          decoration: const InputDecoration(
                            labelText: '输出分辨率',
                            border: OutlineInputBorder(),
                          ),
                          items: CompressionSettings.availableResolutions.map((res) {
                            return DropdownMenuItem(
                              value: res,
                              child: Text(
                                CompressionSettings.resolutionDescriptions[res] ?? res,
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              taskManager.updateCompressionSettings(
                                settings.copyWith(resolution: value),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '⚠️ 注意: 当前使用的 video_compress 库不支持自定义分辨率\n'
                          '输出分辨率由编码器自动控制，通常保持原始分辨率\n'
                          '如需精确控制分辨率，需要升级到支持 FFmpeg 的版本',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.orange[700],
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Frame Rate Setting
                _buildSectionTitle('帧率设置'),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DropdownButtonFormField<int>(
                          initialValue: settings.frameRate,
                          decoration: const InputDecoration(
                            labelText: '输出帧率',
                            border: OutlineInputBorder(),
                          ),
                          items: CompressionSettings.availableFrameRates.map((fps) {
                            return DropdownMenuItem(
                              value: fps,
                              child: Text(
                                CompressionSettings.getFrameRateDescription(fps),
                              ),
                            );
                          }).toList(),
                          onChanged: (value) {
                            if (value != null) {
                              taskManager.updateCompressionSettings(
                                settings.copyWith(frameRate: value),
                              );
                            }
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '✅ 帧率设置已生效\n'
                          '降低帧率可以减小文件大小，但可能影响流畅度\n'
                          '建议视频帧率: 电影24fps, 普通视频30fps, 高清60fps',
                          style: TextStyle(
                            fontSize: 11,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Bitrate Limit
                _buildSectionTitle('码率限制 (可选)'),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SwitchListTile(
                          title: const Text('启用码率限制'),
                          subtitle: Text(
                            settings.maxBitrate > 0
                                ? '最大码率: ${settings.maxBitrate} kbps'
                                : '不限制码率',
                          ),
                          value: settings.maxBitrate > 0,
                          onChanged: (enabled) {
                            taskManager.updateCompressionSettings(
                              settings.copyWith(
                                maxBitrate: enabled ? 2000 : 0,
                              ),
                            );
                          },
                        ),
                        if (settings.maxBitrate > 0) ...[
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Text('500k'),
                              Expanded(
                                child: Slider(
                                  value: settings.maxBitrate.toDouble(),
                                  min: 500,
                                  max: 10000,
                                  divisions: 19,
                                  label: '${settings.maxBitrate}k',
                                  onChanged: (value) {
                                    taskManager.updateCompressionSettings(
                                      settings.copyWith(maxBitrate: value.toInt()),
                                    );
                                  },
                                ),
                              ),
                              const Text('10M'),
                            ],
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Hardware Acceleration
                _buildSectionTitle('性能设置'),
                const SizedBox(height: 8),
                Card(
                  child: SwitchListTile(
                    title: const Text('硬件加速'),
                    subtitle: const Text('使用设备硬件加速编码（推荐）'),
                    value: settings.useHardwareAccel,
                    onChanged: (value) {
                      taskManager.updateCompressionSettings(
                        settings.copyWith(useHardwareAccel: value),
                      );
                    },
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Custom Parameters
                _buildSectionTitle('高级自定义参数'),
                const SizedBox(height: 8),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _customParamsController,
                          decoration: const InputDecoration(
                            labelText: '自定义参数',
                            hintText: '例如: -tune film -profile:v main',
                            border: OutlineInputBorder(),
                            helperText: '输入额外的 FFmpeg 参数',
                          ),
                          maxLines: 3,
                          onChanged: (value) {
                            taskManager.updateCompressionSettings(
                              settings.copyWith(customParams: value),
                            );
                          },
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '注意：请确保输入正确的参数格式',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Command Preview
                _buildSectionTitle('命令预览'),
                const SizedBox(height: 8),
                Card(
                  color: Colors.grey[900],
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'FFmpeg 参数:',
                          style: TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        SelectableText(
                          settings.commandPreview,
                          style: const TextStyle(
                            color: Colors.white,
                            fontFamily: 'monospace',
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                
                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  String _getCrfDescription(int crf) {
    if (crf < 23) {
      return '极高质量 - 文件较大，适合存档';
    } else if (crf < 28) {
      return '高质量 - 质量和大小平衡较好';
    } else if (crf <= 30) {
      return '中等质量（推荐）- 较小文件，质量良好';
    } else if (crf <= 33) {
      return '较低质量 - 文件很小，适合分享';
    } else {
      return '低质量 - 文件最小，质量明显下降';
    }
  }
}
