import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';

class CameraService {
  // Singleton pattern
  static final CameraService _instance = CameraService._internal();
  factory CameraService() => _instance;
  CameraService._internal();

  // Camera states
  bool _isCameraInitialized = false;
  bool _isRecording = false;
  bool _isPaused = false;
  String _selectedCamera = ''; // 'front', 'back', or 'dual'
  bool _recordWithAudio = true;
  String _storageLocation = 'local'; // 'local' or 'cloud'

  // Recording info
  String? _currentVideoPath;
  DateTime? _recordingStartTime;
  Timer? _recordingTimer;
  int _recordingDuration = 15; // in minutes

  // Saved videos
  final List<String> _savedVideos = [];

  // Getters
  bool get isCameraInitialized => _isCameraInitialized;
  bool get isRecording => _isRecording;
  bool get isPaused => _isPaused;
  String get selectedCamera => _selectedCamera;
  bool get recordWithAudio => _recordWithAudio;
  String get storageLocation => _storageLocation;
  String? get currentVideoPath => _currentVideoPath;
  List<String> get savedVideos => List.unmodifiable(_savedVideos);

  // Check and request permissions
  Future<bool> checkAndRequestPermissions() async {
    final cameraPermission = await Permission.camera.request();
    final microphonePermission = await Permission.microphone.request();
    final storagePermission = await Permission.storage.request();

    return cameraPermission.isGranted &&
        microphonePermission.isGranted &&
        storagePermission.isGranted;
  }

  // Initialize camera
  Future<bool> initializeCamera(String cameraType) async {
    try {
      final hasPermissions = await checkAndRequestPermissions();
      if (!hasPermissions) {
        return false;
      }

      // In a real implementation, this would initialize the camera hardware
      // For this example, we'll just simulate it
      _selectedCamera = cameraType;
      _isCameraInitialized = true;
      return true;
    } catch (e) {
      debugPrint('Error initializing camera: $e');
      _isCameraInitialized = false;
      return false;
    }
  }

  // Set recording options
  void setRecordingOptions({
    bool? withAudio,
    int? duration,
    String? storage,
  }) {
    if (withAudio != null) _recordWithAudio = withAudio;
    if (duration != null) _recordingDuration = duration;
    if (storage != null) _storageLocation = storage;
  }

  // Start recording
  Future<bool> startRecording() async {
    if (!_isCameraInitialized) return false;

    try {
      if (_isRecording && _isPaused) {
        // Resume recording
        _isPaused = false;
        return true;
      }

      if (_isRecording) return true; // Already recording

      // In a real implementation, this would start the camera recording
      // For this example, we'll just simulate it
      _isRecording = true;
      _isPaused = false;
      _recordingStartTime = DateTime.now();

      // Start recording timer
      _recordingTimer = Timer(Duration(minutes: _recordingDuration), () {
        stopRecording();
      });

      return true;
    } catch (e) {
      debugPrint('Error starting recording: $e');
      return false;
    }
  }

  // Pause recording
  Future<bool> pauseRecording() async {
    if (!_isRecording || _isPaused) return false;

    try {
      // In a real implementation, this would pause the camera recording
      // For this example, we'll just simulate it
      _isPaused = true;

      // Cancel the current timer
      _recordingTimer?.cancel();

      return true;
    } catch (e) {
      debugPrint('Error pausing recording: $e');
      return false;
    }
  }

  // Stop recording
  Future<String?> stopRecording() async {
    if (!_isRecording) return null;

    try {
      // Cancel the timer
      _recordingTimer?.cancel();

      // In a real implementation, this would stop the camera recording and save the file
      // For this example, we'll just simulate it
      final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
      final videoFileName = 'dashcam_$timestamp.mp4';

      // Get the appropriate directory for saving videos
      final directory = await _getVideoDirectory();
      final videoPath = '${directory.path}/$videoFileName';

      _isRecording = false;
      _isPaused = false;
      _currentVideoPath = videoPath;
      _savedVideos.add(videoPath);

      return videoPath;
    } catch (e) {
      debugPrint('Error stopping recording: $e');
      return null;
    }
  }

  // Delete current recording
  Future<bool> deleteRecording() async {
    if (!_isRecording) return false;

    try {
      // Cancel the timer
      _recordingTimer?.cancel();

      // In a real implementation, this would delete the temporary recording file
      // For this example, we'll just simulate it
      _isRecording = false;
      _isPaused = false;
      _currentVideoPath = null;

      return true;
    } catch (e) {
      debugPrint('Error deleting recording: $e');
      return false;
    }
  }

  // Get all saved videos
  Future<List<String>> loadSavedVideos() async {
    try {
      // In a real implementation, this would scan the directory for video files
      // For this example, we'll just return the list we've been maintaining
      return _savedVideos;
    } catch (e) {
      debugPrint('Error loading saved videos: $e');
      return [];
    }
  }

  // Delete a saved video
  Future<bool> deleteSavedVideo(String path) async {
    try {
      // In a real implementation, this would delete the file from storage
      // For this example, we'll just remove it from our list
      final file = File(path);
      if (await file.exists()) {
        await file.delete();
      }

      _savedVideos.remove(path);
      return true;
    } catch (e) {
      debugPrint('Error deleting saved video: $e');
      return false;
    }
  }

  // Get the directory for saving videos
  Future<Directory> _getVideoDirectory() async {
    if (_storageLocation == 'local') {
      if (Platform.isAndroid) {
        // For Android, use the DCIM directory
        final directory = Directory('/storage/emulated/0/DCIM/OkDriver');
        if (!await directory.exists()) {
          await directory.create(recursive: true);
        }
        return directory;
      } else {
        // For iOS and other platforms, use the documents directory
        final directory = await getApplicationDocumentsDirectory();
        final videoDir = Directory('${directory.path}/OkDriver');
        if (!await videoDir.exists()) {
          await videoDir.create(recursive: true);
        }
        return videoDir;
      }
    } else {
      // For cloud storage, we would still need a local temporary directory
      // In a real implementation, this would be handled by a cloud storage service
      final tempDir = await getTemporaryDirectory();
      return tempDir;
    }
  }

  // Release resources
  void dispose() {
    _recordingTimer?.cancel();
    _isCameraInitialized = false;
    _isRecording = false;
    _isPaused = false;
  }
}
