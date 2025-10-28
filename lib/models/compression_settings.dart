class CompressionSettings {
  final int crf;
  final String preset;
  final String customParams;
  final int maxBitrate; // in kbps, 0 means no limit
  final bool useHardwareAccel;

  CompressionSettings({
    this.crf = 28,
    this.preset = 'medium',
    this.customParams = '',
    this.maxBitrate = 0,
    this.useHardwareAccel = true,
  });

  CompressionSettings copyWith({
    int? crf,
    String? preset,
    String? customParams,
    int? maxBitrate,
    bool? useHardwareAccel,
  }) {
    return CompressionSettings(
      crf: crf ?? this.crf,
      preset: preset ?? this.preset,
      customParams: customParams ?? this.customParams,
      maxBitrate: maxBitrate ?? this.maxBitrate,
      useHardwareAccel: useHardwareAccel ?? this.useHardwareAccel,
    );
  }

  String get commandPreview {
    final List<String> parts = [];
    
    // Hardware acceleration
    if (useHardwareAccel) {
      parts.add('-hwaccel auto');
    }
    
    // Video codec
    parts.add('-c:v libx265');
    
    // CRF setting
    parts.add('-crf $crf');
    
    // Preset
    parts.add('-preset $preset');
    
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
    
    return parts.join(' ');
  }

  Map<String, dynamic> toJson() {
    return {
      'crf': crf,
      'preset': preset,
      'customParams': customParams,
      'maxBitrate': maxBitrate,
      'useHardwareAccel': useHardwareAccel,
    };
  }

  factory CompressionSettings.fromJson(Map<String, dynamic> json) {
    return CompressionSettings(
      crf: json['crf'] ?? 28,
      preset: json['preset'] ?? 'medium',
      customParams: json['customParams'] ?? '',
      maxBitrate: json['maxBitrate'] ?? 0,
      useHardwareAccel: json['useHardwareAccel'] ?? true,
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
}
