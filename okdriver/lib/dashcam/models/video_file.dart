import 'dart:io';

class VideoFile {
  final String id;
  final String filePath;
  final DateTime timestamp;
  final Duration duration;
  final String cameraType; // 'front', 'back', or 'dual'
  final bool hasAudio;
  final String storageType; // 'local' or 'cloud'
  final int fileSizeBytes;

  const VideoFile({
    required this.id,
    required this.filePath,
    required this.timestamp,
    required this.duration,
    required this.cameraType,
    required this.hasAudio,
    required this.storageType,
    required this.fileSizeBytes,
  });

  // Create a VideoFile from a file path and metadata
  static Future<VideoFile?> fromFile({
    required String filePath,
    required String cameraType,
    required bool hasAudio,
    required String storageType,
  }) async {
    try {
      final file = File(filePath);
      if (!await file.exists()) return null;

      final fileStats = await file.stat();
      final fileName = filePath.split('/').last;

      // Extract timestamp from filename (assuming format: dashcam_timestamp.mp4)
      final timestampStr =
          fileName.replaceAll('dashcam_', '').replaceAll('.mp4', '');
      final timestamp = DateTime.fromMillisecondsSinceEpoch(
          int.tryParse(timestampStr) ?? DateTime.now().millisecondsSinceEpoch);

      // In a real app, you would extract the actual video duration
      // For this example, we'll use a placeholder duration
      const duration = Duration(minutes: 1);

      return VideoFile(
        id: fileName,
        filePath: filePath,
        timestamp: timestamp,
        duration: duration,
        cameraType: cameraType,
        hasAudio: hasAudio,
        storageType: storageType,
        fileSizeBytes: fileStats.size,
      );
    } catch (e) {
      print('Error creating VideoFile from path: $e');
      return null;
    }
  }

  // Format the file size for display
  String get formattedFileSize {
    if (fileSizeBytes < 1024) {
      return '$fileSizeBytes B';
    } else if (fileSizeBytes < 1024 * 1024) {
      return '${(fileSizeBytes / 1024).toStringAsFixed(1)} KB';
    } else if (fileSizeBytes < 1024 * 1024 * 1024) {
      return '${(fileSizeBytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    } else {
      return '${(fileSizeBytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
    }
  }

  // Format the timestamp for display
  String get formattedTimestamp {
    return '${timestamp.day.toString().padLeft(2, '0')}/${timestamp.month.toString().padLeft(2, '0')}/${timestamp.year} ${timestamp.hour.toString().padLeft(2, '0')}:${timestamp.minute.toString().padLeft(2, '0')}';
  }

  // Format the duration for display
  String get formattedDuration {
    final minutes = duration.inMinutes.remainder(60).toString().padLeft(2, '0');
    final seconds = duration.inSeconds.remainder(60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Check if the file exists
  Future<bool> exists() async {
    if (storageType == 'cloud') {
      // For cloud storage, we would check if the file exists in the cloud
      // For this example, we'll just return true
      return true;
    } else {
      final file = File(filePath);
      return await file.exists();
    }
  }

  // Delete the file
  Future<bool> delete() async {
    try {
      if (storageType == 'cloud') {
        // For cloud storage, we would delete the file from the cloud
        // For this example, we'll just return true
        return true;
      } else {
        final file = File(filePath);
        if (await file.exists()) {
          await file.delete();
        }
        return true;
      }
    } catch (e) {
      print('Error deleting video file: $e');
      return false;
    }
  }
}
