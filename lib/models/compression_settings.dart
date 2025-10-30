class CompressionSettings {
  final int crf;
  final String preset;
  final String customParams;
  final int maxBitrate; // in kbps, 0 means no limit
  final String resolution; // 分辨率，如 "1920x1080"，"original" 表示原始
  final int frameRate; // 帧率，0 表示使用原始帧率

  CompressionSettings({
    this.crf = 28,
    this.preset = 'medium',
    this.customParams = '',
    this.maxBitrate = 0,
    this.resolution = 'original',
    this.frameRate = 0,
  });

  CompressionSettings copyWith({
    int? crf,
    String? preset,
    String? customParams,
    int? maxBitrate,
    String? resolution,
    int? frameRate,
  }) {
    return CompressionSettings(
      crf: crf ?? this.crf,
      preset: preset ?? this.preset,
      customParams: customParams ?? this.customParams,
      maxBitrate: maxBitrate ?? this.maxBitrate,
      resolution: resolution ?? this.resolution,
      frameRate: frameRate ?? this.frameRate,
    );
  }

  String get commandPreview {
    final List<String> parts = [];
    
    // Input (placeholder)
    parts.add('-i input.mp4');
    
    // Video codec - 始终使用软件编码 libx265
    parts.add('-c:v libx265');
    
    // CRF setting
    parts.add('-crf $crf');
    
    // Preset
    parts.add('-preset $preset');
    
    // Resolution
    if (resolution != 'original') {
      parts.add('-s $resolution');
    }
    
    // Frame rate
    if (frameRate > 0) {
      parts.add('-r $frameRate');
    }
    
    // Bitrate limit
    if (maxBitrate > 0) {
      parts.add('-maxrate ${maxBitrate}k');
      parts.add('-bufsize ${maxBitrate * 2}k');
    }
    
    // Audio codec
    parts.add('-c:a aac');
    parts.add('-b:a 128k');
    
    // Custom parameters
    if (customParams.isNotEmpty) {
      parts.add(customParams);
    }
    
    // Output (placeholder)
    parts.add('output.mp4');
    
    return 'ffmpeg -y ${parts.join(' ')}';
  }

  Map<String, dynamic> toJson() {
    return {
      'crf': crf,
      'preset': preset,
      'customParams': customParams,
      'maxBitrate': maxBitrate,
      'resolution': resolution,
      'frameRate': frameRate,
    };
  }

  factory CompressionSettings.fromJson(Map<String, dynamic> json) {
    return CompressionSettings(
      crf: json['crf'] ?? 28,
      preset: json['preset'] ?? 'medium',
      customParams: json['customParams'] ?? '',
      maxBitrate: json['maxBitrate'] ?? 0,
      resolution: json['resolution'] ?? 'original',
      frameRate: json['frameRate'] ?? 0,
    );
  }

  // Preset quality levels
  static const Map<String, String> presetDescriptions = {
    'ultrafast': '最快速度（质量最低）',
    'superfast': '超快速',
    'veryfast': '很快',
    'faster': '较快',
    'fast': '快速',
    'medium': '中等（推荐）',
    'slow': '慢速（质量好）',
    'slower': '更慢（质量很好）',
    'veryslow': '非常慢（质量最好）',
  };

  static const List<String> availablePresets = [
    'ultrafast',
    'superfast',
    'veryfast',
    'faster',
    'fast',
    'medium',
    'slow',
    'slower',
    'veryslow',
  ];

  // CRF range for HEVC: 0-51, with 28 being good quality/size balance
  static const int minCrf = 18;
  static const int maxCrf = 36;
  static const int defaultCrf = 28;

  // 常用分辨率预设
  static const List<String> availableResolutions = [
    'original',
    '3840x2160', // 4K
    '2560x1440', // 2K
    '1920x1080', // 1080p
    '1280x720',  // 720p
    '854x480',   // 480p
    '640x360',   // 360p
  ];

  static const Map<String, String> resolutionDescriptions = {
    'original': '原始分辨率',
    '3840x2160': '4K (3840x2160)',
    '2560x1440': '2K (2560x1440)',
    '1920x1080': '1080p (1920x1080)',
    '1280x720': '720p (1280x720)',
    '854x480': '480p (854x480)',
    '640x360': '360p (640x360)',
  };

  // 常用帧率预设
  static const List<int> availableFrameRates = [
    0,   // 原始帧率
    24,
    25,
    30,
    50,
    60,
  ];

  static String getFrameRateDescription(int fps) {
    if (fps == 0) return '原始帧率';
    return '$fps FPS';
  }
}
