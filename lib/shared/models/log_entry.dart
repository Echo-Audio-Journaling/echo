import 'package:cloud_firestore/cloud_firestore.dart';

enum LogEntryType { audio, image, video }

abstract class LogEntry {
  final String id;
  final DateTime timestamp;
  final LogEntryType type;
  String title;

  LogEntry({
    required this.id,
    required this.timestamp,
    required this.type,
    required this.title,
  });

  Map<String, dynamic> toJson();

  static LogEntry fromJson(Map<String, dynamic> json) {
    final type = LogEntryType.values.firstWhere(
      (e) => e.toString() == 'LogEntryType.${json['type']}',
      orElse: () => LogEntryType.audio,
    );

    switch (type) {
      case LogEntryType.audio:
        return AudioLogEntry.fromJson(json);
      case LogEntryType.image:
        return ImageLogEntry.fromJson(json);
      case LogEntryType.video:
        return VideoLogEntry.fromJson(json);
    }
  }
}

class AudioLogEntry extends LogEntry {
  final String audioUrl;
  final String transcription;
  final Duration duration;
  bool isPlaying;
  List<String> tags;
  bool isFavorite;

  AudioLogEntry({
    required super.id,
    required super.timestamp,
    required super.title,
    required this.audioUrl,
    required this.transcription,
    required this.duration,
    this.isPlaying = false,
    this.tags = const [],
    this.isFavorite = false,
  }) : super(type: LogEntryType.audio);

  factory AudioLogEntry.fromJson(Map<String, dynamic> json) {
    return AudioLogEntry(
      id: json['id'],
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      title: json['title'],
      audioUrl: json['audioUrl'],
      transcription: json['transcription'],
      duration: Duration(milliseconds: json['durationMs'] ?? 0),
      tags: List<String>.from(json['tags'] ?? []),
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.toString().split('.').last,
      'title': title,
      'audioUrl': audioUrl,
      'transcription': transcription,
      'durationMs': duration.inMilliseconds,
      'tags': tags,
      'isFavorite': isFavorite,
    };
  }

  String get previewText {
    // Return first 100 characters of transcription or the full text if shorter
    if (transcription.length <= 100) {
      return transcription;
    }
    return '${transcription.substring(0, 100)}...';
  }
}

class ImageLogEntry extends LogEntry {
  final String imageUrl;
  final String? description;

  ImageLogEntry({
    required super.id,
    required super.timestamp,
    required super.title,
    required this.imageUrl,
    this.description,
  }) : super(type: LogEntryType.image);

  factory ImageLogEntry.fromJson(Map<String, dynamic> json) {
    return ImageLogEntry(
      id: json['id'],
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      title: json['title'],
      imageUrl: json['imageUrl'],
      description: json['description'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.toString().split('.').last,
      'title': title,
      'imageUrl': imageUrl,
      'description': description,
    };
  }
}

class VideoLogEntry extends LogEntry {
  final String videoUrl;
  final String? description;
  final Duration duration;
  final String? thumbnailUrl;

  VideoLogEntry({
    required super.id,
    required super.timestamp,
    required super.title,
    required this.videoUrl,
    required this.duration,
    this.description,
    this.thumbnailUrl,
  }) : super(type: LogEntryType.video);

  factory VideoLogEntry.fromJson(Map<String, dynamic> json) {
    return VideoLogEntry(
      id: json['id'],
      timestamp: (json['timestamp'] as Timestamp).toDate(),
      title: json['title'],
      videoUrl: json['videoUrl'],
      duration: Duration(milliseconds: json['durationMs'] ?? 0),
      description: json['description'],
      thumbnailUrl: json['thumbnailUrl'],
    );
  }

  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'timestamp': Timestamp.fromDate(timestamp),
      'type': type.toString().split('.').last,
      'title': title,
      'videoUrl': videoUrl,
      'durationMs': duration.inMilliseconds,
      'description': description,
      'thumbnailUrl': thumbnailUrl,
    };
  }
}
