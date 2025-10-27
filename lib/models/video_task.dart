enum VideoStatus {
  pending,
  processing,
  completed,
  failed,
  cancelled,
}

class VideoTask {
  final String id;
  final String inputPath;
  final String outputPath;
  final String fileName;
  final int fileSize; // File size in bytes
  VideoStatus status;
  double progress;
  String? errorMessage;
  int? sessionId; // Session ID for tracking
  DateTime createdAt;
  DateTime? startedAt;
  DateTime? completedAt;

  VideoTask({
    required this.id,
    required this.inputPath,
    required this.outputPath,
    required this.fileName,
    required this.fileSize,
    this.status = VideoStatus.pending,
    this.progress = 0.0,
    this.errorMessage,
    this.sessionId,
    DateTime? createdAt,
    this.startedAt,
    this.completedAt,
  }) : createdAt = createdAt ?? DateTime.now();

  // Copy with method for immutability
  VideoTask copyWith({
    String? id,
    String? inputPath,
    String? outputPath,
    String? fileName,
    int? fileSize,
    VideoStatus? status,
    double? progress,
    String? errorMessage,
    int? sessionId,
    DateTime? createdAt,
    DateTime? startedAt,
    DateTime? completedAt,
  }) {
    return VideoTask(
      id: id ?? this.id,
      inputPath: inputPath ?? this.inputPath,
      outputPath: outputPath ?? this.outputPath,
      fileName: fileName ?? this.fileName,
      fileSize: fileSize ?? this.fileSize,
      status: status ?? this.status,
      progress: progress ?? this.progress,
      errorMessage: errorMessage ?? this.errorMessage,
      sessionId: sessionId ?? this.sessionId,
      createdAt: createdAt ?? this.createdAt,
      startedAt: startedAt ?? this.startedAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  // Convert to JSON for persistence
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'inputPath': inputPath,
      'outputPath': outputPath,
      'fileName': fileName,
      'fileSize': fileSize,
      'status': status.index,
      'progress': progress,
      'errorMessage': errorMessage,
      'sessionId': sessionId,
      'createdAt': createdAt.toIso8601String(),
      'startedAt': startedAt?.toIso8601String(),
      'completedAt': completedAt?.toIso8601String(),
    };
  }

  // Create from JSON
  factory VideoTask.fromJson(Map<String, dynamic> json) {
    return VideoTask(
      id: json['id'],
      inputPath: json['inputPath'],
      outputPath: json['outputPath'],
      fileName: json['fileName'],
      fileSize: json['fileSize'] ?? 0,
      status: VideoStatus.values[json['status']],
      progress: json['progress'],
      errorMessage: json['errorMessage'],
      sessionId: json['sessionId'],
      createdAt: DateTime.parse(json['createdAt']),
      startedAt: json['startedAt'] != null
          ? DateTime.parse(json['startedAt'])
          : null,
      completedAt: json['completedAt'] != null
          ? DateTime.parse(json['completedAt'])
          : null,
    );
  }
}
